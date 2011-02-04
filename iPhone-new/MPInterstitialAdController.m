//
//  MPInterstitialAdController.m
//  MoPub
//
//  Created by Andrew He on 2/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MPInterstitialAdController.h"

@implementation MPInterstitialAdController

@synthesize parent = _parent;
@synthesize adUnitId = _adUnitId;
@synthesize adSize = _adSize;
@synthesize closeButtonType = _closeButtonType;

+ (NSMutableArray *)sharedInterstitialAdControllers
{
	static NSMutableArray *sharedInterstitialAdControllers;
	
	@synchronized(self)
	{
		if (!sharedInterstitialAdControllers)
			sharedInterstitialAdControllers = [[NSMutableArray alloc] initWithCapacity:1];
	}
	return sharedInterstitialAdControllers;
}

+ (MPInterstitialAdController *)sharedInterstitialAdControllerForAdUnitId:(NSString *)ID
{	
	NSMutableArray *controllers = [MPInterstitialAdController sharedInterstitialAdControllers];
	
	@synchronized(self)
	{
		// Find the correct ad controller based on the ad unit ID.
		MPInterstitialAdController *controller = nil;
		for (MPInterstitialAdController *c in controllers)
		{
			if ([c.adUnitId isEqualToString:ID])
			{
				controller = c;
				break;
			}
		}
		
		// Create the ad controller if it doesn't exist.
		if (!controller)
		{
			controller = [[[MPInterstitialAdController alloc] initWithAdUnitId:ID 
														  parentViewController:nil] autorelease];
			[controllers addObject:controller];
		}
		return controller;
	}
}

+ (void)removeSharedInterstitialAdController:(MPInterstitialAdController *)controller
{
	NSMutableArray *sharedInterstitialAdControllers = [MPInterstitialAdController sharedInterstitialAdControllers];
	[sharedInterstitialAdControllers removeObject:controller];
}

- (id)initWithAdUnitId:(NSString *)ID parentViewController:(UIViewController *)parent
{
	if (self = [super init])
	{
		self.parent = parent;
		self.adUnitId = ID;
		self.adSize = [[UIScreen mainScreen] bounds].size;
		self.closeButtonType = InterstitialCloseButtonTypeDefault;
	}
	return self;
}

- (void)dealloc 
{
	_parent = nil;
	_adView.delegate = nil;
	[_adView release];
	[_adUnitId release];
    [super dealloc];
}

- (void)closeButtonPressed
{
	[self.parent shouldDismissInterstitial];
}

- (void)_setUpCloseButton
{
	if (self.closeButtonType == InterstitialCloseButtonTypeDefault)
	{
		UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
		UIImage *closeButtonImage = [UIImage imageNamed:@"moPubCloseButtonX.png"];
		[closeButton setImage:closeButtonImage forState:UIControlStateNormal];
		[closeButton sizeToFit];
		closeButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 20.0 - closeButton.frame.size.width,
									   20.0,
									   closeButton.frame.size.width,
									   closeButton.frame.size.height);
		// TODO: autoresizing mask
		[closeButton addTarget:self action:@selector(closeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:closeButton];
		[self.view bringSubviewToFront:closeButton];
	}
}

- (void)loadView 
{
	UIView *container = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
	container.backgroundColor = [UIColor greenColor];
	container.frame = (CGRect){{0, 0}, [UIScreen mainScreen].bounds.size};
	self.view = container;
	
	_adView = [[MPAdView alloc] initWithFrame:(CGRect){{0, 0}, self.adSize}];
	_adView.adUnitId = self.adUnitId;
	_adView.delegate = self;
	[self.view addSubview:_adView];
	
	[self _setUpCloseButton];
}

- (void)loadAd
{
	self.view;
	[_adView loadAd];
}

#pragma mark -
#pragma mark MPAdViewDelegate

- (UIViewController *)viewControllerForPresentingModalView
{
	return self.parent;
}

- (void)adViewWillLoadAd:(MPAdView *)view
{
	if ([self.parent respondsToSelector:@selector(adViewWillLoadAd:)])
		[self.parent adViewWillLoadAd:view];
}

- (void)adViewDidFailToLoadAd:(MPAdView *)view
{
	if ([self.parent respondsToSelector:@selector(adViewDidFailToLoadAd:)])
		[self.parent adViewDidFailToLoadAd:view];
}

- (void)adViewDidLoadAd:(MPAdView *)view
{
	if ([self.parent respondsToSelector:@selector(adViewDidLoadAd:)])
		[self.parent adViewDidLoadAd:view];
}

- (void)nativeAdClicked:(MPAdView *)view
{
	if ([self.parent respondsToSelector:@selector(nativeAdClicked:)])
		[self.parent nativeAdClicked:view];
}

- (void)willPresentModalViewForAd:(MPAdView *)view
{
	if ([self.parent respondsToSelector:@selector(willPresentModalViewForAd:)])
		[self.parent willPresentModalViewForAd:view];}

- (void)didPresentModalViewForAd:(MPAdView *)view
{
	if ([self.parent respondsToSelector:@selector(didPresentModalViewForAd:)])
		[self.parent didPresentModalViewForAd:view];
}

#pragma mark -

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

@end
