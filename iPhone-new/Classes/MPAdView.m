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
@synthesize clickURL = _clickURL, interceptURL = _interceptURL, failURL = _failURL;
@synthesize keywords = _keywords, location = _location;
@synthesize shouldInterceptLinks = _shouldInterceptLinks, scrollable = _scrollable;

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) 
	{
		self.backgroundColor = [UIColor clearColor];
		[self _setUpWebViewWithFrame:frame];
		self.adUnitId = PUB_ID_320x50;
		_data = [[NSMutableData data] retain];
		self.URL = nil;
		self.shouldInterceptLinks = YES;
		self.scrollable = NO;
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
	[_clickURL release];
	[_interceptURL release];
	[_failURL release];
	[_keywords release];
	[_location release];
    [super dealloc];
}

- (void)setScrollable:(BOOL)scrollable
{
	_scrollable = scrollable;
	if (_webView)
	{
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
			scrollView.scrollEnabled = scrollable;
			scrollView.bounces = scrollable;
		}
	}
}

- (void)_setUpWebViewWithFrame:(CGRect)frame
{
	_webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
	_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_webView.backgroundColor = [UIColor clearColor];
	_webView.opaque = NO;
	_webView.delegate = self;
	
	// Disable webview scrolling.
	self.scrollable = NO;
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

- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation
{
	[_adapter rotateToOrientation:newOrientation];
}

- (void)loadAd
{
	[self loadAdWithURL:nil];
}

- (void)refreshAd
{
	[self loadAdWithURL:nil];
}

- (void)loadAdWithURL:(NSURL *)URL
{
	// If the passed-in URL is nil, construct a URL from our initial parameters.
	if (!URL)
	{
		NSString *urlString = [NSString stringWithFormat:@"http://%@/m/ad?v=3&udid=%@&q=%@&id=%@", 
							   HOSTNAME,
							   [[UIDevice currentDevice] uniqueIdentifier],
							   [self.keywords stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
							   [self.adUnitId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
							   ];
		
		// Append location data if we have it.
		if (self.location)
		{
			urlString = [urlString stringByAppendingFormat:@"&ll=%f,%f",
						 self.location.coordinate.latitude,
						 self.location.coordinate.longitude];
		}
		
		// TODO: exclude parameters
		
		URL = [NSURL URLWithString:urlString];
	}
	
	self.URL = URL;
	NSLog(@"URL: %@", URL);
	
	// Inform delegate that we are about to start loading an ad.
	if ([self.delegate respondsToSelector:@selector(adViewWillLoadAd:)])
		[self.delegate adViewWillLoadAd:self];
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] initWithURL:self.URL 
																 cachePolicy:NSURLRequestUseProtocolCachePolicy 
															 timeoutInterval:3.0] autorelease];
	
	// Set the user agent so that we know where the request is coming from. 
	// !important for targeting!
	if ([request respondsToSelector:@selector(setValue:forHTTPHeaderField:)]) {
		NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
		NSString *systemName = [[UIDevice currentDevice] systemName];
		NSString *model = [[UIDevice currentDevice] model];
		NSString *bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
		NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];			
		NSString *userAgentString = [NSString stringWithFormat:@"%@/%@ (%@; U; CPU %@ %@ like Mac OS X; %@)",
									 bundleName,appVersion,model,
									 systemName,systemVersion,[[NSLocale currentLocale] localeIdentifier]];
		[request setValue:userAgentString forHTTPHeaderField:@"User-Agent"];
	}		
	
	// If this ad view is already loading a request, don't proceed; instead, wait
	// for the previous load to finish.
	if (_isLoading) 
	{
		NSLog(@"MOPUB: ad view already loading an ad, wait to finish.");
		return;
	}
	
	[_conn release];
	_conn = [[NSURLConnection connectionWithRequest:request delegate:self] retain];
	NSLog(@"request fired");
	_isLoading = YES;
}

# pragma mark -
# pragma mark NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	// If the response is anything but a 200 (OK) or 300 (redirect), we call the response a failure and bail.
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
	
	// Initialize data.
	[_data setLength:0];
	
	if ([self.delegate respondsToSelector:@selector(adControllerDidReceiveResponseParams:)])
		[self.delegate adControllerDidReceiveResponseParams:[(NSHTTPURLResponse*)response allHeaderFields]];
	
	// Parse response headers.
	NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
	self.clickURL = [NSURL URLWithString:[headers objectForKey:@"X-Clickthrough"]];
	self.interceptURL = [NSURL URLWithString:[headers objectForKey:@"X-Launchpage"]];
	self.failURL = [NSURL URLWithString:[headers objectForKey:@"X-Failurl"]];
	
	NSString *shouldInterceptLinksString = [headers objectForKey:@"X-Interceptlinks"];
	if (shouldInterceptLinksString)
		self.shouldInterceptLinks = [shouldInterceptLinksString boolValue];
	
	NSString *scrollableString = [headers objectForKey:@"X-Scrollable"];
	if (scrollableString)
		self.scrollable = [scrollableString boolValue];
	
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
	
	// Obtain adapter for specified ad type.
	NSString *classString = [[MPAdapterMap sharedAdapterMap] classStringForAdapterType:typeHeader];
	Class cls = NSClassFromString(classString);
	if (cls != nil)
	{
		_adapter.delegate = nil;
		[_adapter release];
		
		_adapter = (MPBaseAdapter *)[[cls alloc] init];
		_adapter.delegate = self;
		
		// Tell adapter to fire off ad request.
		NSDictionary *params = [(NSHTTPURLResponse *)response allHeaderFields];
		[_adapter getAdWithParams:params];
		
		[connection cancel];
		_isLoading = NO;
	}
	// If there's no adapter for the specified ad type, just fail over.
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
	NSLog(@"MOPUB: ad view failed to load any content. %@", error);

	_isLoading = NO;
	[self _backFillWithNothing];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	// Put any HTML content into the webview.
	_webView.delegate = self;
	[_webView loadData:_data MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:self.URL];
	[self setAdContentView:_webView];
	
	// Print out the response, for debugging.
	NSString *response = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
	NSLog(@"MOPUB: response %@",response);
	[response release];
	
	_isLoading = NO;
}

# pragma mark -

- (void)didCloseAd:(id)sender
{
	[_webView stringByEvaluatingJavaScriptFromString:@"webViewDidClose();"];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSURL *URL = [request URL];
	
	if ([[URL scheme] isEqualToString:@"mopub"])
	{
		NSString *host = [URL host];
		if ([host isEqualToString:@"close"])
		{
			[self didCloseAd:nil];
		}
		else if ([host isEqualToString:@"finishLoad"])
		{
			_webViewIsLoading = NO;
			_webView.hidden = NO;
			
			// Notify delegate that an ad has been loaded.
			if ([self.delegate respondsToSelector:@selector(adViewDidLoadAd:)]) 
				[self.delegate adViewDidLoadAd:self];
		}
		else if ([host isEqualToString:@"failLoad"])
		{
			_webViewIsLoading = NO;
			_webView.hidden = NO;
			
			// Notify delegate that an ad failed to load.
			if ([self.delegate respondsToSelector:@selector(adViewDidFailToLoadAd:)]) 
				[self.delegate adViewDidFailToLoadAd:self];
		}
		else if ([host isEqualToString:@"open"])
		{
			[self _adLinkClicked:URL];
		}
		
		return NO;
	}
	
	if (navigationType == UIWebViewNavigationTypeOther && 
		self.shouldInterceptLinks && 
		self.interceptURL &&
		[[URL absoluteString] hasPrefix:[self.interceptURL absoluteString]])
	{
		[self _adLinkClicked:URL];
		return NO;
	}

	if (navigationType == UIWebViewNavigationTypeLinkClicked && self.shouldInterceptLinks)
	{
		[self _adLinkClicked:URL];
		return NO;
	}
	
	// Other stuff (e.g. JavaScript) should load as usual.
	return YES;
}

- (void)_adLinkClicked:(NSURL *)URL
{
	NSString *redirectURLString = [self _escapeURL:URL];	
	NSURL *desiredURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&r=%@",
											  _clickURL,
											  redirectURLString]];
	
	// Notify delegate that the ad browser is about to open.
	if ([self.delegate respondsToSelector:@selector(willPresentModalViewForAd:)])
		[self.delegate willPresentModalViewForAd:self];

	// Present ad browser.
	AdClickController *adClickController = [[[AdClickController alloc] initWithURL:desiredURL delegate:self] autorelease];
	[[self.delegate viewControllerForPresentingModalView] presentModalViewController:adClickController animated:YES];
	
	// Notify delegate that the ad browser has been presented.
	if ([self.delegate respondsToSelector:@selector(didPresentModalViewForAd:)])
		[self.delegate didPresentModalViewForAd:self];
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

- (void)_trackClickWithURL:(NSURL *)clickURL
{
	NSURLRequest *clickURLRequest = [NSURLRequest requestWithURL:clickURL];
	NSURLConnection *conn = [NSURLConnection connectionWithRequest:clickURLRequest delegate:nil];
	NSLog(@"MOPUB: tracking click %@", clickURL);
}

// TODO: change the name of this
- (void)viewDidAppear
{
	[_webView stringByEvaluatingJavaScriptFromString:@"webviewDidAppear();"]; 
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

- (void)adClickedForAdapter:(MPBaseAdapter *)adapter
{
	[self _trackClickWithURL:self.clickURL];
	
	// Notify delegate that an ad was clicked.
	if ([self.delegate respondsToSelector:@selector(nativeAdClicked:)])
		[self.delegate nativeAdClicked:self];
}

@end
