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

@protocol AdControllerDelegate;

@interface AdController : UIViewController <UIWebViewDelegate, ADBannerViewDelegate> {
	id<AdControllerDelegate> delegate;
	BOOL loaded;
	
	UIViewController* parent;
	AdControllerFormat format;
	NSString* publisherId;

	NSString* keywords;
	CLLocation* location;

@private
	// UI elements
	UIActivityIndicatorView* loading;	
	UIWebView* webView;
	
	// Data to hold the web request
	NSURL* url;
	NSMutableData* data;
	
	// native Ad View
	UIView* nativeAdView; 
	
	// store the click-through URL which is encoded for tracking purposes
	NSString* clickURL;
}
@property(nonatomic, retain) id<AdControllerDelegate> delegate;
@property(assign) BOOL loaded;

@property(nonatomic, retain) UIViewController* parent;
@property(nonatomic, assign) AdControllerFormat format;
@property(nonatomic, copy) NSString* publisherId;

@property(nonatomic, retain) NSString* keywords;
@property(nonatomic, retain) CLLocation* location;

@property(nonatomic, retain) UIActivityIndicatorView* loading;
@property(nonatomic, retain) UIWebView* webView;

@property(nonatomic, retain) NSURL* url;
@property(nonatomic, retain) NSMutableData* data;

@property(nonatomic, retain) UIView* nativeAdView; 

@property(nonatomic, retain) NSString* clickURL;

- (id)initWithFormat:(AdControllerFormat)format publisherId:(NSString*)publisherId parentViewController:(UIViewController*)parent;
- (void)loadAd;
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
 * Called when the ad has been clicked and the ad landing page is about to open.
 */
- (void)adControllerAdWillOpen:(AdController*)adController;

- (void)didSelectClose:(id)sender;
- (void)applicationWillResign:(id)sender;


@end

