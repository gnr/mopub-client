//
//  MPAdView.m
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import "MPAdView.h"
#import "MPBaseAdapter.h"
#import "MPAdapterMap.h"

@interface MPAdView (Internal)
- (void)_setUpWebViewWithFrame:(CGRect)frame;
- (void)_adLinkClicked:(NSURL *)URL;
- (void)_backFillWithNothing;
- (NSString *)_escapeURL:(NSURL *)URL;
@end

@implementation MPAdView

@synthesize delegate = _delegate, adUnitId = _adUnitId, URL = _URL;
@synthesize clickURL = _clickURL, failURL = _failURL;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
		[self _setUpWebViewWithFrame:frame];
		self.adUnitId = PUB_ID_320x50;
		_data = [[NSMutableData data] retain];
		self.URL = nil;
		_isLoading = NO;
    }
    return self;
}

- (void)dealloc {
	[_adContentView release];
	[_adapter release];
	[_webView release];
	[_adUnitId release];
	[_data release];
	[_URL release];
    [super dealloc];
}

- (void)_setUpWebViewWithFrame:(CGRect)frame
{
	_webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
	_webView.backgroundColor = [UIColor clearColor];
	_webView.opaque = NO;
	_webView.delegate = self;
	
	// Disable webview scrolling.
	UIScrollView *scrollView = nil;
	for (UIView *v in _webView.subviews)
	{
		if ([v isKindOfClass:[UIScrollView class]])
		{
			scrollView = (UIScrollView *)v;
			break;
		}
	}
	
	if (scrollView)
	{
		scrollView.scrollEnabled = NO;
		scrollView.bounces = NO;
	}
}

- (void)setAdContentView:(UIView *)view
{
	if (view != _adContentView)
	{
		[_adContentView release];
		[_adContentView removeFromSuperview];
	}
	_adContentView = [view retain];
	[self addSubview:_adContentView];
}

- (void)loadAd
{
	NSString *urlString = [NSString stringWithFormat:@"http://%@/m/ad?v=3&udid=%@&q=%@&id=%@", 
						   HOSTNAME,
						   [[UIDevice currentDevice] uniqueIdentifier],
						   @"",
						   [self.adUnitId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
						   ];
	NSURL *URL = [NSURL URLWithString:urlString];
	[self loadAdWithURL:URL];
}

- (void)refreshAd
{
	[self loadAd];
}

- (void)loadAdWithURL:(NSURL *)URL
{
	if (!URL)
	{
		NSLog(@"MOPUB: URL was nil");
		return;
	}
	
	self.URL = URL;
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:self.URL 
																 cachePolicy:NSURLRequestUseProtocolCachePolicy 
															 timeoutInterval:3.0] autorelease];
	
	if (_isLoading) 
	{
		NSLog(@"wait to finish");
		return;
	}
	
	[_conn release];
	_conn = [[NSURLConnection connectionWithRequest:request delegate:self] retain];
	_isLoading = YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	// If the response is anything but a 200 (OK) or 300 (redirect) we call the response a failure and bail
	if ([response respondsToSelector:@selector(statusCode)])
	{
		int statusCode = [((NSHTTPURLResponse *)response) statusCode];
		if (statusCode >= 400)
		{
			[connection cancel];
			NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:
																		  NSLocalizedString(@"Server returned status code %d",@""),
																		  statusCode]
																  forKey:NSLocalizedDescriptionKey];
			NSError *statusError = [NSError errorWithDomain:@"mopub.com"
													   code:statusCode
												   userInfo:errorInfo];
			[self connection:connection didFailWithError:statusError];
			return;
		}
	}
	
	// initialize the data
	[_data setLength:0];
	
	// TODO: parse headers
	NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
	self.clickURL = [NSURL URLWithString:[headers objectForKey:@"X-Clickthrough"]];
	self.failURL = [NSURL URLWithString:[headers objectForKey:@"X-Failurl"]];
	
	// Determine ad type.
	NSString *typeHeader = [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"X-Adtype"];
	
	if (!typeHeader || [typeHeader isEqualToString:@"html"])
	{
		return;
	}
	else if ([typeHeader isEqualToString:@"clear"])
	{
		[connection cancel];
		_isLoading = NO;
		[self _backFillWithNothing];
		return;
	}
		
	NSString *classString = [[MPAdapterMap sharedAdapterMap] classStringForAdapterType:typeHeader];
	Class cls = NSClassFromString(classString);
	if (cls != nil)
	{
		_adapter.delegate = nil;
		[_adapter release];
		
		_adapter = (MPBaseAdapter *)[[cls alloc] init];
		_adapter.delegate = self;
		NSDictionary *params = [(NSHTTPURLResponse *)response allHeaderFields];
		[_adapter getAdWithParams:params];
		
		[connection cancel];
		_isLoading = NO;
	}
	else 
	{
		[connection cancel];
		_isLoading = NO;

		[self loadAdWithURL:self.failURL];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d {
	[_data appendData:d];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSLog(@"MOPUB: failed to load ad content... %@", error);
	
	// TODO: should we fill with nothing?
	_isLoading = NO;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	// set the content into the webview	
	
	_webView.delegate = self;
	[_webView loadData:_data MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:self.URL];
	[self addSubview:_webView];
	
	// print out the response for debugging purposes
	NSString *response = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
	NSLog(@"MOPUB: response %@",response);
	[response release];
	
	_isLoading = NO;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSURL *URL = [request URL];
	
	if (navigationType == UIWebViewNavigationTypeLinkClicked)
	{
		[self _adLinkClicked:URL];
		return NO;
	}
	
	return YES;
}

- (void)_adLinkClicked:(NSURL *)URL
{
	NSString *redirectURLString = [self _escapeURL:URL];	
	NSURL *desiredURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&r=%@",
											  _clickURL,
											  redirectURLString]];
	
	// TODO: signal delegate that ad browser will open

	AdClickController *adClickController = [[[AdClickController alloc] initWithURL:desiredURL delegate:self] autorelease];
	[[self.delegate viewControllerForPresentingModalView] presentModalViewController:adClickController animated:YES];
	
	// TODO: signal delegate that ad browser did open
}

- (void)_backFillWithNothing
{
	self.backgroundColor = [UIColor clearColor];
	self.hidden = YES;
	
	// Notify delegate that the ad has failed to load.
	if ([self.delegate respondsToSelector:@selector(adViewDidFailToLoadAd:)]){
		[self.delegate adViewDidFailToLoadAd:self];
	}
}

- (void)dismissModalViewForAdClickController:(AdClickController *)adClickController
{
	[[self.delegate viewControllerForPresentingModalView] dismissModalViewControllerAnimated:YES];
}

- (NSString *)_escapeURL:(NSURL *)URL
{
	NSMutableString *redirectUrl = [NSMutableString stringWithString:[URL absoluteString]];
	NSRange wholeString = NSMakeRange(0, [redirectUrl length]);
	[redirectUrl replaceOccurrencesOfString:@"&" withString:@"%26" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"+" withString:@"%2B" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"," withString:@"%2C" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@":" withString:@"%3A" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@";" withString:@"%3B" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"=" withString:@"%3D" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"?" withString:@"%3F" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"@" withString:@"%40" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@" " withString:@"%20" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"\t" withString:@"%09" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"#" withString:@"%23" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"<" withString:@"%3C" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@">" withString:@"%3E" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"\"" withString:@"%22" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"\n" withString:@"%0A" options:NSCaseInsensitiveSearch range:wholeString];
	
	return redirectUrl;
}

#pragma mark -
#pragma mark MPAdapterDelegate

- (void)adapterDidFinishLoadingAd:(MPBaseAdapter *)adapter
{
	if ([self.delegate respondsToSelector:@selector(adViewDidLoadAd:)])
		[self.delegate adViewDidLoadAd:self];
}

- (void)adapter:(MPBaseAdapter *)adapter didFailToLoadAdWithError:(NSError *)error
{
	[self loadAdWithURL:self.failURL];
	// TODO: handle error
}

@end
