//
//  SimpleAdsAppDelegate.h
//  SimpleAds
//

#import <UIKit/UIKit.h>

@class SimpleAdsViewController;
@class InterstitialAdController;

@interface SimpleAdsAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    SimpleAdsViewController *viewController;
	UINavigationController *navigationController;
	InterstitialAdController *interstitialAdController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet SimpleAdsViewController *viewController;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (readonly) InterstitialAdController *interstitialAdController;

@end

