//
//  MPInterstitialAdController.m
//  MoPub
//
//  Created by Andrew He on 2/2/11.
//  Copyright 2011 MoPub, Inc. All rights reserved.
//

#import "MPInterstitialAdController.h"
#import "MPBaseInterstitialAdapter.h"
#import "MPAdapterMap.h"
#import "MPAdView+InterstitialPrivate.h"

static const CGFloat kCloseButtonPadding				= 6.0;
static NSString * const kCloseButtonXImageName			= @"MPCloseButtonX.png";

// Ad header key/value constants.
static NSString * const kCloseButtonHeaderKey			= @"X-Closebutton";
static NSString * const kCloseButtonNone				= @"None";
static NSString * const kOrientationHeaderKey			= @"X-Orientation";
static NSString * const kOrientationPortraitOnly		= @"p";
static NSString * const kOrientationLandscapeOnly		= @"l";
static NSString * const kOrientationBoth				= @"b";

@interface MPInterstitialAdController (Internal)

- (id)initWithAdUnitId:(NSString *)ID parentViewController:(UIViewController *)parent;
- (void)setCloseButtonImageNamed:(NSString *)name;
- (void)layoutCloseButton;
@end

@interface MPInterstitialAdController ()
@property (nonatomic, retain) UIButton *closeButton;
@property (nonatomic, retain) MPBaseInterstitialAdapter *currentAdapter;
@end

@implementation MPInterstitialAdController

@synthesize ready = _ready;
@synthesize parent = _parent;
@synthesize adUnitId = _adUnitId;
@synthesize closeButton = _closeButton;
@synthesize currentAdapter = _currentAdapter;

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

+ (MPInterstitialAdController *)interstitialAdControllerForAdUnitId:(NSString *)ID
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
	NSMutableArray *sharedInterstitialAdControllers = 
		[MPInterstitialAdController sharedInterstitialAdControllers];
	[sharedInterstitialAdControllers removeObject:controller];
}

+ (void)removeAllSharedInterstitialAdControllers
{
	NSMutableArray *sharedInterstitialAdControllers = 
		[MPInterstitialAdController sharedInterstitialAdControllers];
	[sharedInterstitialAdControllers removeAllObjects];
}

#pragma mark -
#pragma mark Lifecycle

- (id)initWithAdUnitId:(NSString *)ID parentViewController:(UIViewController *)parent
{
	if (self = [super init])
	{
		_ready = NO;
		_parent = parent;
		_adUnitId = ID;
		_closeButtonType = InterstitialCloseButtonTypeDefault;
		_orientationType = InterstitialOrientationTypeBoth;
		
		_adView = [[MPAdView alloc] initWithAdUnitId:self.adUnitId size:CGSizeZero];
		_adView.stretchesWebContentToFill = YES;
		_adView.delegate = self;
		
		// Typically, we don't set an autoresizing mask for MPAdView, but in this case we always
		// want it to occupy the full screen.
		_adView.autoresizingMask = UIViewAutoresizingFlexibleWidth | 
			UIViewAutoresizingFlexibleHeight;
	}
	return self;
}

- (void)dealloc 
{
	_parent = nil;
	_adView.delegate = nil;
	[_currentAdapter unregisterDelegate];
	[_currentAdapter release];
	[_adView release];
	[_adUnitId release];
    [super dealloc];
}

- (void)loadView 
{
	CGRect screenBounds = MPScreenBounds();
	
	self.view = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
	self.view.backgroundColor = [UIColor blackColor];
	self.view.frame = screenBounds;
	self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	_adView.frame = self.view.bounds;
	
	[self.view addSubview:_adView];
	[self layoutCloseButton];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if ([self.parent respondsToSelector:@selector(interstitialWillAppear:)])
		[self.parent interstitialWillAppear:self];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[_adView adViewDidAppear];
}

#pragma mark -
#pragma mark Internal

- (void)setCloseButtonImageNamed:(NSString *)name
{
	UIImage *image = [UIImage imageNamed:name];
	[self.closeButton setImage:image forState:UIControlStateNormal];
	[self.closeButton sizeToFit];
}

- (void)layoutCloseButton
{
	if (!self.closeButton) 
	{
		self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
		self.closeButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | 
			UIViewAutoresizingFlexibleBottomMargin;
		[self.closeButton addTarget:self 
							 action:@selector(closeButtonPressed) 
				   forControlEvents:UIControlEventTouchUpInside];
		[self setCloseButtonImageNamed:kCloseButtonXImageName];
		
		CGFloat originx = self.view.bounds.size.width;
		originx -= self.closeButton.bounds.size.width + kCloseButtonPadding;
		self.closeButton.frame = CGRectMake(originx, 
											kCloseButtonPadding, 
											self.closeButton.bounds.size.width,
											self.closeButton.bounds.size.height);
		
		[self.view addSubview:self.closeButton];
		[self.view bringSubviewToFront:self.closeButton];
	}
					
	if (_closeButtonType == InterstitialCloseButtonTypeDefault)
	{
		[self setCloseButtonImageNamed:kCloseButtonXImageName];
		self.closeButton.hidden = NO;
	}
	else
	{
		self.closeButton.hidden = YES;
	}
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
	[[UIApplication sharedApplication] setStatusBarHidden:_statusBarWasHidden];
	[self.navigationController setNavigationBarHidden:_navigationBarWasHidden animated:NO];
	
	[self.parent dismissInterstitial:self];
}

- (void)loadAd
{
	_ready = NO;
	[_adView loadAd];
}

- (void)show
{	
	if (self.currentAdapter != nil)
	{
		[self.currentAdapter showInterstitialFromViewController:self.parent];
	}
	else 
	{
		[self interstitialWillAppearForAdapter:nil];
		// Track the previous state of the status bar, so that we can restore it.
		_statusBarWasHidden = [UIApplication sharedApplication].statusBarHidden;
		[[UIApplication sharedApplication] setStatusBarHidden:YES];
		
		// Likewise, track the previous state of the navigation bar.
		_navigationBarWasHidden = self.navigationController.navigationBarHidden;
		[self.navigationController setNavigationBarHidden:YES animated:YES];
		
		[self.parent presentModalViewController:self animated:YES];
		[self interstitialDidAppearForAdapter:nil];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	if (_orientationType == InterstitialOrientationTypePortrait)
		return (interfaceOrientation == UIInterfaceOrientationPortrait || 
				interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
	else if (_orientationType == InterstitialOrientationTypeLandscape)
		return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || 
				interfaceOrientation == UIInterfaceOrientationLandscapeRight);
	else return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
										 duration:(NSTimeInterval)duration
{
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

#pragma mark -
#pragma mark MPAdViewDelegate

- (UIViewController *)viewControllerForPresentingModalView
{
	return self;
}

- (void)adViewDidLoadAd:(MPAdView *)view
{
	_ready = YES;
	
	if ([self.parent respondsToSelector:@selector(interstitialDidLoadAd:)])
		[self.parent interstitialDidLoadAd:self];
}

- (void)adViewDidFailToLoadAd:(MPAdView *)view
{
	_ready = NO;
	
	if ([self.parent respondsToSelector:@selector(interstitialDidFailToLoadAd:)])
		[self.parent interstitialDidFailToLoadAd:self];
}

- (void)willPresentModalViewForAd:(MPAdView *)view
{
	if ([self.parent respondsToSelector:@selector(willPresentModalViewForAd:)])
		[self.parent willPresentModalViewForAd:view];
}

- (void)adViewDidReceiveResponseParams:(NSDictionary *)params
{
	NSString *closeButtonChoice = [params objectForKey:kCloseButtonHeaderKey];
	
	if ([closeButtonChoice isEqualToString:kCloseButtonNone])
		_closeButtonType = InterstitialCloseButtonTypeNone;
	else
		_closeButtonType = InterstitialCloseButtonTypeDefault;
	
	// Adjust the close button depending on the header value.
	[self layoutCloseButton];
	
	// Set the allowed orientations.
	NSString *orientationChoice = [params objectForKey:kOrientationHeaderKey];
	if ([orientationChoice isEqualToString:kOrientationPortraitOnly])
		_orientationType = InterstitialOrientationTypePortrait;
	else if ([orientationChoice isEqualToString:kOrientationLandscapeOnly])
		_orientationType = InterstitialOrientationTypeLandscape;
	else 
		_orientationType = InterstitialOrientationTypeBoth;
	
	NSString *adapterType = [params objectForKey:@"X-Fulladtype"];
	if (!adapterType || [adapterType isEqualToString:@""]) return;
	NSString *classString = [[MPAdapterMap sharedAdapterMap] classStringForAdapterType:adapterType];
	Class cls = NSClassFromString(classString);
	if (cls != nil)
	{
		[self.currentAdapter unregisterDelegate];	
		self.currentAdapter = (MPBaseInterstitialAdapter *)[[cls alloc] initWithInterstitialAdController:self];
		[self.currentAdapter getAdWithParams:params];
	}
	else 
	{
		// TODO: Generate error.
		[self adapter:nil didFailToLoadAdWithError:nil];
	}
}

- (void)adViewShouldClose:(MPAdView *)view
{
	[self closeButtonPressed];
}

#pragma mark -
#pragma mark MPBaseInterstitialAdapterDelegate

- (void)adapterDidFinishLoadingAd:(MPBaseInterstitialAdapter *)adapter
{	
	_ready = YES;
	_adView.isLoading = NO;
	if ([self.parent respondsToSelector:@selector(interstitialDidLoadAd:)])
		[self.parent interstitialDidLoadAd:self];
}

- (void)adapter:(MPBaseInterstitialAdapter *)adapter didFailToLoadAdWithError:(NSError *)error
{
	_ready = NO;
	MPLogError(@"Interstitial adapter (%p) failed to load ad. Error: %@", adapter, error);
	
	// Dispose of the current adapter, because we don't want it to try loading again.
	[self.currentAdapter unregisterDelegate];
	self.currentAdapter = nil;
	
	[_adView adapter:nil didFailToLoadAdWithError:error];
}

- (void)interstitialWillAppearForAdapter:(MPBaseInterstitialAdapter *)adapter
{
	[_adView trackImpression];
	if ([self.parent respondsToSelector:@selector(interstitialWillAppear:)])
		[self.parent interstitialWillAppear:self];
}

- (void)interstitialDidAppearForAdapter:(MPBaseInterstitialAdapter *)adapter
{
	if ([self.parent respondsToSelector:@selector(interstitialDidAppear:)])
		[self.parent interstitialDidAppear:self];
}

- (void)interstitialWillDisappearForAdapter:(MPBaseInterstitialAdapter *)adapter
{
	if ([self.parent respondsToSelector:@selector(interstitialWillDisappear:)])
		[self.parent interstitialWillDisappear:self];
}

- (void)interstitialDidDisappearForAdapter:(MPBaseInterstitialAdapter *)adapter
{
	if ([self.parent respondsToSelector:@selector(interstitialDidDisappear:)])
		[self.parent interstitialDidDisappear:self];
}

#pragma mark -

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	
	self.closeButton = nil;
}

@end
