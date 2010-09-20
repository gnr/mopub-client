//
//  SimpleAdsViewController.m
//  SimpleAds
//

#import "SimpleAdsViewController.h"
#import "AdController.h"
#import <iAd/iAd.h>

@implementation SimpleAdsViewController

@synthesize keyword;
@synthesize adController, mrectController;
@synthesize adView, mrectView;

//#define PUB_ID_320x50 @"agltb3B1Yi1pbmNyDAsSBFNpdGUYudkDDA"
//#define PUB_ID_300x250 @"agltb3B1Yi1pbmNyDAsSBFNpdGUYoeEDDA"

// DEV
#define PUB_ID_320x50 @"agltb3B1Yi1pbmNyCgsSBFNpdGUYAQw"
#define PUB_ID_300x250 @"agltb3B1Yi1pbmNyCgsSBFNpdGUYAQw"

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
