//
//  NavAppAppDelegate.h
//  NavApp
//
//  Created by Nafis Jamal on 4/20/11.
//  Copyright 2011 MoPub. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NavAppAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    UIViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end

