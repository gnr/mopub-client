//
//  MPAdView.h
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MPAdBrowserController.h"
#import "MPBaseAdapter.h"
#import "MPStore.h"
#import "MPConstants.h"
#import "MPLogging.h"

@protocol MPAdViewDelegate;

@interface NSString (MPAdditions)

/* 
 * Returns string with reserved/unsafe characters encoded.
 */
- (NSString *)URLEncodedString;

@end

@interface UIDevice (MPAdditions)

/* 
 * Produces MD5 hash of a UDID.
 */
- (NSString *)hashedMoPubUDID;

@end

@interface MPAdView : UIView <UIWebViewDelegate, MPAdBrowserControllerDelegate, MPAdapterDelegate> 
{
	id<MPAdViewDelegate> _delegate;
	
	// Ad unit identifier for this ad view.
	NSString *_adUnitId;
	
	// Targeting parameters.
	NSString *_keywords;
	CLLocation *_location;
	
	// Subview that represents the actual ad content. Set via -setAdContentView.
	UIView *_adContentView;
	
	// Default webview used for HTML ads.
	UIWebView *_webView;
	
	// URL for initial MoPub ad request.
	NSURL *_URL;
	
	// Connection object for initial ad request.
	NSURLConnection *_conn;
	
	// Connection data object for ad request.
	NSMutableData *_data;
	
	// Current adapter being used for serving native ads.
	MPBaseAdapter *_adapter;
	
	// Click-tracking URL.
	NSURL *_clickURL;
	
	// We often need to intercept ad navigation that is not the result of a
	// click. This represents a URL prefix for links we'd like to intercept.
	NSURL *_interceptURL;
	
	// Fall-back URL if an ad request fails.
	NSURL *_failURL;
	
	// Impression-tracking URL.
	NSURL *_impTrackerURL;
	
	// Handle to the shared store object that manages in-app purchases from ads.
	MPStore *_store;
	
	// Whether we should intercept any sort of ad navigation.
	BOOL _shouldInterceptLinks;
	
	// Whether scrolling is enabled for the ad view.
	BOOL _scrollable;
	
	// Whether this ad view is currently loading an ad.
	BOOL _isLoading;
}

@property (nonatomic, assign) id<MPAdViewDelegate> delegate;
@property (nonatomic, copy) NSString *adUnitId;
@property (nonatomic, copy) NSString *keywords;
@property (nonatomic, retain) CLLocation *location;
@property (nonatomic, copy) NSURL *URL;

/*
 * Returns an MPAdView with the given ad unit ID.
 */
- (id)initWithAdUnitId:(NSString *)adUnitId size:(CGSize)size;

/* 
 * Ad sizes may vary between different ad networks. This method returns the actual
 * size of the underlying ad, which you can use to adjust the size of the MPAdView
 * to avoid clipping or border issues.
 */
- (CGSize)adContentViewSize;

/*
 * Loads a new ad using a default URL constructed from the ad unit ID.
 */
- (void)loadAd;

/*
 * Loads a new ad using the specified URL.
 */
- (void)loadAdWithURL:(NSURL *)URL;

/*
 * Request that the ad view get another ad using its current URL. Note that the 
 * resulting ad is not guaranteed to be the same ad currently being displayed.
 */
- (void)refreshAd;

/*
 * Replaces the content of the MPAdView with the specified view. This method is
 * crucial for implementing adapters or custom events.
 */
- (void)setAdContentView:(UIView *)view;

/*
 * Signals the internal webview that it has appeared on-screen.
 */
- (void)adViewDidAppear;

/* 
 * Informs the ad view that the device orientation has changed. You should call
 * this method when your application's orientation changes if you want your
 * underlying ads to adjust their orientation properly. You may want to use
 * this method in conjunction with -adContentViewSize, in case the orientation
 * change modifies the size of the underlying ad.
 */
- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation;

/*
 * Signals the internal webview that it has been closed. This will trigger
 * the -adViewShouldClose delegate callback, if it is implemented.
 */
- (void)didCloseAd:(id)sender;

/*
 * Signals to the ad view that a custom event has caused ad content to load
 * successfully. You must call this method if you implement custom events.
 */
- (void)customEventDidLoadAd;

/*
 * Signals to the ad view that a custom event has resulted in a failed load.
 * You must call this method if you implement custom events.
 */
- (void)customEventDidFailToLoadAd;

@end

@protocol MPAdViewDelegate <NSObject>

@required
/*
 * The ad view relies on this method to determine which view controller will be 
 * used for presenting/dismissing modal views (e.g. the ad browser presented 
 * when a user clicks on an ad).
 */
- (UIViewController *)viewControllerForPresentingModalView;

@optional
/*
 * These callbacks notify you regarding whether the ad view (un)successfully
 * loaded an ad.
 */
- (void)adViewDidFailToLoadAd:(MPAdView *)view;
- (void)adViewDidLoadAd:(MPAdView *)view;

/*
 * These callbacks are triggerd when the ad view is about to present/dismiss a
 * modal view. If your application may be disrupted by these actions, you can
 * use these notifications to handle them (for example, a game might need to
 * pause/unpause).
 */
- (void)willPresentModalViewForAd:(MPAdView *)view;
- (void)didDismissModalViewForAd:(MPAdView *)view;

/*
 * This callback is triggered when the ad view has retrieved ad parameters
 * (headers) from the MoPub server. See MPInterstitialAdController for an
 * example of how this should be used.
 */
- (void)adViewDidReceiveResponseParams:(NSDictionary *)params;

/*
 * This method is called when a mopub://close link is activated. If implemented, this method 
 * should remove the ad view from the screen (see MPInterstitialAdController for an example).
 */
- (void)adViewShouldClose:(MPAdView *)view;

@end

@interface MPAdView ()

@property (nonatomic, copy) NSURL *clickURL;
@property (nonatomic, copy) NSURL *interceptURL;
@property (nonatomic, copy) NSURL *failURL;
@property (nonatomic, copy) NSURL *impTrackerURL;
@property (nonatomic, assign) BOOL shouldInterceptLinks;
@property (nonatomic, assign) BOOL scrollable;

@end
