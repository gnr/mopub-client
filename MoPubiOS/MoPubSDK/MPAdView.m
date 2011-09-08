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

#define kDefaultLocationPrecision 6

static NSString * const kAdAnimationId = @"MPAdTransition";

@interface MPAdView ()

@property (nonatomic, retain) MPAdManager *adManager;
@property (nonatomic, retain) UIView *adContentView;
@property (nonatomic, assign) CGSize originalSize;
@property (nonatomic, retain) NSArray *locationDescriptionPair;

- (void)updateLocationDescriptionPair;
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
@synthesize keywords;
@synthesize delegate = _delegate;
@synthesize adContentView = _adContentView;
@synthesize creativeSize = _creativeSize;
@synthesize originalSize = _originalSize;
@synthesize scrollable = _scrollable;
@synthesize locationEnabled = _locationEnabled;
@synthesize	locationPrecision = _locationPrecision;
@synthesize locationDescriptionPair = _locationDescriptionPair;
@synthesize animationType = _animationType;
@synthesize ignoresAutorefresh = _ignoresAutorefresh;

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
		_locationEnabled = YES;
		_locationPrecision = kDefaultLocationPrecision;
		_animationType = MPAdAnimationTypeNone;
		_originalSize = size;
		_allowedNativeAdOrientation = MPNativeAdOrientationAny;
		_adUnitId = (adUnitId) ? [adUnitId copy] : DEFAULT_PUB_ID;
		_adManager = [[MPAdManager alloc] initWithAdView:self];
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
	[_locationDescriptionPair release];
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

- (void)setKeywords:(NSString *)words {
	_adManager.keywords = words; 
}

- (void)setLocation:(CLLocation *)location {
	if (_location != location) {
		[_location release];
		_location = [location copy];
		[self updateLocationDescriptionPair];
	}
}

- (void)setLocationEnabled:(BOOL)enabled {
	_locationEnabled = enabled;
	[self updateLocationDescriptionPair];
}

- (void)setLocationPrecision:(NSUInteger)precision {
	_locationPrecision = precision;
	[self updateLocationDescriptionPair];
}

- (void)updateLocationDescriptionPair {
	static NSNumberFormatter *formatter = nil;
	
	if (!self.location || !self.locationEnabled) {
		self.locationDescriptionPair = nil;
		return;
	}
	
	float lat = self.location.coordinate.latitude;
	float lon = self.location.coordinate.longitude;
	
	if (!formatter) { formatter = [[NSNumberFormatter alloc] init]; }
	[formatter setMaximumFractionDigits:self.locationPrecision];
	self.locationDescriptionPair = [NSArray arrayWithObjects:
			[formatter stringFromNumber:[NSNumber numberWithFloat:lat]],
			[formatter stringFromNumber:[NSNumber numberWithFloat:lon]],
			nil];
}

- (NSArray *)locationDescriptionPair {
	return _locationDescriptionPair;
}

- (void)setIgnoresAutorefresh:(BOOL)ignoresAutorefresh {
	_ignoresAutorefresh = ignoresAutorefresh;
	_adManager.ignoresAutorefresh = ignoresAutorefresh;
}

- (void)setAdContentView:(UIView *)view
{
	if (!view) return;
	[view retain];
	
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

- (void)customEventActionWillBegin 
{
    [_adManager customEventActionWillBegin];
}

- (void)customEventActionDidEnd
{
    [_adManager customEventActionDidEnd];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MPInterstitialAdView

- (id)initWithAdUnitId:(NSString *)adUnitId size:(CGSize)size 
{   
    if (self = [super initWithAdUnitId:adUnitId size:size]) 
	{
		_adManager = [[MPInterstitialAdManager alloc] initWithAdView:self];
    }
    return self;
}

- (void)setAdContentView:(UIView *)view
{
	if (!view) return;
	[view retain];
	
	if ([view isKindOfClass:[UIWebView class]])
	{
		// Avoids a race condition: 
		// 1) a webview is initialized with the ad view's bounds
		// 2) ad view resizes its frame before the webview gets set as the content view
		view.frame = self.bounds;
	}
	
	self.hidden = NO;
	
	// We don't necessarily know where this view came from, so make sure its scrollability
	// corresponds to our value of self.scrollable.
	[self setScrollable:self.scrollable forView:view];
	
	[self animateTransitionToAdView:view];
}

@end
