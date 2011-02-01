//
//  MoPubAppDelegate.h
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MoPubViewController;

@interface MoPubAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    MoPubViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MoPubViewController *viewController;

@end

