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
#import <CommonCrypto/CommonDigest.h>

@interface MPAdView (Internal)
- (void)setUpWebViewWithFrame:(CGRect)frame;
- (void)adLinkClicked:(NSURL *)URL;
- (void)backFillWithNothing;
- (void)trackClickWithURL:(NSURL *)clickURL;
- (void)trackImpressionWithURL:(NSURL *)impTrackerURL;
- (NSDictionary *)queryToDictionary:(NSString *)query;
@end

@implementation MPAdView

@synthesize delegate = _delegate;
@synthesize adUnitId = _adUnitId;
@synthesize URL = _URL;
@synthesize clickURL = _clickURL;
@synthesize interceptURL = _interceptURL;
@synthesize failURL = _failURL;
@synthesize impTrackerURL = _impTrackerURL;
@synthesize keywords = _keywords;
@synthesize location = _location;
@synthesize shouldInterceptLinks = _shouldInterceptLinks;
@synthesize scrollable = _scrollable;

#pragma mark -
#pragma mark Lifecycle

- (id)initWithFrame:(CGRect)frame 
{    
    self = [super initWithFrame:frame];
    if (self) 
	{
		self.backgroundColor = [UIColor clearColor];
		[self setUpWebViewWithFrame:frame];
		_adUnitId = PUB_ID_320x50;
		_data = [[NSMutableData data] retain];
		_excludeParams = [[NSMutableArray array] retain];
		_shouldInterceptLinks = YES;
		_scrollable = NO;
		_isLoading = NO;
		_store = [MPStore sharedStore];
    }
    return self;
}

- (void)dealloc 
{
	[_adContentView release];
	[_adapter release];
	[_webView release];
	[_adUnitId release];
	[_data release];
	[_URL release];
	[_clickURL release];
	[_interceptURL release];
	[_failURL release];
	[_impTrackerURL release];
	[_excludeParams release];
	[_keywords release];
	[_location release];
    [super dealloc];
}

#pragma mark -
#pragma mark Internal

- (void)setUpWebViewWithFrame:(CGRect)frame
{
	_webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
	_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_webView.backgroundColor = [UIColor clearColor];
	_webView.opaque = NO;
	_webView.delegate = self;
	
	// Disable webview scrolling.
	self.scrollable = NO;
}

- (void)adLinkClicked:(NSURL *)URL
{
	NSString *redirectURLString = [[URL absoluteString] URLescapedString];	
	NSURL *desiredURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&r=%@",
											  _clickURL,
											  redirectURLString]];
	
	// Notify delegate that the ad browser is about to open.
	if ([self.delegate respondsToSelector:@selector(willPresentModalViewForAd:)])
		[self.delegate willPresentModalViewForAd:self];
	
	// Present ad browser.
	MPAdBrowserController *browserController = [[[MPAdBrowserController alloc] initWithURL:desiredURL 
																				  delegate:self] autorelease];
	[[self.delegate viewControllerForPresentingModalView] presentModalViewController:browserController animated:YES];
	
	// Notify delegate that the ad browser has been presented.
	if ([self.delegate respondsToSelector:@selector(didPresentModalViewForAd:)])
		[self.delegate didPresentModalViewForAd:self];
}

- (void)backFillWithNothing
{
	self.backgroundColor = [UIColor clearColor];
	self.hidden = YES;
	
	// Notify delegate that the ad has failed to load.
	if ([self.delegate respondsToSelector:@selector(adViewDidFailToLoadAd:)]){
		[self.delegate adViewDidFailToLoadAd:self];
	}
}

- (void)trackClickWithURL:(NSURL *)clickURL
{
	NSURLRequest *clickURLRequest = [NSURLRequest requestWithURL:clickURL];
	[NSURLConnection connectionWithRequest:clickURLRequest delegate:nil];
	NSLog(@"MOPUB: tracking click %@", clickURL);
}

- (void)trackImpressionWithURL:(NSURL *)impTrackerURL
{
	NSURLRequest *impTrackerURLRequest = [NSURLRequest requestWithURL:impTrackerURL];
	[NSURLConnection connectionWithRequest:impTrackerURLRequest delegate:nil];
	NSLog(@"MOPUB: tracking impression %@", impTrackerURL);
}

- (NSDictionary *)queryToDictionary:(NSString *)query
{
	NSMutableDictionary *queryDict = [[NSMutableDictionary alloc] initWithCapacity:1];
	NSArray *queryElements = [query componentsSeparatedByString:@"&"];
	for (NSString *element in queryElements) {
		NSArray *keyVal = [element componentsSeparatedByString:@"="];
		NSString *key = [keyVal objectAtIndex:0];
		NSString *value = [keyVal lastObject];
		[queryDict setObject:[value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] 
					  forKey:key];
	}
	return [queryDict autorelease];
}

#pragma mark -

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

- (void)setAdContentView:(UIView *)view
{
	if (view != _adContentView)
	{
		[_adContentView release];
		[_adContentView removeFromSuperview];
	}
	_adContentView = [view retain];
	[self addSubview:_adContentView];
	self.hidden = NO;
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
	[_excludeParams removeAllObjects];
	[self loadAdWithURL:nil];
}

- (void)loadAdWithURL:(NSURL *)URL
{
	// If the passed-in URL is nil, construct a URL from our initial parameters.
	if (!URL)
	{
		NSString *urlString = [NSString stringWithFormat:@"http://%@/m/ad?v=3&udid=%@&q=%@&id=%@", 
							   HOSTNAME,
							   [[UIDevice currentDevice] hashedMopubUDID],
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
		
		// Append exclude parameters.
		for (NSString *exclude in _excludeParams)
		{
			urlString = [urlString stringByAppendingFormat:@"&exclude=%@", exclude];
		}
		
		URL = [NSURL URLWithString:urlString];
	}
	
	self.URL = URL;
	NSLog(@"loadAdWithURL: %@", URL);
	
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
									 bundleName, appVersion, model,
									 systemName, systemVersion, [[NSLocale currentLocale] localeIdentifier]];
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
	
	if ([self.delegate respondsToSelector:@selector(adViewDidReceiveResponseParams:)])
		[self.delegate adViewDidReceiveResponseParams:[(NSHTTPURLResponse*)response allHeaderFields]];
	
	// Parse response headers.
	NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
	self.clickURL = [NSURL URLWithString:[headers objectForKey:@"X-Clickthrough"]];
	self.interceptURL = [NSURL URLWithString:[headers objectForKey:@"X-Launchpage"]];
	self.failURL = [NSURL URLWithString:[headers objectForKey:@"X-Failurl"]];
	self.impTrackerURL = [NSURL URLWithString:[headers objectForKey:@"X-Imptrackerurl"]];
	
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
		// HTML ad, so just return. connectionDidFinishLoading: will take care of the rest.
		return;
	}
	else if ([typeHeader isEqualToString:@"clear"])
	{
		// Show a blank.
		[connection cancel];
		_isLoading = NO;
		[self backFillWithNothing];
		return;
	}
	
	// Obtain adapter for specified ad type.
	NSString *classString = [[MPAdapterMap sharedAdapterMap] classStringForAdapterType:typeHeader];
	Class cls = NSClassFromString(classString);
	if (cls != nil)
	{
		_adapter.adView = nil;
		[_adapter release];
		
		_adapter = (MPBaseAdapter *)[[cls alloc] init];
		_adapter.adView = self;
		
		[connection cancel];
		//_isLoading = NO;
		
		// Tell adapter to fire off ad request.
		NSDictionary *params = [(NSHTTPURLResponse *)response allHeaderFields];
		[_adapter getAdWithParams:params];
	}
	// There's no adapter for the specified ad type, so just fail over.
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
	[self backFillWithNothing];
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
	
	//_isLoading = NO;
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
			
			_isLoading = NO;
			
			// Notify delegate that an ad has been loaded.
			if ([self.delegate respondsToSelector:@selector(adViewDidLoadAd:)]) 
				[self.delegate adViewDidLoadAd:self];
		}
		else if ([host isEqualToString:@"failLoad"])
		{
			_webViewIsLoading = NO;
			_webView.hidden = NO;
			
			_isLoading = NO;
			
			// Notify delegate that an ad failed to load.
			if ([self.delegate respondsToSelector:@selector(adViewDidFailToLoadAd:)]) 
				[self.delegate adViewDidFailToLoadAd:self];
		}
		else if ([host isEqualToString:@"open"])
		{
			[self adLinkClicked:URL];
		}
		else if ([host isEqualToString:@"inapp"])
		{
			NSDictionary *queryDict = [self queryToDictionary:[URL query]];
			[_store initiatePurchaseForProductIdentifier:[queryDict objectForKey:@"id"] 
												quantity:[[queryDict objectForKey:@"num"] intValue]];
		}
		
		return NO;
	}
	
	if (navigationType == UIWebViewNavigationTypeOther && 
		self.shouldInterceptLinks && 
		self.interceptURL &&
		[[URL absoluteString] hasPrefix:[self.interceptURL absoluteString]])
	{
		[self adLinkClicked:URL];
		return NO;
	}

	if (navigationType == UIWebViewNavigationTypeLinkClicked && self.shouldInterceptLinks)
	{
		[self adLinkClicked:URL];
		return NO;
	}
	
	// Other stuff (e.g. JavaScript) should load as usual.
	return YES;
}

- (void)dismissModalViewForBrowserController:(MPAdBrowserController *)browserController
{
	[[self.delegate viewControllerForPresentingModalView] dismissModalViewControllerAnimated:YES];
}

- (void)adViewDidAppear
{
	[_webView stringByEvaluatingJavaScriptFromString:@"webviewDidAppear();"]; 
}

- (void)customEventDidLoadAd
{
	_isLoading = NO;
	[self trackImpressionWithURL:self.impTrackerURL];
}

- (void)customEventDidFailToLoadAd
{
	_isLoading = NO;
	[self loadAdWithURL:self.failURL];
}

#pragma mark -
#pragma mark MPAdapterDelegate

- (void)adapterDidFinishLoadingAd:(MPBaseAdapter *)adapter
{
	_isLoading = NO;
	if ([self.delegate respondsToSelector:@selector(adViewDidLoadAd:)])
		[self.delegate adViewDidLoadAd:self];
}

- (void)adapter:(MPBaseAdapter *)adapter didFailToLoadAdWithError:(NSError *)error
{
	_isLoading = NO;
	NSLog(@"MOPUB: Adapter failed to load ad. Error: %@", error);
	[self loadAdWithURL:self.failURL];
}

- (void)adClickedForAdapter:(MPBaseAdapter *)adapter
{
	[self trackClickWithURL:self.clickURL];
	
	// Notify delegate that an ad was clicked.
	if ([self.delegate respondsToSelector:@selector(nativeAdClicked:)])
		[self.delegate nativeAdClicked:self];
}

@end

#pragma mark -
#pragma mark Categories

@implementation UIDevice (MPAdditions)

- (NSString *)hashedMopubUDID 
{
	NSString *result = nil;
	NSString *udid = [NSString stringWithFormat:@"mopub-%@", [UIDevice currentDevice].uniqueIdentifier];
	
	if (udid) 
	{
		unsigned char digest[16];
		NSData *data = [udid dataUsingEncoding:NSASCIIStringEncoding];
		CC_MD5([data bytes], [data length], digest);
		
		result = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
				  digest[0], digest[1], 
				  digest[2], digest[3],
				  digest[4], digest[5],
				  digest[6], digest[7],
				  digest[8], digest[9],
				  digest[10], digest[11],
				  digest[12], digest[13],
				  digest[14], digest[15]];
		result = [result uppercaseString];
	}
	return [NSString stringWithFormat:@"md5:%@", result];
}

@end

@implementation NSString (MPAdditions)

- (NSString *)URLescapedString
{
	NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
																		   (CFStringRef)self,
																		   NULL,
																		   (CFStringRef)@"!*'();:@&=+$,/?%#[]<>",
																		   kCFStringEncodingUTF8);
	return result;
}

@end

