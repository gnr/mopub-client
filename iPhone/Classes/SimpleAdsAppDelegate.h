//
//  SimpleAdsAppDelegate.h
//  SimpleAds
//
//  Created by Jim Payne on 1/31/10.
//  Copyright Apple Inc 2010. All rights reserved.
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

