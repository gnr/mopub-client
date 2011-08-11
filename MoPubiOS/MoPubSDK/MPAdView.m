//
//  MPAdView.m
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 MoPub, Inc. All rights reserved.
//

#import "MPAdView.h"
#import "MPAdManager+MPAdViewFriend.h"
#import <stdlib.h>
#import <time.h>

static NSString * const kAdAnimationId = @"MPAdTransition";

@interface MPAdView ()

@property (nonatomic, retain) MPAdManager *adManager;
@property (nonatomic, retain) UIView *adContentView;
@property (nonatomic, assign) CGSize originalSize;

- (void)setScrollable:(BOOL)scrollable forView:(UIView *)view;
- (void)animateTransitionToAdView:(UIView *)view;
- (void)backFillWithNothing;
- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished 
				 context:(void *)context;

@end

@implementation MPAdView
@synthesize location = _location;
@synthesize adManager = _adManager;
@synthesize adUnitId = _adUnitId;
@synthesize keywords = _keywords;
@synthesize delegate = _delegate;
@synthesize adContentView = _adContentView;
@synthesize creativeSize = _creativeSize;
@synthesize originalSize = _originalSize;
@synthesize scrollable = _scrollable;
@synthesize stretchesWebContentToFill = _stretchesWebContentToFill;
@synthesize animationType = _animationType;

#pragma mark -
#pragma mark Lifecycle

+ (void)initialize
{
	srandom(time(NULL));
}

- (id)initWithAdUnitId:(NSString *)adUnitId size:(CGSize)size 
{   
	CGRect f = (CGRect){{0, 0}, size};
    if (self = [super initWithFrame:f]) 
	{	
		self.backgroundColor = [UIColor clearColor];
		self.clipsToBounds = YES;
		_scrollable = NO;
		_animationType = MPAdAnimationTypeNone;
		_originalSize = size;
		_adManager = [[MPAdManager alloc] initWithAdView:self];
		_adManager.adUnitId = _adUnitId = (adUnitId) ? [adUnitId copy] : DEFAULT_PUB_ID;
		_allowedNativeAdOrientation = MPNativeAdOrientationAny;
    }
    return self;
}

- (void)dealloc 
{
	_delegate = nil;
	[_adUnitId release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];	
	
	// If our content has a delegate, set its delegate to nil.
	if ([_adContentView respondsToSelector:@selector(setDelegate:)])
		[_adContentView performSelector:@selector(setDelegate:) withObject:nil];
	[_adContentView release];
	
	_adManager.adView = nil;
	[_adManager release];
	[_location release];
    [super dealloc];
}

#pragma mark -

- (void)setAdUnitId:(NSString *)adUnitId {
	if (_adUnitId != adUnitId) {
		[_adUnitId release];
		_adUnitId = [adUnitId copy];
	}
	_adManager.adUnitId = _adUnitId;
}

- (NSString *)keywords {
	return _adManager.keywords;
}

- (void)setKeywords:(NSString *)keywords {
	_adManager.keywords = keywords; 
}

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

- (void)animateTransitionToAdView:(UIView *)view
{
	MPAdAnimationType type = (_animationType == MPAdAnimationTypeRandom) ? 
		(random() % (MPAdAnimationTypeCount - 2)) + 2 : _animationType;
	
	// Special case: if there's currently no ad content view, certain transitions will
	// look strange (e.g. CurlUp / CurlDown). We'll just omit the transition.
	if (!_adContentView) type = MPAdAnimationTypeNone;
    if (type == MPAdAnimationTypeNone) {
        [self addSubview:view];
        [self animationDidStop:kAdAnimationId finished:[NSNumber numberWithBool:YES] context:view];
        return;
    } 
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
				UIWebView *webView = (UIWebView *)_adContentView;
				[webView setDelegate:nil];
				[webView stopLoading];
				[_adManager removeWebviewFromPool:webView];
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

- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation
{
	[_adManager rotateToOrientation:newOrientation];
}

- (void)loadAd
{
	[_adManager loadAdWithURL:nil];
}

- (void)refreshAd
{
	[_adManager refreshAd];
}

- (void)forceRefreshAd
{
	[_adManager forceRefreshAd];
}

- (void)loadAdWithURL:(NSURL *)URL
{
	[_adManager loadAdWithURL:URL];
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

- (void)lockNativeAdsToOrientation:(MPNativeAdOrientation)orientation
{
	_allowedNativeAdOrientation = orientation;
}

- (void)unlockNativeAdsOrientation
{
	_allowedNativeAdOrientation = MPNativeAdOrientationAny;
}

- (MPNativeAdOrientation)allowedNativeAdsOrientation
{
	return _allowedNativeAdOrientation;
}

<<<<<<< HEAD
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
		MPLogWarn(@"Couldn't find the native ad adapter named %@. Have you forgotten to add"
				  @" %@.h/.m to your project?", classString, classString);
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
	if (self.autorefreshTimer == nil || ![self.autorefreshTimer isValid])
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

- (void)dismissBrowserController:(MPAdBrowserController *)browserController {
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

=======
>>>>>>> 298b4e259b9fa0396d22c790319bf325f51dcb80
- (void)backFillWithNothing
{
	// Make the ad view disappear.
	self.backgroundColor = [UIColor clearColor];
	self.hidden = YES;
	
	// Notify delegate that the ad has failed to load.
	if ([self.delegate respondsToSelector:@selector(adViewDidFailToLoadAd:)])
		[self.delegate adViewDidFailToLoadAd:self];
}

# pragma mark -
# pragma mark Custom Events

- (void)customEventDidLoadAd
{
	[_adManager customEventDidLoadAd];

}

- (void)customEventDidFailToLoadAd
{
	[_adManager customEventDidFailToLoadAd];
}

@end
