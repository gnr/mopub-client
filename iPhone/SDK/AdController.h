//
//  AdController.h
//  Copyright (c) 2010 MoPub Inc.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "AdClickController.h"

#define HOSTNAME @"ads.mopub.com"

@class AdClickController;
@class MoPubNativeSDKAdapter;

@protocol AdControllerDelegate;

@interface AdController : UIViewController <UIWebViewDelegate, AdClickControllerDelegate> {
	id<AdControllerDelegate> delegate; 
	BOOL loaded;
	BOOL adLoading;
	
	UIViewController *parent;
	CGSize size;
	NSString *adUnitId;

	NSString *keywords;
	CLLocation *location;
		
	// boolean flag to let us know if the ad will be shown as an interstitial
	BOOL _isInterstitial;
	
	BOOL interceptLinks;
	BOOL scrollable;
	
@private
	// UI elements
	UIActivityIndicatorView *loadingIndicator;	
	UIWebView *_webView;
	
	// Data to hold the web request
	NSURL *url;
	NSMutableData * data;
	
	// Native Ad Fail url
	NSURL *failURL;

	// native Ad View
	UIView *nativeAdView; 
	UIViewController *nativeAdViewController;
	
	// store the click-through URL which is encoded for tracking purposes
	NSString *clickURL;
	
	// store the click host for other ad networks c.admob.com, c.google.com, c.quattro.com, from teh header
	NSString *newPageURLString;
	
	// array of strings of parameters to include the the ad request ?exclude=iAd...
	NSMutableArray *excludeParams;
	
	MoPubNativeSDKAdapter *currentAdapter;
	MoPubNativeSDKAdapter *lastAdapter;
	
}
@property(nonatomic, assign) id <AdControllerDelegate> delegate;
@property(nonatomic, assign) BOOL loaded;

@property(nonatomic, retain) UIViewController* parent;
@property(nonatomic, assign) CGSize size;
@property(nonatomic, copy) NSString* adUnitId;

@property(nonatomic, copy) NSString* keywords;
@property(nonatomic, retain) CLLocation* location;

@property(nonatomic, retain) UIActivityIndicatorView* loadingIndicator;
@property(nonatomic, retain) UIWebView* webView;

@property(nonatomic, copy) NSURL* url;
@property(nonatomic, retain) NSMutableData* data;

@property(nonatomic, copy) NSURL* failURL;

@property(nonatomic, retain) UIView* nativeAdView; 
@property(nonatomic, retain) UIViewController* nativeAdViewController; 


@property(nonatomic, copy) NSString* clickURL;
@property(nonatomic, copy) NSString* newPageURLString;

@property (nonatomic, retain) MoPubNativeSDKAdapter *currentAdapter;
@property (nonatomic, retain) MoPubNativeSDKAdapter *lastAdapter;

@property (nonatomic, readonly) NSString *currentAdType;

@property (nonatomic, assign) BOOL interceptLinks;
@property (nonatomic, assign) BOOL scrollable;

- (id)initWithSize:(CGSize)size adUnitId:(NSString*)publisherId parentViewController:(UIViewController*)parent;


/**
 * Call this method whenever you would like to load the ad
 * should often be called in a background thread
 */
- (void)loadAd;
/**
 * Call this method whenever you would like to refresh
 * the current ad on the screen
 */
- (void)refresh;

/**
 * Call this method whenever the application closes (maybe after a loading up content, etc)
 * the current ad on the screen (mopub will track time on screen,etc)
 */
- (void)closeAd;

/**
 * Informs the webview that the application would like to dismiss the add
 */

- (void)didSelectClose:(id)sender;

/**
 * Informs the ad unit that the device orientation has changed
 */
- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation;

- (void)nativeAdTrackAdClick;
- (void)nativeAdTrackAdClickWithURL:(NSString *)adClickURL;
- (void)nativeAdLoadSucceededWithResults:(NSDictionary *)results;
- (void)nativeAdLoadFailedwithError:(NSError *)error;


@end

@protocol AdControllerDelegate <NSObject>
@optional
/**
 * Called when the ad controller is about to load a new ad creative
 */
-(void)adControllerWillLoadAd:(AdController*)adController;

/**
 * Called when the ad creative has been loaded.
 */
-(void)adControllerDidLoadAd:(AdController*)adController;

/**
 * Called when the ad creative has failed to load.
 */
-(void)adControllerFailedLoadAd:(AdController*)adController;

/**
 * Called when the ad has been clicked and the ad landing page is about to open.
 */
- (void)adControllerAdWillOpen:(AdController*)adController;

/*
 * Called when the ad requested to be close.
 */
- (void)didSelectClose:(id)sender;

/*
 * Called when the ad has been clicked an a full screen webview will be presented
 */
- (void)willPresentModalViewForAd:(AdController*)adController;

/*
 * Called when the full screen webview has been presented
 */
- (void)didPresentModalViewForAd:(AdController*)adController;

/*
 * Called just before dismissing a full screen view.
 */

- (void)willDismissModalViewForAd:(AdController*)adController;

/*
 * Called just after dismissing a full screen view.
 */
- (void)didDismissModalViewForAd:(AdController*)adController;

/*
 * Responds to notification UIApplicationWillResignActiveNotification
 */
- (void)applicationWillResign:(id)sender;






@end

