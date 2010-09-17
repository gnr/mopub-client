//
//  SimpleAdsAppDelegate.h
//  SimpleAds
//

#import <UIKit/UIKit.h>

@class SimpleAdsViewController;

@interface SimpleAdsAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    SimpleAdsViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet SimpleAdsViewController *viewController;

@end

