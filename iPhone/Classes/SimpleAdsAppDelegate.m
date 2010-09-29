//
//  SimpleAdsAppDelegate.m
//  SimpleAds
//
//

#import "SimpleAdsAppDelegate.h"
#import "SimpleAdsViewController.h"
#import "InterstitialAdController.h"

@implementation SimpleAdsAppDelegate

@synthesize window;
@synthesize viewController;
@synthesize navigationController;	
@synthesize interstitialAdController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after app launch    
	
	
	viewController = [[SimpleAdsViewController alloc] initWithNibName:@"SimpleAdsViewController" bundle:nil];
	navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
	viewController.navigationItem.title = @"Nav Controller";
	
	
	interstitialAdController = [[InterstitialAdController alloc] initWithAdUnitId:PUB_ID_INTERSTITIAL parentViewController:nil];
	interstitialAdController.delegate = viewController; // the SimpleAdsViewController Object controller is response for showing the ad once its ready
	[interstitialAdController loadAd];
	
	
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
