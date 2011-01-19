//
//  SimpleAdsViewController.m
//  Copyright (c) 2010 MoPub Inc.
//

#import "SimpleAdsViewController.h"
#import "AdController.h"
#import "InterstitialAdController.h"
//#import <iAd/iAd.h>

@implementation SimpleAdsViewController

@synthesize keyword;
@synthesize adController, mrectController, interstitialAdController, navigationInterstitialAdController;
@synthesize adView, mrectView;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib. 

- (void)dealloc{
	[adController release];
	[mrectController release];
	[interstitialAdController release];
	[super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	
	// put the ad on screen and have it appear as soon as its ready
	self.adController = [[AdController alloc] initWithSize:self.adView.frame.size adUnitId:PUB_ID_320x50 parentViewController:self];
	self.adController.keywords = @"coffee";
	self.adController.delegate = self;
	[self.adView addSubview:self.adController.view];
	
	// set up the ad controller, but don't display the ad until we get a callback
	self.mrectController = [[AdController alloc] initWithSize:self.mrectView.frame.size adUnitId:PUB_ID_300x250 parentViewController:self];
	self.mrectController.keywords = @"coffee";
	self.mrectController.delegate = self;
	[self.mrectController loadAd];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)newOrientation
								duration:(NSTimeInterval)duration {
	[super willRotateToInterfaceOrientation:newOrientation
								   duration:duration];
	
	// //  ONLY IF YOU WANT TO RESIZE iAD
	// we only need to tell the top banner about the rotation
	// since we only have banner iAds (not mRects)
	//	[self.adController rotateToOrientation:newOrientation];
	//	[self adjustAdSize];
}

- (void)adjustAdSize{
//	if ([self.adController.currentAdType isEqual:@"iAd"]){
//		CGRect newFrame = self.adController.nativeAdView.frame;
//		if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)){
//			newFrame.origin.x = -80.0;
//		}
//		else {
//			newFrame.origin.x = 0.0;
//		}
//		
//		self.adController.nativeAdView.frame = newFrame;
//		if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation])){
//			((ADBannerView *)self.adController.nativeAdView).currentContentSizeIdentifier = ADBannerContentSizeIdentifier320x50;
//		}
//		else {
//			((ADBannerView *)self.adController.nativeAdView).currentContentSizeIdentifier = ADBannerContentSizeIdentifier480x32;
//		}
//		
//	}	
}

- (IBAction) getNavigationInterstitial{
	if (!shownNavigationInterstitialAlready){
		self.navigationInterstitialAdController = [InterstitialAdController sharedInterstitialAdControllerForAdUnitId:PUB_ID_NAV_INTERSTITIAL];
		self.navigationInterstitialAdController.delegate = self;
		self.navigationInterstitialAdController.parent = self.navigationController;
		[self.navigationInterstitialAdController loadAd];
	}
	else {
		SecondViewController *vc = [[SecondViewController alloc] initWithNibName:@"SecondViewController" bundle:nil];
		[self.navigationController pushViewController:vc animated:YES]; 
		[vc.navigationController setNavigationBarHidden:NO animated:YES];
		[vc release];
		
	}

}

- (IBAction) getAndShowModalInterstitial{
	getAndShow = YES;
	[self getModalInterstitial];
}

- (IBAction) getModalInterstitial{
	self.interstitialAdController = [InterstitialAdController sharedInterstitialAdControllerForAdUnitId:PUB_ID_INTERSTITIAL];	
	self.interstitialAdController.parent = self;
	self.interstitialAdController.delegate = self;
	self.interstitialAdController.keywords = @"coffee";
	[self.interstitialAdController loadAd];
	
}

- (IBAction) showModalInterstitial{
	[self presentModalViewController:interstitialAdController animated:YES];
}

- (void)interstitialDidLoad:(InterstitialAdController *)_interstitialAdController{
	// if the adcontroller is the navigational interstitial
	if (_interstitialAdController.parent == self.navigationController){
		[self.navigationController pushViewController:self.navigationInterstitialAdController animated:YES];
	}
	else{
		// if its an interstitial we show it right away
		[self presentModalViewController:_interstitialAdController animated:YES];
	}
	
}

- (void)adControllerDidLoadAd:(AdController *)_adController{
	NSLog(@"AD DID LOAD %@",_adController);
	
	// we SLOWLY fade in the mrect whenever we are told the ad has been loaded up
	if (_adController == mrectController){
		self.mrectController.view.alpha = 0.0;
		[self.mrectView addSubview:self.mrectController.view];
		[UIView beginAnimations:@"fadeIn" context:nil];
		[UIView setAnimationDuration:2.0f];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationCurve:UIViewAnimationCurveLinear];
		
		self.mrectController.view.alpha = 1.0;

		[UIView commitAnimations];
	}
//  //  ONLY IF YOU WANT TO RESIZE iAD	
//	else if (_adController == adController){
//		[self adjustAdSize];
//	}
}

- (void)adControllerFailedLoadAd:(AdController *)_adController{
//	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"MoPub" message:@"Ad Failed to Load" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//	[alert show];
//	[alert release];
}

- (void)interstitialDidClose:(InterstitialAdController *)_interstitialAdController{
	if (_interstitialAdController == self.navigationInterstitialAdController){
		[self.navigationController popViewControllerAnimated:NO];
		SecondViewController *vc = [[SecondViewController alloc] initWithNibName:@"SecondViewController" bundle:nil];
		[self.navigationController pushViewController:vc animated:YES]; 
		[vc release];
		shownNavigationInterstitialAlready = YES;
	}
	else {
		[_interstitialAdController dismissModalViewControllerAnimated:YES];
	}
	// release the object
	[InterstitialAdController removeSharedInterstitialAdController:_interstitialAdController];

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
