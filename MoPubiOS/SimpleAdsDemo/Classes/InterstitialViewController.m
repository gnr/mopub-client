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
@synthesize interstitialAdController;

- (void)dealloc{
	[showInterstitialButton release];
	[interstitialAdController release];
	[super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = @"Interstitials";
	self.showInterstitialButton.hidden = YES;
}

#pragma mark Basic Interstitials

- (IBAction) getAndShowModalInterstitial{
	[self getModalInterstitial];
	getAndShow = YES;
}

- (IBAction) getModalInterstitial{
	getAndShow = NO;
	self.interstitialAdController = [MPInterstitialAdController interstitialAdControllerForAdUnitId:PUB_ID_INTERSTITIAL];	
	self.interstitialAdController.delegate = self;
	[self.interstitialAdController loadAd];
}

- (IBAction) showModalInterstitial{
	[interstitialAdController showFromViewController:self];
}

#pragma mark Interstitial delegate methods
- (UIViewController *)viewControllerForPresentingModalView{
	return self;
}

- (void)interstitialDidLoadAd:(MPInterstitialAdController *)interstitial{
	NSLog(@"Interstitial did load Ad: %@",interstitial);
	if (getAndShow) {
        [interstitial showFromViewController:self];
    } else {
        // otherwise, we enable the button so the user can show it manually
        self.showInterstitialButton.hidden = NO;
    }
}

- (void)dismissInterstitial:(MPInterstitialAdController *)interstitial{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)interstitialDidFailToLoadAd:(MPInterstitialAdController *)interstitial{
	NSLog(@"Interstitial did fail to return ad %@",interstitial);
}

- (void)interstitialWillAppear:(MPInterstitialAdController *)interstitial{
	NSLog(@"Interstitial will appear: %@",interstitial);
}

- (void)interstitialDidExpire:(MPInterstitialAdController *)interstitial {
    // Reload the interstitial ad, if desired.
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end