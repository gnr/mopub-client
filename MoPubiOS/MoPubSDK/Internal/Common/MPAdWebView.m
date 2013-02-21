//
//  MPAdWebView.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPAdWebView.h"

#import "MPAdConfiguration.h"
#import "MPGlobal.h"
#import "MPLogging.h"
#import "MPStore.h"
#import "UIWebView+MPAdditions.h"

#import "CJSONDeserializer.h"

NSString * const kMoPubURLScheme = @"mopub";
NSString * const kMoPubCloseHost = @"close";
NSString * const kMoPubFinishLoadHost = @"finishLoad";
NSString * const kMoPubFailLoadHost = @"failLoad";
NSString * const kMoPubInAppPurchaseHost = @"inapp";
NSString * const kMoPubCustomHost = @"custom";

@interface MPAdWebView ()

@property (nonatomic, retain) MPAdConfiguration *configuration;
@property (nonatomic, readwrite, retain) UIWebView *webView;
@property (nonatomic, readwrite, retain) MPAdBrowserController *browserController;

- (void)showLoadingIndicatorAnimated:(BOOL)animated;
- (void)hideLoadingIndicatorAnimated:(BOOL)animated;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MPAdWebView

@synthesize configuration = _configuration;
@synthesize webView = _webView;
@synthesize delegate = _delegate;
@synthesize customMethodDelegate = _customMethodDelegate;
@synthesize browserController = _browserController;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
    
        CGRect webViewFrame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        _webView = [[UIWebView alloc] initWithFrame:webViewFrame];
        _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _webView.backgroundColor = [UIColor clearColor];
        _webView.delegate = self;
        _webView.opaque = NO;
        
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= MP_IOS_4_0
        if ([_webView respondsToSelector:@selector(allowsInlineMediaPlayback)]) {
            [_webView setAllowsInlineMediaPlayback:YES];
            [_webView setMediaPlaybackRequiresUserAction:NO];
        }
#endif
        
        [self addSubview:_webView];
    }
    return self;
}

- (void)dealloc
{
    [self hideLoadingIndicatorAnimated:NO];
    
    [_configuration release];
    
    _webView.delegate = nil;
    [_webView removeFromSuperview];
    [_webView release];
    
    [_browserController release];
    
    [super dealloc];
}

#pragma mark - Public

- (void)loadConfiguration:(MPAdConfiguration *)configuration
{
    self.configuration = configuration;
    
    if ([configuration hasPreferredSize]) {
        [self setFrameFromConfiguration:configuration];
    }
    
    [_webView mp_setScrollable:configuration.scrollable];
    [self loadData:configuration.adResponseData MIMEType:@"text/html" textEncodingName:@"utf-8"
           baseURL:nil];
}

- (void)loadURL:(NSURL *)URL
{
    NSURLRequest *request = [NSURLRequest requestWithURL:URL
                                             cachePolicy:NSURLRequestReloadIgnoringCacheData
                                         timeoutInterval:10.0];
    [_webView loadRequest:request];
}

- (void)loadData:(NSData *)data MIMEType:(NSString *)MIMEType
textEncodingName:(NSString *)textEncodingName baseURL:(NSURL *)baseURL
{
    [_webView loadData:data MIMEType:MIMEType textEncodingName:textEncodingName baseURL:baseURL];
}

- (void)invokeJavaScriptForEvent:(MPAdWebViewEvent)event
{
    switch (event) {
        case MPAdWebViewEventAdDidAppear:
            [_webView stringByEvaluatingJavaScriptFromString:@"webviewDidAppear();"];
            break;
        case MPAdWebViewEventAdDidDisappear:
            [_webView stringByEvaluatingJavaScriptFromString:@"webviewDidClose();"];
            break;
        default:
            break;
    }
}

#pragma mark - Internal

- (void)setFrameFromConfiguration:(MPAdConfiguration *)configuration
{
    if (configuration.preferredSize.width <= 0 || configuration.preferredSize.height <= 0) {
        return;
    }
    
    CGRect frame = self.frame;
    frame.size.width = configuration.preferredSize.width;
    frame.size.height = configuration.preferredSize.height;
    self.frame = frame;
}

- (BOOL)shouldPerformClickNavigationInline
{
    return !(self.configuration.shouldInterceptLinks);
}

- (NSString *)clickDetectionURLPrefix
{
    if ([self.configuration.interceptURLPrefix absoluteString]) {
        return [self.configuration.interceptURLPrefix absoluteString];
    } else {
        return @"";
    }
}

- (NSString *)clickTrackingURL
{
    return [self.configuration.clickTrackingURL absoluteString];
}

#pragma mark - Rotation

- (void)rotateToOrientation:(UIInterfaceOrientation)orientation
{
    [self forceRedraw];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType
{
    if (self.isDismissed) {
        return NO;
    }
    
    NSURL *URL = [request URL];
    
    if ([[URL scheme] isEqualToString:kMoPubURLScheme]) {
        [self performActionForMoPubSpecificURL:URL];
        return NO;
    } else if ([self shouldShowClickBrowserForURL:URL navigationType:navigationType]) {
        [self showClickBrowserForURL:URL];
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - MoPub-specific URL handlers

- (void)performActionForMoPubSpecificURL:(NSURL *)URL
{
    MPLogDebug(@"MPAdWebView - loading MoPub URL: %@", URL);
    NSString *host = [URL host];
    
    if ([host isEqualToString:kMoPubCloseHost] &&
        [self.delegate respondsToSelector:@selector(adDidClose:)]) {
        [self.delegate adDidClose:self];
    } else if ([host isEqualToString:kMoPubFinishLoadHost] &&
               [self.delegate respondsToSelector:@selector(adDidFinishLoadingAd:)]) {
        [self.delegate adDidFinishLoadingAd:self];
    } else if ([host isEqualToString:kMoPubFailLoadHost] &&
               [self.delegate respondsToSelector:@selector(adDidFailToLoadAd:)]) {
        [self.delegate adDidFailToLoadAd:self];
    } else if ([host isEqualToString:kMoPubInAppPurchaseHost]) {
        [self initiatePurchaseForURL:URL];
    } else if ([host isEqualToString:kMoPubCustomHost]) {
        [self handleMoPubCustomURL:URL];
    } else {
        MPLogWarn(@"MPAdWebView - unsupported MoPub URL: %@", [URL absoluteString]);
    }
}

- (void)handleMoPubCustomURL:(NSURL *)URL
{
    NSDictionary *queryParameters = [self dictionaryFromQueryString:[URL query]];
    NSString *selectorName = [queryParameters objectForKey:@"fnc"];
    NSString *dataString = [queryParameters objectForKey:@"data"];
    
    CJSONDeserializer *deserializer = [CJSONDeserializer deserializerWithNullObject:NULL];
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error;
    NSDictionary *dataDictionary = [deserializer deserializeAsDictionary:data error:&error];
    
    NSString *oneArgumentSelectorName = [selectorName stringByAppendingString:@":"];
    SEL oneArgumentSelector = NSSelectorFromString(oneArgumentSelectorName);
    SEL zeroArgumentSelector = NSSelectorFromString(selectorName);
    
    if ([self.customMethodDelegate respondsToSelector:zeroArgumentSelector]) {
        [self.customMethodDelegate performSelector:zeroArgumentSelector];
    } else if ([self.customMethodDelegate respondsToSelector:oneArgumentSelector]) {
        [self.customMethodDelegate performSelector:oneArgumentSelector withObject:dataDictionary];
    } else {
        MPLogError(@"Custom method delegate does not implement custom selectors %@ or %@.",
                   selectorName, oneArgumentSelectorName);
    }
}

- (void)initiatePurchaseForURL:(NSURL *)URL
{
    NSDictionary *queryParameters = [self dictionaryFromQueryString:[URL query]];
    NSString *productIdentifier = [queryParameters objectForKey:@"id"];
    NSInteger quantity = [[queryParameters objectForKey:@"num"] integerValue];
    [[MPStore sharedStore] initiatePurchaseForProductIdentifier:productIdentifier
                                                       quantity:quantity];
}

- (BOOL)shouldShowClickBrowserForURL:(NSURL *)URL
                      navigationType:(UIWebViewNavigationType)navigationType
{
    if ([self shouldPerformClickNavigationInline]) {
        return NO;
    } else if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        return YES;
    } else if (navigationType == UIWebViewNavigationTypeOther) {
        return [[URL absoluteString] hasPrefix:[self clickDetectionURLPrefix]];
    } else {
        return NO;
    }
}

- (void)showClickBrowserForURL:(NSURL *)URL
{
    NSString *encodedURLString = [[URL absoluteString] URLEncodedString];
    NSURL *redirectedURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&r=%@",
                                                 self.clickTrackingURL,
                                                 encodedURLString]];
    
    if ([self.delegate respondsToSelector:@selector(adActionWillBegin:)]) {
        [self.delegate adActionWillBegin:self];
    }
    
    [self.browserController stopLoading];
    self.browserController = [[[MPAdBrowserController alloc] initWithURL:redirectedURL
                                                                delegate:self] autorelease];
    self.browserController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self.browserController startLoading];
    
    [self showLoadingIndicatorAnimated:YES];
}

#pragma mark - MPAdBrowserControllerDelegate

- (void)dismissBrowserController:(MPAdBrowserController *)browserController
{
    [self dismissBrowserController:browserController animated:YES];
}

- (void)dismissBrowserController:(MPAdBrowserController *)browserController animated:(BOOL)animated
{
    UIViewController *presenter = [self.delegate viewControllerForPresentingModalView];
    [presenter dismissModalViewControllerAnimated:animated];
    
    if ([self.delegate respondsToSelector:@selector(adActionDidFinish:)]) {
        [self.delegate adActionDidFinish:self];
    }
}

- (void)browserControllerDidFinishLoad:(MPAdBrowserController *)browserController
{
    if ([self isBrowserControllerAlreadyPresented]) {
        return;
    }
    
    [self hideLoadingIndicatorAnimated:YES];
    
    // TODO: Nil view controller edge case.
    [[self.delegate viewControllerForPresentingModalView]
     presentModalViewController:self.browserController animated:YES];
}

- (void)browserControllerWillLeaveApplication:(MPAdBrowserController *)browserController
{
    [self hideLoadingIndicatorAnimated:NO];
    
    if ([self.delegate respondsToSelector:@selector(adActionWillLeaveApplication:)]) {
        [self.delegate adActionWillLeaveApplication:self];
    }
}

#pragma mark - Loading indicator

- (void)showLoadingIndicatorAnimated:(BOOL)animated
{
    [MPProgressOverlayView presentOverlayInWindow:self.window animated:animated delegate:self];
}

- (void)hideLoadingIndicatorAnimated:(BOOL)animated
{
    // XXX: When this view is used as the backing view for an interstitial, it is possible for
    // self.window to be nil if the interstitial has been dismissed.
    UIWindow *window = self.window ? self.window : MPKeyWindow();
    [MPProgressOverlayView dismissOverlayFromWindow:window animated:animated];
}

- (void)overlayCancelButtonPressed
{
    [self.browserController stopLoading];
    [self hideLoadingIndicatorAnimated:YES];
    if ([self.delegate respondsToSelector:@selector(adActionDidFinish:)]) {
        [self.delegate adActionDidFinish:self];
    }
}

#pragma mark - Utility

- (BOOL)isBrowserControllerAlreadyPresented
{
    UIViewController *presentingViewController = [self.delegate
                                                  viewControllerForPresentingModalView];
    UIViewController *presentedViewController = presentingViewController.modalViewController;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= MP_IOS_5_0
    if ([presentingViewController respondsToSelector:@selector(presentedViewController)]) {
        presentedViewController = presentingViewController.presentedViewController;
    }
#endif
    
    return (presentedViewController == self.browserController);
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

- (void)forceRedraw
{
	UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
	int angle = -1;
	switch (orientation)
	{
		case UIDeviceOrientationPortrait: angle = 0; break;
		case UIDeviceOrientationLandscapeLeft: angle = 90; break;
		case UIDeviceOrientationLandscapeRight: angle = -90; break;
		case UIDeviceOrientationPortraitUpsideDown: angle = 180; break;
		default: break;
	}
	
	if (angle == -1) return;
	
	// UIWebView doesn't seem to fire the 'orientationchange' event upon rotation, so we do it here.
	NSString *orientationEventScript = [NSString stringWithFormat:
                                        @"window.__defineGetter__('orientation',function(){return %d;});"
                                        @"(function(){ var evt = document.createEvent('Events');"
                                        @"evt.initEvent('orientationchange',true,true);window.dispatchEvent(evt);})();",
                                        angle];
	[_webView stringByEvaluatingJavaScriptFromString:orientationEventScript];
	
	// XXX: If the UIWebView is rotated off-screen (which may happen with interstitials), its
	// content may render off-center upon display. We compensate by setting the viewport meta tag's
	// 'width' attribute to be the size of the webview.
	NSString *viewportUpdateScript = [NSString stringWithFormat:
                                      @"document.querySelector('meta[name=viewport]')"
                                      @".setAttribute('content', 'width=%f;', false);",
                                      _webView.frame.size.width];
	[_webView stringByEvaluatingJavaScriptFromString:viewportUpdateScript];
}

@end
