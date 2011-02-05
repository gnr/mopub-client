//
//  MPInterstitialAdController.m
//  MoPub
//
//  Created by Andrew He on 2/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MPInterstitialAdController.h"

@implementation MPInterstitialAdController

@synthesize ready = _ready;
@synthesize parent = _parent;
@synthesize adUnitId = _adUnitId;

#pragma mark -
#pragma mark Class methods

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

#pragma mark -
#pragma mark Lifecycle

- (id)initWithAdUnitId:(NSString *)ID parentViewController:(UIViewController *)parent
{
	if (self = [super init])
	{
		_ready = NO;
		self.parent = parent;
		self.adUnitId = ID;
		_adSize = [[UIScreen mainScreen] bounds].size;
		_closeButtonType = InterstitialCloseButtonTypeDefault;
		_orientationType = InterstitialOrientationTypeBoth;
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

#pragma mark -

- (void)setKeywords:(NSString *)keywords
{
	_adView.keywords = keywords;
}

- (NSString *)keywords
{
	return _adView.keywords;
}

- (void)closeButtonPressed
{
	// Restore previous status/navigation bar state.
	[[UIApplication sharedApplication] setStatusBarHidden:_statusBarWasHidden withAnimation:UIStatusBarAnimationNone];
	[self.navigationController setNavigationBarHidden:_navigationBarWasHidden animated:NO];
	
	[self.parent dismissInterstitial:self];
}

- (void)_setUpCloseButton
{
	if (_closeButtonType == InterstitialCloseButtonTypeDefault)
	{
		[_closeButton removeFromSuperview];
		_closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
		UIImage *closeButtonImage = [UIImage imageNamed:@"moPubCloseButtonX.png"];
		[_closeButton setImage:closeButtonImage forState:UIControlStateNormal];
		[_closeButton sizeToFit];
		_closeButton.frame = CGRectMake(self.view.frame.size.width - 20.0 - _closeButton.frame.size.width,
										20.0,
										_closeButton.frame.size.width,
										_closeButton.frame.size.height);
		_closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
		[_closeButton addTarget:self action:@selector(closeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:_closeButton];
		[self.view bringSubviewToFront:_closeButton];
	}
	else
	{
		[_closeButton removeFromSuperview];
	}
}

- (void)loadView 
{
	UIView *container = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
	container.backgroundColor = [UIColor greenColor];
	container.frame = (CGRect){{0, 0}, [[UIScreen mainScreen] applicationFrame].size};
	container.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.view = container;
	
	_adView = [[MPAdView alloc] initWithFrame:(CGRect){{0, 0}, _adSize}];
	_adView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_adView.adUnitId = self.adUnitId;
	_adView.delegate = self;
	[self.view addSubview:_adView];
	
	[self _setUpCloseButton];
}

- (void)loadAd
{
	// TODO: figure out better place to do this load view
	self.view;
	[_adView loadAd];
}

- (void)show
{
	// Track the previous state of the status bar, so that we can restore it.
	_statusBarWasHidden = [UIApplication sharedApplication].statusBarHidden;
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
	
	// Likewise, track the previous state of the navigation bar.
	_navigationBarWasHidden = self.navigationController.navigationBarHidden;
	[self.navigationController setNavigationBarHidden:YES animated:NO];
	
	[self.parent presentModalViewController:self animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
	self.view;
	[super viewWillAppear:animated];
	
	if ([self.parent respondsToSelector:@selector(interstitialWillAppear:)])
		[self.parent interstitialWillAppear:self];
}

- (void)viewDidAppear:(BOOL)animated
{
	self.view;
	[_adView viewDidAppear];
	[super viewDidAppear:animated];
	
	if ([self.parent respondsToSelector:@selector(interstitialDidAppear:)])
		[self.parent interstitialDidAppear:self];
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
	_ready = NO;
	
	if ([self.parent respondsToSelector:@selector(interstitialDidFailToLoadAd:)])
		[self.parent interstitialDidFailToLoadAd:self];
}

- (void)adViewDidLoadAd:(MPAdView *)view
{
	_ready = YES;
	
	if ([self.parent respondsToSelector:@selector(interstitialDidLoadAd:)])
		[self.parent interstitialDidLoadAd:self];
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

- (void)adViewDidReceiveResponseParams:(NSDictionary *)params
{
	NSString *closeButtonChoice = [params objectForKey:@"X-Closebutton"];
	
	if ([closeButtonChoice isEqualToString:@"None"])
		_closeButtonType = InterstitialCloseButtonTypeNone;
	else
		_closeButtonType = InterstitialCloseButtonTypeDefault;
	
	NSString *orientationChoice = [params objectForKey:@"X-Orientation"];
	// TODO: turn these into constants
	if ([orientationChoice isEqualToString:@"p"])
		_orientationType = InterstitialOrientationTypePortrait;
	else if ([orientationChoice isEqualToString:@"l"])
		_orientationType = InterstitialOrientationTypeLandscape;
	else 
		_orientationType = InterstitialOrientationTypeBoth;
}

#pragma mark -

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	if (_orientationType == InterstitialOrientationTypePortrait)
		return (interfaceOrientation == UIInterfaceOrientationPortrait || 
				interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
	else if (_orientationType == InterstitialOrientationTypeLandscape)
		return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || 
				interfaceOrientation == UIInterfaceOrientationLandscapeRight);
	else
		return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
										 duration:(NSTimeInterval)duration
{
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	//[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];	
}

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
