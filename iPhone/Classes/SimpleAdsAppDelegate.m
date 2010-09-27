//
//  SimpleAdsAppDelegate.m
//  SimpleAds
//
//

#import "SimpleAdsAppDelegate.h"
#import "SimpleAdsViewController.h"

@implementation SimpleAdsAppDelegate

@synthesize window;
@synthesize viewController;
@synthesize navigationController;	

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after app launch    
	viewController = [[SimpleAdsViewController alloc] initWithNibName:@"SimpleAdsViewController" bundle:nil];
	navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
	viewController.navigationItem.title = @"NavController";
    [window addSubview:navigationController.view];
    [window makeKeyAndVisible];
	
	return YES;
}


- (void)dealloc {
    [viewController release];
	[navigationController release];
    [window release];
    [super dealloc];
}


@end
