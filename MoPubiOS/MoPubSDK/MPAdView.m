//
//  MPAdView.m
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 MoPub, Inc. All rights reserved.
//

#import "MPAdView.h"
#import "MPBaseAdapter.h"
#import "MPAdapterMap.h"
#import "MPTimer.h"
#import "CJSONDeserializer.h"
#import <CommonCrypto/CommonDigest.h>
#import <stdlib.h>
#import <time.h>

static NSString * const kTimerNotificationName		= @"Autorefresh";
static NSString * const kAdAnimationId				= @"MPAdTransition";
static NSString * const kErrorDomain				= @"mopub.com";
static NSString * const kMoPubUrlScheme				= @"mopub";
static NSString * const kMoPubCloseHost				= @"close";
static NSString * const kMoPubFinishLoadHost		= @"finishLoad";
static NSString * const kMoPubFailLoadHost			= @"failLoad";
static NSString * const kMoPubInAppHost				= @"inapp";
static NSString * const kMoPubCustomHost			= @"custom";
static NSString * const kMoPubInterfaceOrientationPortraitId	= @"p";
static NSString * const kMoPubInterfaceOrientationLandscapeId	= @"l";
static const CGFloat kMoPubRequestTimeoutInterval	= 10.0;
static const CGFloat kMoPubRequestRetryInterval     = 60.0;

// Ad header key/value constants.
static NSString * const kClickthroughHeaderKey		= @"X-Clickthrough";
static NSString * const kLaunchpageHeaderKey		= @"X-Launchpage";
static NSString * const kFailUrlHeaderKey			= @"X-Failurl";
static NSString * const kImpressionTrackerHeaderKey	= @"X-Imptracker";
static NSString * const kInterceptLinksHeaderKey	= @"X-Interceptlinks";
static NSString * const kScrollableHeaderKey		= @"X-Scrollable";
static NSString * const kWidthHeaderKey				= @"X-Width";
static NSString * const kHeightHeaderKey			= @"X-Height";
static NSString * const kRefreshTimeHeaderKey		= @"X-Refreshtime";
static NSString * const kAnimationHeaderKey			= @"X-Animation";
static NSString * const kAdTypeHeaderKey			= @"X-Adtype";
static NSString * const kNetworkTypeHeaderKey		= @"X-Networktype";
static NSString * const kAdTypeHtml					= @"html";
static NSString * const kAdTypeClear				= @"clear";
static NSString * userAgentString;

@interface MPAdView (Internal)
- (void)registerForApplicationStateTransitionNotifications;
- (void)destroyWebviewPool;
- (void)scheduleAutorefreshTimer;
- (void)setScrollable:(BOOL)scrollable forView:(UIView *)view;
- (void)animateTransitionToAdView:(UIView *)view;
- (UIWebView *)makeAdWebViewWithFrame:(CGRect)frame;
- (void)adLinkClicked:(NSURL *)URL;
- (void)backFillWithNothing;
- (void)trackClick;
- (void)trackImpression;
- (NSDictionary *)dictionaryFromQueryString:(NSString *)query;
- (void)applicationDidEnterBackground;
- (void)applicationWillEnterForeground;
- (void)customLinkClickedForSelectorString:(NSString *)selectorString 
							withDataString:(NSString *)dataString;
- (void)replaceCurrentAdapterWithAdapter:(MPBaseAdapter *)newAdapter;
- (NSURL *)serverRequestUrl;
- (NSString *)orientationQueryStringComponent;
- (NSString *)scaleFactorQueryStringComponent;
- (NSString *)timeZoneQueryStringComponent;
- (NSString *)locationQueryStringComponent;
- (NSURLRequest *)serverRequestObjectForUrl:(NSURL *)url;
@end

@interface MPAdView ()
@property (nonatomic, copy) NSURL *clickURL;
@property (nonatomic, copy) NSURL *interceptURL;
@property (nonatomic, copy) NSURL *failURL;
@property (nonatomic, copy) NSURL *impTrackerURL;
@property (nonatomic, assign) BOOL shouldInterceptLinks;
@property (nonatomic, assign) BOOL scrollable;
@property (nonatomic, retain) MPTimer *autorefreshTimer;
@property (nonatomic, assign) BOOL isLoading;
@end

@implementation MPAdView

@synthesize delegate = _delegate;
@synthesize adUnitId = _adUnitId;
@synthesize URL = _URL;
@synthesize clickURL = _clickURL;
@synthesize interceptURL = _interceptURL;
@synthesize failURL = _failURL;
@synthesize impTrackerURL = _impTrackerURL;
@synthesize creativeSize = _creativeSize;
@synthesize keywords = _keywords;
@synthesize location = _location;
@synthesize shouldInterceptLinks = _shouldInterceptLinks;
@synthesize scrollable = _scrollable;
@synthesize autorefreshTimer = _autorefreshTimer;
@synthesize ignoresAutorefresh = _ignoresAutorefresh;
@synthesize stretchesWebContentToFill = _stretchesWebContentToFill;
@synthesize isLoading = _isLoading;

#pragma mark -
#pragma mark Lifecycle

+ (void)initialize
{
	UIWebView *webview = [[UIWebView alloc] init];
	userAgentString = [[webview stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"] copy];
	[webview release];
	srandom(time(NULL));
}

- (id)initWithAdUnitId:(NSString *)adUnitId size:(CGSize)size 
{   
	CGRect f = (CGRect){{0, 0}, size};
    if (self = [super initWithFrame:f]) 
	{
		self.backgroundColor = [UIColor clearColor];
		self.clipsToBounds = YES;
		_adUnitId = (adUnitId) ? [adUnitId copy] : DEFAULT_PUB_ID;
		_data = [[NSMutableData data] retain];
		_shouldInterceptLinks = YES;
		_scrollable = NO;
		_isLoading = NO;
		_ignoresAutorefresh = NO;
		_store = [MPStore sharedStore];
		_animationType = MPAdAnimationTypeNone;
		_originalSize = size;
		_webviewPool = [[NSMutableSet set] retain];
		[self registerForApplicationStateTransitionNotifications];
		_timerTarget = [[MPTimerTarget alloc] initWithNotificationName:kTimerNotificationName];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(forceRefreshAd)
													 name:kTimerNotificationName
												   object:_timerTarget];
    }
    return self;
}

- (void)registerForApplicationStateTransitionNotifications
{
	// iOS version > 4.0: Register for relevant application state transition notifications.
	if (&UIApplicationDidEnterBackgroundNotification != nil)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(applicationDidEnterBackground) 
													 name:UIApplicationDidEnterBackgroundNotification 
												   object:[UIApplication sharedApplication]];
	}		
	if (&UIApplicationWillEnterForegroundNotification != nil)
	{
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(applicationWillEnterForeground)
													 name:UIApplicationWillEnterForegroundNotification 
												   object:[UIApplication sharedApplication]];
	}
}

- (void)dealloc 
{
	_delegate = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];	
	
	// If our content has a delegate, set its delegate to nil.
	if ([_adContentView respondsToSelector:@selector(setDelegate:)])
		[_adContentView performSelector:@selector(setDelegate:) withObject:nil];
	[_adContentView release];
	
	[self destroyWebviewPool];
	
	[_currentAdapter unregisterDelegate];
	[_currentAdapter release];
	[_previousAdapter unregisterDelegate];
	[_previousAdapter release];
	[_adUnitId release];
	[_conn cancel];
	[_conn release];
	[_data release];
	[_URL release];
	[_clickURL release];
	[_interceptURL release];
	[_failURL release];
	[_impTrackerURL release];
	[_keywords release];
	[_location release];
	[_autorefreshTimer invalidate];
	[_autorefreshTimer release];
	[_timerTarget release];
    [super dealloc];
}

- (void)destroyWebviewPool
{
	for (UIWebView *webview in _webviewPool)
	{
		[webview setDelegate:nil];
		[webview stopLoading];
	}
	[_webviewPool release];
}

#pragma mark -

- (void)setAdContentView:(UIView *)view
{
	if (!view) return;
	[view retain];
	
	if (_stretchesWebContentToFill && [view isKindOfClass:[UIWebView class]])
	{
		// Avoids a race condition: 
		// 1) a webview is initialized with the ad view's bounds
		// 2) ad view resizes its frame before webview gets set as the content view
		view.frame = self.bounds;
	}
	
	self.hidden = NO;
	
	// We don't necessarily know where this view came from, so make sure its scrollability
	// corresponds to our value of self.scrollable.
	[self setScrollable:self.scrollable forView:view];
	
	[self animateTransitionToAdView:view];
}

- (void)animateTransitionToAdView:(UIView *)view
{
	MPAdAnimationType type = (_animationType == MPAdAnimationTypeRandom) ? 
		(random() % (MPAdAnimationTypeCount - 2)) + 2 : _animationType;
	
	// Special case: if there's currently no ad content view, certain transitions will
	// look strange (e.g. CurlUp / CurlDown). We'll just omit the transition.
	if (!_adContentView) type = MPAdAnimationTypeNone;
	
	if (type == MPAdAnimationTypeFade) view.alpha = 0.0;
	
	MPLogDebug(@"Ad view (%p) is using animationType: %d", self, type);
	
	[UIView beginAnimations:kAdAnimationId context:view];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	[UIView setAnimationDuration:1.0];
	
	switch (type)
	{
		case MPAdAnimationTypeFlipFromLeft:
			[self addSubview:view];
			[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft 
								   forView:self 
									 cache:YES];
			break;
		case MPAdAnimationTypeFlipFromRight:
			[self addSubview:view];
			[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight
								   forView:self 
									 cache:YES];
			break;
		case MPAdAnimationTypeCurlUp:
			[self addSubview:view];
			[UIView setAnimationTransition:UIViewAnimationTransitionCurlUp
								   forView:self 
									 cache:YES];
			break;
		case MPAdAnimationTypeCurlDown:
			[self addSubview:view];
			[UIView setAnimationTransition:UIViewAnimationTransitionCurlDown
								   forView:self 
									 cache:YES];
			break;
		case MPAdAnimationTypeFade:
			[UIView setAnimationCurve:UIViewAnimationCurveLinear];
			[self addSubview:view];
			view.alpha = 1.0;
			break;
		default:
			[self addSubview:view];
			break;
	}
	
	[UIView commitAnimations];
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished 
				 context:(void *)context
{
	if ([animationID isEqualToString:kAdAnimationId])
	{
		UIView *viewAddedToHierarchy = (UIView *)context;
		
		// Remove the old ad content view from the view hierarchy, but first confirm that it's
		// not the same as the new view; otherwise, we'll be left with no content view.
		if (_adContentView != viewAddedToHierarchy)
		{
			[_adContentView removeFromSuperview];
			
			// Additionally, do webview-related cleanup if the old _adContentView was a webview.
			if ([_adContentView isKindOfClass:[UIWebView class]])
			{
				[(UIWebView *)_adContentView setDelegate:nil];
				[(UIWebView *)_adContentView stopLoading];
				[_webviewPool removeObject:_adContentView];
			}
		}
		
		// Release _adContentView, since -setAdContentView: retained it.
		[_adContentView release];
		
		_adContentView = viewAddedToHierarchy;
	}
}

- (CGSize)adContentViewSize
{
	return (!_adContentView) ? _originalSize : _adContentView.bounds.size;
}

- (void)setIgnoresAutorefresh:(BOOL)ignoresAutorefresh
{
	_ignoresAutorefresh = ignoresAutorefresh;
	
	if (_ignoresAutorefresh) 
	{
		MPLogInfo(@"Ad view (%p) is now ignoring autorefresh.", self);
		if ([self.autorefreshTimer isScheduled]) [self.autorefreshTimer pause];
	}
	else 
	{
		MPLogInfo(@"Ad view (%p) is no longer ignoring autorefresh.", self);
		if ([self.autorefreshTimer isScheduled]) [self.autorefreshTimer resume];
	}
}

- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation
{
	// Pass along this notification to the adapter, so that it can handle the orientation change.
	[_currentAdapter rotateToOrientation:newOrientation];
}

- (void)loadAd
{
	[self loadAdWithURL:nil];
}

- (void)refreshAd
{
	[self.autorefreshTimer invalidate];
	[self loadAdWithURL:nil];
}

- (void)forceRefreshAd
{
	// Cancel any existing request to the ad server.
	[_conn cancel];
	
	_isLoading = NO;
	[self.autorefreshTimer invalidate];
	[self loadAdWithURL:nil];
}

- (void)loadAdWithURL:(NSURL *)URL
{
	if (_isLoading) 
	{
		MPLogWarn(@"Ad view (%p) already loading an ad. Wait for previous load to finish.", self);
		return;
	}
	
	self.URL = (URL) ? URL : [self serverRequestUrl];
	MPLogDebug(@"Ad view (%p) loading ad with MoPub server URL: %@", self, self.URL);
	
	NSURLRequest *request = [self serverRequestObjectForUrl:self.URL];
	[_conn release];
	_conn = [[NSURLConnection connectionWithRequest:request delegate:self] retain];
	_isLoading = YES;
	
	MPLogInfo(@"Ad view (%p) fired initial ad request.", self);
}

- (NSURL *)serverRequestUrl
{
	NSString *urlString = [NSString stringWithFormat:@"http://%@/m/ad?v=5&udid=%@&q=%@&id=%@", 
						   HOSTNAME,
						   [[UIDevice currentDevice] hashedMoPubUDID],
						   [self.keywords stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
						   [self.adUnitId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
						   ];
	
	urlString = [urlString stringByAppendingString:[self orientationQueryStringComponent]];
	urlString = [urlString stringByAppendingString:[self scaleFactorQueryStringComponent]];
	urlString = [urlString stringByAppendingString:[self timeZoneQueryStringComponent]];
	urlString = [urlString stringByAppendingString:[self locationQueryStringComponent]];
	
	return [NSURL URLWithString:urlString];
}

- (NSString *)orientationQueryStringComponent
{
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	NSString *orientString = UIInterfaceOrientationIsPortrait(orientation) ?
		kMoPubInterfaceOrientationPortraitId : kMoPubInterfaceOrientationLandscapeId;
	return [NSString stringWithFormat:@"&o=%@", orientString];
}
													
- (NSString *)scaleFactorQueryStringComponent
{
	return [NSString stringWithFormat:@"&sc=%.1f", MPDeviceScaleFactor()];
}

- (NSString *)timeZoneQueryStringComponent
{
	static NSDateFormatter *formatter;
	@synchronized(self)
	{
		if (!formatter) formatter = [[NSDateFormatter alloc] init];
	}
	[formatter setDateFormat:@"Z"];
	NSDate *today = [NSDate date];
	return [NSString stringWithFormat:@"&z=%@", [formatter stringFromDate:today]];
}

- (NSString *)locationQueryStringComponent
{
	NSString *result = @"";
	if (self.location)
	{
		result = [result stringByAppendingFormat:
				  @"&ll=%f,%f",
				  self.location.coordinate.latitude,
				  self.location.coordinate.longitude];
	}
	return result;
}

- (NSURLRequest *)serverRequestObjectForUrl:(NSURL *)url
{
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] 
									 initWithURL:url
									 cachePolicy:NSURLRequestUseProtocolCachePolicy 
									 timeoutInterval:kMoPubRequestTimeoutInterval] autorelease];
	
	// Set the user agent so that we know where the request is coming from (for targeting).
	if ([request respondsToSelector:@selector(setValue:forHTTPHeaderField:)]) 
	{
		[request setValue:userAgentString forHTTPHeaderField:@"User-Agent"];
	}			
	
	return request;
}

- (void)didCloseAd:(id)sender
{
	if ([_adContentView isKindOfClass:[UIWebView class]])
		[(UIWebView *)_adContentView stringByEvaluatingJavaScriptFromString:@"webviewDidClose();"];
	
	if ([self.delegate respondsToSelector:@selector(adViewShouldClose:)])
		[self.delegate adViewShouldClose:self];
}

- (void)adViewDidAppear
{
	if ([_adContentView isKindOfClass:[UIWebView class]])
		[(UIWebView *)_adContentView stringByEvaluatingJavaScriptFromString:@"webviewDidAppear();"];
}

# pragma mark -
# pragma mark Custom Events

- (void)customEventDidLoadAd
{
	_isLoading = NO;
	[self trackImpression];
}

- (void)customEventDidFailToLoadAd
{
	_isLoading = NO;
	[self loadAdWithURL:self.failURL];
}

# pragma mark -
# pragma mark NSURLConnection delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response 
{
	// If the response is anything but a 200 (OK) or 300 (redirect), consider it a failure and bail.
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
			NSError *statusError = [NSError errorWithDomain:kErrorDomain
													   code:statusCode
												   userInfo:errorInfo];
			[self connection:connection didFailWithError:statusError];
			return;
		}
	}
	
	MPLogInfo(@"Ad view (%p) received valid response from MoPub server.", self);
	
	// Initialize data.
	[_data setLength:0];
	
	if ([self.delegate respondsToSelector:@selector(adView:didReceiveResponseParams:)])
		[self.delegate adView:self didReceiveResponseParams:[(NSHTTPURLResponse*)response allHeaderFields]];
	
	// Parse response headers, set relevant URLs and booleans.
	NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
	NSString *urlString = nil;
	
	urlString = [headers objectForKey:kClickthroughHeaderKey];
	self.clickURL = urlString ? [NSURL URLWithString:urlString] : nil;
	
	urlString = [headers objectForKey:kLaunchpageHeaderKey];
	self.interceptURL = urlString ? [NSURL URLWithString:urlString] : nil;
	
	urlString = [headers objectForKey:kFailUrlHeaderKey];
	self.failURL = urlString ? [NSURL URLWithString:urlString] : nil;
	
	urlString = [headers objectForKey:kImpressionTrackerHeaderKey];
	self.impTrackerURL = urlString ? [NSURL URLWithString:urlString] : nil;
	
	NSString *shouldInterceptLinksString = [headers objectForKey:kInterceptLinksHeaderKey];
	if (shouldInterceptLinksString)
		self.shouldInterceptLinks = [shouldInterceptLinksString boolValue];
	
	NSString *scrollableString = [headers objectForKey:kScrollableHeaderKey];
	if (scrollableString)
		self.scrollable = [scrollableString boolValue];
	
	NSString *widthString = [headers objectForKey:kWidthHeaderKey];
	NSString *heightString = [headers objectForKey:kHeightHeaderKey];
	
	// Try to get the creative size from the server or otherwise use the original container's size.
	if (widthString && heightString)
		self.creativeSize = CGSizeMake([widthString floatValue], [heightString floatValue]);
	else
		self.creativeSize = _originalSize;
	
	// Create the autorefresh timer, which will be scheduled either when the ad appears,
	// or if it fails to load.
	NSString *refreshString = [headers objectForKey:kRefreshTimeHeaderKey];
	if (refreshString && !self.ignoresAutorefresh)
	{
		NSTimeInterval interval = [refreshString doubleValue];
		interval = (interval >= MINIMUM_REFRESH_INTERVAL) ? interval : MINIMUM_REFRESH_INTERVAL;
		self.autorefreshTimer = [MPTimer timerWithTimeInterval:interval
														target:_timerTarget 
													  selector:@selector(postNotification) 
													  userInfo:nil 
													   repeats:NO];
	}
	
	NSString *animationString = [headers objectForKey:kAnimationHeaderKey];
	if (animationString)
		_animationType = [animationString intValue];
	
	// Log if the ad is from an ad network
	NSString *networkTypeHeader = [[(NSHTTPURLResponse *)response allHeaderFields] 
								   objectForKey:kNetworkTypeHeaderKey];
	if (networkTypeHeader && ![networkTypeHeader isEqualToString:@""])
	{
		MPLogInfo(@"Fetching Ad Network Type: %@",networkTypeHeader);
	}
	
	// Determine ad type.
	NSString *typeHeader = [[(NSHTTPURLResponse *)response allHeaderFields] 
								objectForKey:kAdTypeHeaderKey];
		
	if (!typeHeader || [typeHeader isEqualToString:kAdTypeHtml])
	{
		[self replaceCurrentAdapterWithAdapter:nil];
		
		// HTML ad, so just return. connectionDidFinishLoading: will take care of the rest.
		return;
	}
	else if ([typeHeader isEqualToString:kAdTypeClear])
	{
		[self replaceCurrentAdapterWithAdapter:nil];
		
		// Show a blank.
		MPLogInfo(@"*** CLEAR ***");
		[connection cancel];
		_isLoading = NO;
		[self backFillWithNothing];
		[self scheduleAutorefreshTimer];
		return;
	}
	
	// Obtain adapter for specified ad type.
	NSString *classString = [[MPAdapterMap sharedAdapterMap] classStringForAdapterType:typeHeader];
	Class cls = NSClassFromString(classString);
	if (cls != nil)
	{
		MPBaseAdapter *newAdapter = (MPBaseAdapter *)[[cls alloc] initWithAdView:self];
		[self replaceCurrentAdapterWithAdapter:newAdapter];
		
		[connection cancel];
		
		// Tell adapter to fire off ad request.
		NSDictionary *params = [(NSHTTPURLResponse *)response allHeaderFields];
		[_currentAdapter getAdWithParams:params];
	}
	// Else: no adapter for the specified ad type, so just fail over.
	else 
	{
		[self replaceCurrentAdapterWithAdapter:nil];
		
		[connection cancel];
		_isLoading = NO;
		
		[self loadAdWithURL:self.failURL];
	}
}

- (void)replaceCurrentAdapterWithAdapter:(MPBaseAdapter *)newAdapter
{
	// Dispose of the last adapter stored in _previousAdapter.
	[_previousAdapter unregisterDelegate];
	[_previousAdapter release];
	
	_previousAdapter = _currentAdapter;
	_currentAdapter = newAdapter;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d
{
	[_data appendData:d];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	MPLogError(@"Ad view (%p) failed to get a valid response from MoPub server. Error: %@", 
			   self, error);
	
	// If the initial request to MoPub fails, replace the current ad content with a blank.
	_isLoading = NO;
	[self backFillWithNothing];
	
	// Retry in 60 seconds.
	if (!self.autorefreshTimer || ![self.autorefreshTimer isValid])
	{
		self.autorefreshTimer = [MPTimer timerWithTimeInterval:kMoPubRequestRetryInterval 
														target:_timerTarget 
													  selector:@selector(postNotification) 
													  userInfo:nil 
													   repeats:NO];
	}
	
	[self scheduleAutorefreshTimer];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	// Generate a new webview to contain the HTML and add it to the webview pool.
	UIWebView *webview = [self makeAdWebViewWithFrame:(CGRect){{0, 0}, self.creativeSize}];
	webview.delegate = self;
	[_webviewPool addObject:webview];
	[webview loadData:_data MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:self.URL];
	
	// Print out the response, for debugging.
	if (MPLogGetLevel() <= MPLogLevelTrace)
	{
		NSString *response = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
		MPLogTrace(@"Ad view (%p) loaded HTML content: %@", self, response);
		[response release];
	}
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request 
 navigationType:(UIWebViewNavigationType)navigationType
{
	NSURL *URL = [request URL];
	
	// Handle the custom mopub:// scheme.
	if ([[URL scheme] isEqualToString:kMoPubUrlScheme])
	{
		NSString *host = [URL host];
		if ([host isEqualToString:kMoPubCloseHost])
		{
			[self didCloseAd:nil];
		}
		else if ([host isEqualToString:kMoPubFinishLoadHost])
		{
			_isLoading = NO;
			
			[self setAdContentView:webView];
			[self scheduleAutorefreshTimer];
			
			// Notify delegate that an ad has been loaded.
			if ([self.delegate respondsToSelector:@selector(adViewDidLoadAd:)]) 
				[self.delegate adViewDidLoadAd:self];
		}
		else if ([host isEqualToString:kMoPubFailLoadHost])
		{
			_isLoading = NO;
			
			// Deallocate this webview by removing it from the pool.
			webView.delegate = nil;
			[webView stopLoading];
			[_webviewPool removeObject:webView];
			
			// Start a new request using the fall-back URL.
			[self loadAdWithURL:self.failURL];
		}
		else if ([host isEqualToString:kMoPubInAppHost])
		{
			[self trackClick];
			NSDictionary *queryDict = [self dictionaryFromQueryString:[URL query]];
			[_store initiatePurchaseForProductIdentifier:[queryDict objectForKey:@"id"] 
												quantity:[[queryDict objectForKey:@"num"] intValue]];
		}
		else if ([host isEqualToString:kMoPubCustomHost]){
			[self trackClick];
			NSDictionary *queryDict = [self dictionaryFromQueryString:[URL query]];
			[self customLinkClickedForSelectorString:[queryDict objectForKey:@"fnc"]
									  withDataString:[queryDict objectForKey:@"data"]];
		}

		return NO;
	}
	
	// Intercept non-click forms of navigation (e.g. "window.location = ...") if the target URL
	// has the interceptURL prefix. Launch the ad browser.
	if (navigationType == UIWebViewNavigationTypeOther && 
		self.shouldInterceptLinks && 
		self.interceptURL &&
		[[URL absoluteString] hasPrefix:[self.interceptURL absoluteString]])
	{
		[self adLinkClicked:URL];
		return NO;
	}
	
	// Launch the ad browser for all clicks (if shouldInterceptLinks is YES).
	if (navigationType == UIWebViewNavigationTypeLinkClicked && self.shouldInterceptLinks)
	{
		[self adLinkClicked:URL];
		return NO;
	}
	
	// Other stuff (e.g. JavaScript) should load as usual.
	return YES;
}

#pragma mark -
#pragma mark MPAdBrowserControllerDelegate

- (void)dismissBrowserController:(MPAdBrowserController *)browserController{
	[self dismissBrowserController:browserController animated:YES];
}

- (void)dismissBrowserController:(MPAdBrowserController *)browserController animated:(BOOL)animated
{
	_adActionInProgress = NO;
	[[self.delegate viewControllerForPresentingModalView] dismissModalViewControllerAnimated:animated];
	
	if ([self.delegate respondsToSelector:@selector(didDismissModalViewForAd:)])
		[self.delegate didDismissModalViewForAd:self];
	
	if (_autorefreshTimerNeedsScheduling)
	{
		[self.autorefreshTimer scheduleNow];
		_autorefreshTimerNeedsScheduling = NO;
	}
	else if ([self.autorefreshTimer isScheduled])
		[self.autorefreshTimer resume];
}

#pragma mark -
#pragma mark MPAdapterDelegate

- (void)adapterDidFinishLoadingAd:(MPBaseAdapter *)adapter shouldTrackImpression:(BOOL)shouldTrack
{	
	_isLoading = NO;
	
	if (shouldTrack) [self trackImpression];
	[self scheduleAutorefreshTimer];
	
	if ([self.delegate respondsToSelector:@selector(adViewDidLoadAd:)])
		[self.delegate adViewDidLoadAd:self];
}

- (void)adapter:(MPBaseAdapter *)adapter didFailToLoadAdWithError:(NSError *)error
{
	// Ignore fail messages from the previous adapter.
	if (_previousAdapter && adapter == _previousAdapter) return;
	
	_isLoading = NO;
	MPLogError(@"Adapter (%p) failed to load ad. Error: %@", adapter, error);
	
	// Dispose of the current adapter, because we don't want it to try loading again.
	[_currentAdapter unregisterDelegate];
	[_currentAdapter release];
	_currentAdapter = nil;
	
	// An adapter will sometimes send this message during a user action (example: user taps on an 
	// iAd; iAd then does an internal refresh and fails). In this case, we schedule a new request
	// to occur after the action ends. Otherwise, just start a new request using the fall-back URL.
	if (_adActionInProgress) [self scheduleAutorefreshTimer];
	else [self loadAdWithURL:self.failURL];
}

- (void)userActionWillBeginForAdapter:(MPBaseAdapter *)adapter
{
	_adActionInProgress = YES;
	[self trackClick];
	
	if ([self.autorefreshTimer isScheduled])
		[self.autorefreshTimer pause];
	
	// Notify delegate that the ad will present a modal view / disrupt the app.
	if ([self.delegate respondsToSelector:@selector(willPresentModalViewForAd:)])
		[self.delegate willPresentModalViewForAd:self];
}

- (void)userActionDidEndForAdapter:(MPBaseAdapter *)adapter
{
	_adActionInProgress = NO;
	
	if (_autorefreshTimerNeedsScheduling)
	{
		[self.autorefreshTimer scheduleNow];
		_autorefreshTimerNeedsScheduling = NO;
	}
	else if ([self.autorefreshTimer isScheduled])
		[self.autorefreshTimer resume];
	
	// Notify delegate that the ad's modal view was dismissed, returning focus to the app.
	if ([self.delegate respondsToSelector:@selector(didDismissModalViewForAd:)])
		[self.delegate didDismissModalViewForAd:self];
}

- (void)userWillLeaveApplicationFromAdapter:(MPBaseAdapter *)adapter
{
	// TODO: Implement.
}

#pragma mark -
#pragma mark Internal

- (void)scheduleAutorefreshTimer
{
	if (_adActionInProgress)
	{
		MPLogDebug(@"Ad action in progress: MPTimer will be scheduled after action ends.");
		_autorefreshTimerNeedsScheduling = YES;
	}
	else if ([self.autorefreshTimer isScheduled])
	{
		MPLogDebug(@"Tried to schedule the autorefresh timer, but it was already scheduled.");
	}
	else if (self.autorefreshTimer == nil)
	{
		MPLogDebug(@"Tried to schedule the autorefresh timer, but it was nil.");
	}
	else
	{
		[self.autorefreshTimer scheduleNow];
	}
}

- (void)setScrollable:(BOOL)scrollable forView:(UIView *)view
{
	// For webviews, find all subviews that are UIScrollViews or subclasses
	// and set their scrolling and bounce.
	if ([view isKindOfClass:[UIWebView class]])
	{
		UIScrollView *scrollView = nil;
		for (UIView *v in view.subviews)
		{
			if ([v isKindOfClass:[UIScrollView class]])
			{
				scrollView = (UIScrollView *)v;
				scrollView.scrollEnabled = scrollable;
				scrollView.bounces = scrollable;
			}
		}
	}
	// For normal UIScrollView subclasses, use the provided setter.
	else if ([view isKindOfClass:[UIScrollView class]])
	{
		[(UIScrollView *)view setScrollEnabled:scrollable];
	}
}

- (UIWebView *)makeAdWebViewWithFrame:(CGRect)frame
{
	UIWebView *webView = [[UIWebView alloc] initWithFrame:frame];
	if (self.stretchesWebContentToFill)
		webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	webView.backgroundColor = [UIColor clearColor];
	webView.opaque = NO;
	return [webView autorelease];
}

- (void)adLinkClicked:(NSURL *)URL
{
	_adActionInProgress = YES;
	
	// Construct the URL that we want to load in the ad browser, using the click-tracking URL.
	NSString *redirectURLString = [[URL absoluteString] URLEncodedString];	
	NSURL *desiredURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&r=%@",
											  _clickURL,
											  redirectURLString]];
	
	// Notify delegate that the ad browser is about to open.
	if ([self.delegate respondsToSelector:@selector(willPresentModalViewForAd:)])
		[self.delegate willPresentModalViewForAd:self];
	
	if ([self.autorefreshTimer isScheduled])
		[self.autorefreshTimer pause];
	
	// Present ad browser.
	MPAdBrowserController *browserController = [[MPAdBrowserController alloc] initWithURL:desiredURL 
																				 delegate:self];
	[[self.delegate viewControllerForPresentingModalView] presentModalViewController:browserController 			
																			animated:YES];
	[browserController release];
}

- (void)backFillWithNothing
{
	// Make the ad view disappear.
	self.backgroundColor = [UIColor clearColor];
	self.hidden = YES;
	
	// Notify delegate that the ad has failed to load.
	if ([self.delegate respondsToSelector:@selector(adViewDidFailToLoadAd:)])
		[self.delegate adViewDidFailToLoadAd:self];
}

- (void)trackClick
{
	NSURLRequest *clickURLRequest = [NSURLRequest requestWithURL:self.clickURL];
	[NSURLConnection connectionWithRequest:clickURLRequest delegate:nil];
	MPLogDebug(@"Ad view (%p) tracking click %@", self, self.clickURL);
}

- (void)trackImpression
{
	NSURLRequest *impTrackerURLRequest = [NSURLRequest requestWithURL:self.impTrackerURL];
	[NSURLConnection connectionWithRequest:impTrackerURLRequest delegate:nil];
	MPLogDebug(@"Ad view (%p) tracking impression %@", self, self.impTrackerURL);
}

- (NSDictionary *)dictionaryFromQueryString:(NSString *)query
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

- (void)customLinkClickedForSelectorString:(NSString *)selectorString 
							withDataString:(NSString *)dataString
{
	if (!selectorString)
	{
		MPLogError(@"Custom selector requested, but no custom selector string was provided.",
				   selectorString);
	}
	
	SEL selector = NSSelectorFromString(selectorString);
	
	// First, try calling the no-object selector.
	if ([self.delegate respondsToSelector:selector])
	{
		[self.delegate performSelector:selector];
	}
	// Then, try calling the selector passing in the ad view.
	else 
	{
		NSString *selectorWithObjectString = [NSString stringWithFormat:@"%@:", selectorString];
		SEL selectorWithObject = NSSelectorFromString(selectorWithObjectString);
		
		if ([self.delegate respondsToSelector:selectorWithObject])
		{
			NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
			NSDictionary *dataDictionary = [[CJSONDeserializer deserializer] deserializeAsDictionary:data
																							   error:NULL];
			[self.delegate performSelector:selectorWithObject withObject:dataDictionary];
		}
		else
		{
			MPLogError(@"Ad view delegate does not implement custom selectors %@ or %@.",
					   selectorString,
					   selectorWithObjectString);
		}
	}
}

# pragma mark -
# pragma UIApplicationNotification responders

- (void)applicationDidEnterBackground
{
	[self.autorefreshTimer pause];
}

- (void)applicationWillEnterForeground
{
	_autorefreshTimerNeedsScheduling = NO;
	if (_ignoresAutorefresh == NO) [self forceRefreshAd];
}

@end

#pragma mark -
#pragma mark Categories

@implementation UIDevice (MPAdditions)

- (NSString *)hashedMoPubUDID 
{
	NSString *result = nil;
	NSString *udid = [NSString stringWithFormat:@"mopub-%@", 
					  [[UIDevice currentDevice] uniqueIdentifier]];
	
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

- (NSString *)URLEncodedString
{
	NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(
															NULL,
															(CFStringRef)self,
															NULL,
															(CFStringRef)@"!*'();:@&=+$,/?%#[]<>",
															kCFStringEncodingUTF8);
	return result;
}

@end

