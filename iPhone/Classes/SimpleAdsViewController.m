//
//  SimpleAdsViewController.m
//  SimpleAds
//

#import "SimpleAdsViewController.h"
#import "AdController.h"
#import <iAd/iAd.h>
#import "InterstitialAdController.h"

@implementation SimpleAdsViewController

@synthesize keyword;
@synthesize adController, mrectController, interstitialAdController;
@synthesize adView, mrectView;

#define PUB_ID_320x50 @"agltb3B1Yi1pbmNyCgsSBFNpdGUYAgw"
#define PUB_ID_300x250 @"agltb3B1Yi1pbmNyCgsSBFNpdGUYAgw"
#define PUB_ID_INTERSTITIAL @"agltb3B1Yi1pbmNyCgsSBFNpdGUYAgw"

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib. 

- (void)dealloc{
	[adController release];
	[mrectController release];
	[interstitialAdController release];
	[super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.adController = [[AdController alloc] initWithFormat:AdControllerFormat320x50 publisherId:PUB_ID_320x50 parentViewController:self];
	self.adController.keywords = @"coffee";
	[self.adView addSubview:self.adController.view];
	
	
	// lets load the mrectController in the background this time
	self.mrectController = [[AdController alloc] initWithFormat:AdControllerFormat300x250 publisherId:PUB_ID_320x50 parentViewController:self];
	self.mrectController.keywords = @"coffee";
	self.mrectController.delegate = self;
	[self.mrectController loadAd];
}

- (IBAction) getAndShowInterstitial{
	getAndShow = YES;
	[self getInterstitial];
}

- (IBAction) getInterstitial{
	interstitialAdController = [[InterstitialAdController alloc] initWithPublisherId:PUB_ID_INTERSTITIAL parentViewController:self];
	self.interstitialAdController.delegate = self;
	[self.interstitialAdController loadAd];
	
}

- (IBAction) showInterstitial{
	// we show the interstitial manually
	// if the ad is not yet loaded, then we pop open an alert view stateing this
	if (interstitialAdController.loaded){
		[self presentModalViewController:interstitialAdController animated:YES];
	}
	else{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"The interstitial has not yet loaded" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
}

- (void)adControllerDidLoadAd:(AdController *)_adController{
	// if for getAndShow we show the interstitial as soon as its available
	if (getAndShow)
		[self showInterstitial];

	// we SLOWLY fade in the mrect whenever we are told the ad has been loaded up
	if (_adController == mrectController){
		self.mrectController.view.alpha = 0.0;
		[self.mrectView addSubview:self.mrectController.view];
		[UIView beginAnimations:@"foo" context:nil];
		[UIView setAnimationDuration:2.0f];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationCurve:UIViewAnimationCurveLinear];
		
		self.mrectController.view.alpha = 1.0;

		[UIView commitAnimations];

	}
}

- (void)interstitialDidClose:(InterstitialAdController *)_interstitialAdController{
	[_interstitialAdController dismissModalViewControllerAnimated:YES];
	getAndShow = NO;
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

@end
