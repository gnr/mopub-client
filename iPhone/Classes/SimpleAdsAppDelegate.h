//
//  SimpleAdsAppDelegate.h
//  Copyright (c) 2010 MoPub Inc.
//

#import <UIKit/UIKit.h>

@class SimpleAdsViewController;
@class InterstitialAdController;

@interface SimpleAdsAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    SimpleAdsViewController *viewController;
	UINavigationController *navigationController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet SimpleAdsViewController *viewController;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@end

