//
//  SimpleAdsAppDelegate.m
//  SimpleAds
//
//  Created by Jim Payne on 1/31/10.
//  Copyright Apple Inc 2010. All rights reserved.
//

#import "SimpleAdsAppDelegate.h"
#import "SimpleAdsViewController.h"

@implementation SimpleAdsAppDelegate

@synthesize window;
@synthesize viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
	
	return YES;
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
