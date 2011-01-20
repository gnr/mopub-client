//
//  MPAdView.m
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import "MPAdView.h"
#import "MPBaseAdapter.h"

@interface MPAdView (Internal)
- (void)_setUpWebViewWithFrame:(CGRect)frame;
- (void)_adLinkClicked:(NSURL *)URL;
- (NSString *)_escapeURL:(NSURL *)URL;
@end

@implementation MPAdView

@synthesize delegate = _delegate, adUnitId = _adUnitId;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
		[self _setUpWebViewWithFrame:frame];
		self.adUnitId = PUB_ID_320x50;
		_data = [[NSMutableData data] retain];
		_url = nil;
		_isLoading = NO;
    }
    return self;
}

- (void)dealloc {
	[_adContentView release];
	[_webView release];
	[_adUnitId release];
	[_data release];
	[_url release];
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
	_url = [[NSURL URLWithString:urlString] copy];
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:_url 
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

- (void)refreshAd
{
	[self loadAd];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	
	//
	// if the response is anything but a 200 (OK) or 300 (redirect) we call the response a failure and bail
	//
	if ([response respondsToSelector:@selector(statusCode)])
	{
		int statusCode = [((NSHTTPURLResponse *)response) statusCode];
		if (statusCode >= 400)
		{
			[connection cancel];  // stop connecting; no more delegate messages
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
	
	_clickURL = [[[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"X-Clickthrough"] copy];
	
	// TODO: parse headers
	NSString *typeHeader = [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"X-Adtype"];
	NSString *classString = [NSString stringWithFormat:@"MP%@Adapter", @"IAd"];
	Class cls = NSClassFromString(classString);
	if (cls != nil)
	{
		MPBaseAdapter *adapter = (MPBaseAdapter *)[[cls alloc] init];
		adapter.delegate = self;
		[adapter getAd];
		[connection cancel];
	}
}

// standard data appending
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d {
	[_data appendData:d];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSLog(@"MOPUB: failed to load ad content... %@", error);
	
	//[self backfillWithNothing];
	//	[connection release];
	//adLoading = NO;
	//[loadingIndicator stopAnimating];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	// set the content into the webview	
	
	_webView.delegate = self;
	[_webView loadData:_data MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:_url];
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

@end
