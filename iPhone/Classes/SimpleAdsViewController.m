//
//  SimpleAdsViewController.m
//  SimpleAds
//
//  Created by Jim Payne on 1/31/10.
//  Copyright Apple Inc 2010. All rights reserved.
//

#import "SimpleAdsViewController.h"
#import "AdController.h"
#import <iAd/iAd.h>

@implementation SimpleAdsViewController

@synthesize keyword;
@synthesize adController, mrectController;
@synthesize adView, mrectView;

#define PUB_ID_320x50 @"ahFoaWdobm90ZS1uZXR3b3Jrc3IMCxIEU2l0ZRi52QMM"
#define PUB_ID_300x250 @"ahFoaWdobm90ZS1uZXR3b3Jrc3IMCxIEU2l0ZRih4QMM"

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
 */


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib. 
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.adController = [[AdController alloc] initWithFormat:AdControllerFormat320x50 publisherId:PUB_ID_320x50 parentViewController:self];
	self.adController.keywords = @"coffee";
	[self.adView addSubview:self.adController.view];

	self.mrectController = [[AdController alloc] initWithFormat:AdControllerFormat300x250 publisherId:PUB_ID_300x250 parentViewController:self];
	self.mrectController.keywords = @"coffee";
	[self.mrectView addSubview:self.mrectController.view];
	
	
	// add a native ADBannerView to contrast
	Class cls = NSClassFromString(@"ADBannerView");
	if (cls != nil) {
		ADBannerView* adBannerView = [[ADBannerView alloc] initWithFrame:CGRectMake(0, 410, 320, 50)];
		adBannerView.requiredContentSizeIdentifiers = [NSSet setWithObjects:ADBannerContentSizeIdentifier320x50, nil];
		adBannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifier320x50;
		
		// replace our view with the Ad view
		[self.view addSubview:adBannerView];
	}	
	
}

- (IBAction) refreshAd {
	[keyword resignFirstResponder];
	
	// update ad 
	self.adController.keywords = keyword.text;
	[self.adController refresh];
	
	// update mrect
	self.mrectController.keywords = keyword.text;
	[self.mrectController refresh];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[self refreshAd];
	return YES;
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end
