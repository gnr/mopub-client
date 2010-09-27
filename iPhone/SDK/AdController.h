//
//  AdController.h
//  SimpleAds
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <iAd/iAd.h>

//#define HOSTNAME @"32-campaigns-django-port.latest.mopub-inc.appspot.com"
// #define HOSTNAME @"32-campaigns.latest.mopub-inc.appspot.com"
 #define HOSTNAME @"localhost:8000"

enum {
	AdControllerFormat320x50,			// mobile banner size
	AdControllerFormat300x250,			// medium rectangle
	AdControllerFormat728x90,			// leaderboard
	AdControllerFormat468x60,			// full banner
	AdControllerFormatFullScreen,		// full-screen interstitial
};
typedef NSUInteger AdControllerFormat;

@class AdClickController;

@protocol AdControllerDelegate;

@interface AdController : UIViewController <UIWebViewDelegate, ADBannerViewDelegate> {
	id<AdControllerDelegate> delegate;
	BOOL loaded;
	BOOL adLoading;
	
	UIViewController *parent;
	AdControllerFormat format;
	NSString *publisherId;

	NSString *keywords;
	CLLocation *location;
	
	AdClickController *adClickController;
	
	// boolean flag to let us know if the ad will be shown as an interstitial
	BOOL _isInterstitial;

	
@private
	// UI elements
	UIActivityIndicatorView *loadingIndicator;	
	UIWebView *webView;
	
	// Data to hold the web request
	NSURL *url;
	NSMutableData * data;
	
	// native Ad View
	UIView *nativeAdView; 
	
	// store the click-through URL which is encoded for tracking purposes
	NSString *clickURL;
	
	// store the click host for other ad networks c.admob.com, c.google.com, c.quattro.com, from teh header
	NSString *newPageURLString;
	
	// array of strings of parameters to include the the ad request ?exclude=iAd...
	NSMutableArray *excludeParams;
	
}
@property(nonatomic, retain) id<AdControllerDelegate> delegate;
@property(nonatomic, assign) BOOL loaded;

@property(nonatomic, retain) UIViewController* parent;
@property(nonatomic, assign) AdControllerFormat format;
@property(nonatomic, copy) NSString* publisherId;

@property(nonatomic, copy) NSString* keywords;
@property(nonatomic, retain) CLLocation* location;

@property(nonatomic, retain) UIActivityIndicatorView* loadingIndicator;
@property(nonatomic, retain) UIWebView* webView;

@property(nonatomic, copy) NSURL* url;
@property(nonatomic, retain) NSMutableData* data;

@property(nonatomic, retain) UIView* nativeAdView; 

@property(nonatomic, copy) NSString* clickURL;
@property(nonatomic, copy) NSString* newPageURLString;

@property(nonatomic, retain) AdClickController *adClickController;

- (id)initWithFormat:(AdControllerFormat)format publisherId:(NSString*)publisherId parentViewController:(UIViewController*)parent;
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

@end

@protocol AdControllerDelegate
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
 * Responds to notification UIApplicationWillResignActiveNotification
 */
- (void)applicationWillResign:(id)sender;


@end

