//
//  SimpleAdsAppDelegate.m
//  Copyright (c) 2010 MoPub Inc.
//
//

#import "SimpleAdsAppDelegate.h"
#import "SimpleAdsViewController.h"
#import "MPInterstitialAdController.h"
#import "MPAdConversionTracker.h"

@implementation SimpleAdsAppDelegate

@synthesize window;
@synthesize tabBarController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    [[MPAdConversionTracker sharedConversionTracker] reportApplicationOpenForApplicationID:@"agltb3B1Yi1pbmNyCwsSA0FwcBii-wsM"];
	
    // Override point for customization after app launch.
    
    if ([self.window respondsToSelector:@selector(setRootViewController:)]) {
        [self.window setRootViewController:self.tabBarController];
    } else {
        [window addSubview:self.tabBarController.view];
    }
    
    //[[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    [window makeKeyAndVisible];
	
	return YES;
}

- (void)dealloc {
    [tabBarController release];
    [window release];
    [super dealloc];
}

@end
