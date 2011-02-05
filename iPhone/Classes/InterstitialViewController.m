//
//  InterstitialViewController.m
//  SimpleAds
//
//  Created by James Payne on 2/3/11.
//  Copyright 2011 MoPub Inc. All rights reserved.
//

#import "InterstitialViewController.h"

@implementation InterstitialViewController

@synthesize showInterstitialButton;
@synthesize adController, mrectController, interstitialAdController, navigationInterstitialAdController;

- (void)dealloc{
	[showInterstitialButton release];
	[adController release];
	[mrectController release];
	[interstitialAdController release];
	[navigationInterstitialAdController release];
	[super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = @"Interstitials";
	self.showInterstitialButton.enabled = NO;
}

#pragma mark Orientations

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)newOrientation
								duration:(NSTimeInterval)duration {
	[super willRotateToInterfaceOrientation:newOrientation
								   duration:duration];
}

#pragma mark Basic Interstitials

- (IBAction) getAndShowModalInterstitial{
	[self getModalInterstitial];
	getAndShow = YES;
}

- (IBAction) getModalInterstitial{
	getAndShow = NO;
	self.interstitialAdController = [InterstitialAdController sharedInterstitialAdControllerForAdUnitId:PUB_ID_INTERSTITIAL];	
	self.interstitialAdController.parent = self;
	self.interstitialAdController.delegate = self;
	[self.interstitialAdController loadAd];
}

- (IBAction) showModalInterstitial{
	[self presentModalViewController:interstitialAdController animated:YES];
}

#pragma mark Navigation Interstitials 

- (IBAction) getNavigationInterstitial{
	self.navigationInterstitialAdController = [InterstitialAdController sharedInterstitialAdControllerForAdUnitId:PUB_ID_NAV_INTERSTITIAL];
	self.navigationInterstitialAdController.delegate = self;
	self.navigationInterstitialAdController.parent = self.navigationController;
	[self.navigationInterstitialAdController loadAd];
}

#pragma mark Interstitial delegate methods

- (void)interstitialDidLoad:(InterstitialAdController *)_interstitialAdController{
	if (_interstitialAdController.parent == self.navigationController) {
		// if the adcontroller is the navigational interstitial
		// then we show the interstitial right away as part of the nav action
		// when the interstitial is closed, we can push the actual view into the nav controller
		//
		[self.navigationController pushViewController:self.navigationInterstitialAdController animated:YES];
	}
	else { 
		if (getAndShow) {
			// if its an interstitial we show it right away if the flag is set
			[self presentModalViewController:_interstitialAdController animated:YES];
		} else {
			// otherwise, we enable the button so the user can show it manually
			self.showInterstitialButton.enabled = YES;
		}
	}	
}

- (void)interstitialDidClose:(InterstitialAdController *)_interstitialAdController{
	if (_interstitialAdController == self.navigationInterstitialAdController){
		// if we are in the nav view, we close the interstitial without animation
		// and replace with the SecondViewController
		[self.navigationController popViewControllerAnimated:NO];
		SecondViewController *vc = [[SecondViewController alloc] initWithNibName:@"SecondViewController" bundle:nil];
		[self.navigationController pushViewController:vc animated:YES]; 
		[vc release];
	}
	else {
		[_interstitialAdController dismissModalViewControllerAnimated:YES];
	}

	// release the object
	[InterstitialAdController removeSharedInterstitialAdController:_interstitialAdController];
}

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