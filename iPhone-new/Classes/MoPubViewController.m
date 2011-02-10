//
//  MoPubViewController.m
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import "MoPubViewController.h"

#define PUB_ID_INTERSTITIAL @"agltb3B1Yi1pbmNyDAsSBFNpdGUYsckMDA"

@implementation MoPubViewController



/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

- (void)presentInterstitial
{
	MPInterstitialAdController *interstitialController = 
		[MPInterstitialAdController sharedInterstitialAdControllerForAdUnitId:PUB_ID_INTERSTITIAL];
	interstitialController.parent = self;
	[interstitialController loadAd];
}

- (void)loadView 
{
	self.view = [[[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease];
	self.view.backgroundColor = [UIColor blackColor];
	adView = [[MPAdView alloc] initWithFrame:CGRectMake(0, 200, 320, 50)];
	adView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin |
		UIViewAutoresizingFlexibleBottomMargin;
	adView.delegate = self;
	[self.view addSubview:adView];
	
	UIButton *refresh = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	refresh.frame = CGRectMake(110, 280, 100, 40);
	[refresh setTitle:@"Refresh it." forState:UIControlStateNormal];
	[refresh addTarget:adView action:@selector(refreshAd) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:refresh];
	
	UIButton *interstitial = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	interstitial.frame = CGRectMake(110, 350, 100, 40);
	[interstitial setTitle:@"Interstitial" forState:UIControlStateNormal];
	[interstitial addTarget:self action:@selector(presentInterstitial) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:interstitial];
	
	[adView loadAd];
	[adView release];
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

#pragma mark -
#pragma mark MPAdViewDelegate

- (UIViewController *)viewControllerForPresentingModalView
{
	return self;
}

- (void)adViewWillLoadAd:(MPAdView *)view
{
	NSLog(@"Ad View DELEGATE: %@", NSStringFromSelector(_cmd));
}

- (void)adViewDidFailToLoadAd:(MPAdView *)view
{
	NSLog(@"Ad View DELEGATE: %@", NSStringFromSelector(_cmd));
}

- (void)adViewDidLoadAd:(MPAdView *)view
{
	NSLog(@"Ad View DELEGATE: %@", NSStringFromSelector(_cmd));
}

- (void)nativeAdClicked:(MPAdView *)view
{
	NSLog(@"Ad View DELEGATE: %@", NSStringFromSelector(_cmd));
}

- (void)willPresentModalViewForAd:(MPAdView *)view
{
	NSLog(@"Ad View DELEGATE: %@", NSStringFromSelector(_cmd));
}

- (void)didPresentModalViewForAd:(MPAdView *)view
{
	NSLog(@"Ad View DELEGATE: %@", NSStringFromSelector(_cmd));
}

#pragma mark -
#pragma mark MPInterstitialAdControllerDelegate

- (void)dismissInterstitial:(MPInterstitialAdController *)interstitial
{
	[self dismissModalViewControllerAnimated:YES];
	[MPInterstitialAdController removeSharedInterstitialAdController:interstitial];
}

- (void)interstitialDidLoadAd:(MPInterstitialAdController *)interstitial
{
	[interstitial show];
}

- (void)interstitialDidFailToLoadAd:(MPInterstitialAdController *)interstitial
{
}

- (void)interstitialWillAppear:(MPInterstitialAdController *)interstitial
{
}

- (void)interstitialDidAppear:(MPInterstitialAdController *)interstitial
{
}

#pragma mark -
#pragma mark Custom Event

/*- (void)customEventTest
{
	UIView *redView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
	redView.backgroundColor = [UIColor redColor];
	[adView setAdContentView:redView];
	[redView release];
}*/

/*- (void)customEventTest:(MPAdView *)theAdView
{
	UIView *blueView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
	blueView.backgroundColor = [UIColor blueColor];
	[theAdView setAdContentView:blueView];
	[blueView release];
}*/

#pragma mark -

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
