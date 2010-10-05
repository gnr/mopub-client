//
//  SimpleAdsAppDelegate.m
//  Copyright (c) 2010 MoPub Inc.
//
//

#import "SimpleAdsAppDelegate.h"
#import "SimpleAdsViewController.h"
#import "InterstitialAdController.h"
#import "AdConversionTracker.h"

@implementation SimpleAdsAppDelegate

@synthesize window;
@synthesize viewController;
@synthesize navigationController;	
@synthesize interstitialAdController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    [[AdConversionTracker sharedConversionTracker] reportApplicationOpen];
    // Override point for customization after app launch    
	viewController = [[SimpleAdsViewController alloc] initWithNibName:@"SimpleAdsViewController" bundle:nil];
	navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
	viewController.navigationItem.title = @"MoPub Demo";
	
    [window addSubview:navigationController.view];
    [window makeKeyAndVisible];
	
	return YES;
}


- (void)dealloc {
    [viewController release];
	[navigationController release];
	[interstitialAdController release];
    [window release];
    [super dealloc];
}


@end
