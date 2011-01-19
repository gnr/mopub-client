//
//  InterstitialAdController.m
//  Copyright (c) 2010 MoPub Inc.
//
//  Created by Nafis Jamal on 9/21/10.
//

#import "InterstitialAdController.h"

@interface InterstitialAdController (Internal)
- (UIColor *)colorForHex:(NSString *)hexColor;
@end


@implementation InterstitialAdController

@synthesize closeButton, adUnitId, delegate, adController;
@synthesize backgroundColor;


+ (NSMutableArray *)sharedInterstitialAdControllers{
	static NSMutableArray *sharedInterstitialAdControllers;
	
	@synchronized(self){
		// set up array of interstitial ad controllers
		if (!sharedInterstitialAdControllers)
			sharedInterstitialAdControllers = [[NSMutableArray alloc] initWithCapacity:1];
	}
	return sharedInterstitialAdControllers;
	
}

+ (InterstitialAdController *)sharedInterstitialAdControllerForAdUnitId:(NSString *)a{	
	NSMutableArray *sharedInterstitialAdControllers = [InterstitialAdController sharedInterstitialAdControllers];
	
	@synchronized(self)
	{
		// find the correct ad controller based on the adunit id
		InterstitialAdController *sharedInterstitialAdController = nil;
		for (InterstitialAdController *interstialAdController in sharedInterstitialAdControllers){
			if ([interstialAdController.adUnitId isEqual:a]){
				sharedInterstitialAdController = interstialAdController;
				break;
			}
		}
			
		
		// make the ad controller if it doesn't exist
		if (!sharedInterstitialAdController){
			sharedInterstitialAdController = [[[InterstitialAdController alloc] initWithAdUnitId:a parentViewController:nil] autorelease];
			[sharedInterstitialAdControllers addObject:sharedInterstitialAdController];
		}
		return sharedInterstitialAdController;
	}
}

+ (void)removeSharedInterstitialAdController:(InterstitialAdController *)interstitialAdController{
	NSMutableArray *sharedInterstitialAdControllers = [InterstitialAdController sharedInterstitialAdControllers];
	[sharedInterstitialAdControllers removeObject:interstitialAdController];
}

-(id)initWithAdUnitId:(NSString *)a parentViewController:(UIViewController*)pvc{
	if (self = [super init])
	{
		self.parent = pvc;
		adUnitId = [a copy];
		adSize = [[UIScreen mainScreen] bounds].size;

	}
	return self;
}


- (BOOL)loaded{
	return self.adController.loaded;
}

- (void)setKeywords:(NSString *)kw{
	self.adController.keywords = kw;
}

- (NSString *)keywords{
	return self.adController.keywords;
}

- (AdController *)adController{
	if (!_adController){
		_adController = [[AdController alloc] initWithSize:adSize adUnitId:adUnitId parentViewController:self];
		_adController.delegate = self;
	}
	return _adController;
}

- (void)setParent:(UIViewController *)vc{
	[vc retain];
	[parent release];
	parent = vc;
	
	_inNavigationController = [parent isKindOfClass:[UINavigationController class]];
	
	if (_inNavigationController) {
		closeButtonType = AdCloseButtonTypeNext;
	}
	else {
		closeButtonType = AdCloseButtonTypeDefault;
	}
}

- (UIViewController *)parent{
	return parent;
}

- (void)loadAd{
	[self.adController loadAd];
}

- (void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	
	[self.adController viewWillAppear:animated];
	if ([self.delegate respondsToSelector:@selector(interstitialWillAppear:)]){
		[self.delegate performSelector:@selector(interstitialWillAppear:) withObject:self];
	}
}

- (void)viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
	[self.adController viewDidAppear:animated];
	if ([self.delegate respondsToSelector:@selector(interstitialDidAppear:)]){
		[self.delegate performSelector:@selector(interstitialDidAppear:) withObject:self];
	}
}
- (void)viewDidLoad {
    [super viewDidLoad];
	
	// no-op if not in a navigation view
	wasNavigationBarHidden = self.navigationController.navigationBarHidden;
	// hide the navigation bar
	[self.navigationController setNavigationBarHidden:YES animated:NO];
	
	// store that the state of the status bar
	wasStatusBarHidden = [UIApplication sharedApplication].statusBarHidden;
	// hide the status bar
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];	
	
	self.view.backgroundColor = backgroundColor;
	
	CGSize screenSize = [UIScreen mainScreen].bounds.size;

	self.adController.view.frame = CGRectMake((screenSize.width-adSize.width)/2.0,(screenSize.height-adSize.height)/2.0,adSize.width,adSize.height);
	self.adController.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
	[self.view addSubview:self.adController.view];
	[self makeCloseButton];

}

- (void)loadView{
	[super loadView];
	
	
}


- (void)makeCloseButton{
	// we add a close button to the top right corner of the screen
	if (closeButtonType == AdCloseButtonTypeDefault || closeButtonType == AdCloseButtonTypeNext){
		[self.closeButton removeFromSuperview];
		self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom]; 
		NSString *closeButtonImageName;
		if (closeButtonType == AdCloseButtonTypeDefault){
			closeButtonImageName = @"moPubCloseButtonX.png";
		}
		else if (closeButtonType == AdCloseButtonTypeNext){
			closeButtonImageName = @"moPubCloseButtonNext.png";
		}
		UIImage *closeButtonImage = [UIImage imageNamed:closeButtonImageName];
		[closeButton setImage:closeButtonImage forState:UIControlStateNormal];
		[closeButton sizeToFit];
		closeButton.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width-closeButton.frame.size.width-10.0, 10.0, closeButton.frame.size.width, closeButton.frame.size.height);
		closeButton.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin); // keep close button on the top right
		[closeButton addTarget:self action:@selector(didSelectClose:) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:closeButton];
		[self.view bringSubviewToFront:closeButton];
	}
	else if (closeButtonType == AdCloseButtonTypeNone){
		// remove the close button if it was already there
		[closeButton removeFromSuperview];
	}
	
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];	
}


- (void)didSelectClose:(id)sender{
	[self.adController didSelectClose:sender];
	
	// return the state of the status bar
	[[UIApplication sharedApplication] setStatusBarHidden:wasStatusBarHidden withAnimation:UIStatusBarAnimationNone];
	// return the state of the navigation bar
	[self.navigationController setNavigationBarHidden:wasNavigationBarHidden animated:NO];
	
	
	// resign from caring about any webview interactions
	self.adController.webView.delegate = nil;
	
	// tell the delegate that the webview would like to be closed
	// the delegate is responsible for tearing down the view, usually
	// with dismissModalViewController
	[self.delegate performSelector:@selector(interstitialDidClose:) withObject:self];
	
	if (_inNavigationController){
		[self.navigationController setNavigationBarHidden:NO animated:NO];
	}

}

- (void)adControllerDidReceiveResponseParams:(NSDictionary *)params{
	NSString *closeButtonChoice = [params objectForKey:@"X-Closebutton"];
	NSString *_backgroundColor = [params objectForKey:@"X-Backgroundcolor"];
	NSString *width = [params objectForKey:@"X-Width"];
	NSString *height = [params objectForKey:@"X-Height"];
	
	if (width && height)
		adSize = CGSizeMake([width floatValue], [height floatValue]);

	
	if (_backgroundColor){
		self.backgroundColor = [self colorForHex:_backgroundColor];
	}
	else {
		self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
	}

	
								 
								 
	
	if (closeButtonChoice == nil){
		closeButtonType = closeButtonType; // keep the same
	}
	else if ([closeButtonChoice isEqual: @"None"]){
		closeButtonType = AdCloseButtonTypeNone;
	}
	else if ([closeButtonChoice isEqual:@"Next"]){\
		closeButtonType = AdCloseButtonTypeNext;
	}
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSString* closeButtonChoice = [[(NSHTTPURLResponse*)response allHeaderFields] objectForKey:@"X-Closebutton"];
	
	if (closeButtonChoice == nil){
		closeButtonType = closeButtonType; // keep the same
	}
	else if ([closeButtonChoice isEqual: @"None"]){
		closeButtonType = AdCloseButtonTypeNone;
	}
	else if ([closeButtonChoice isEqual:@"Next"]){\
		closeButtonType = AdCloseButtonTypeNext;
	}
	// we can add other button types too, like a next arrow etc.
	[super connection:connection didReceiveResponse:response];
}
																		  
- (void)dealloc{
	[closeButton release];
	_adController.delegate = nil;
	[_adController release];
	[adUnitId release];
	[parent release];
	[backgroundColor release];
	[super dealloc];
}

- (UIColor *) colorForHex:(NSString *)hexColor {
	hexColor = [[hexColor stringByTrimmingCharactersInSet:
				 [NSCharacterSet whitespaceAndNewlineCharacterSet]
				 ] uppercaseString];  
	
    // String should be 6 or 7 characters if it includes '#'  
    if ([hexColor length] < 6) 
		return [UIColor blackColor];  
	
    // strip # if it appears  
    if ([hexColor hasPrefix:@"#"]) 
		hexColor = [hexColor substringFromIndex:1];  
	
    // if the value isn't 6 characters at this point return 
    // the color black	
    if ([hexColor length] != 6) 
		return [UIColor blackColor];  
	
    // Separate into r, g, b substrings  
    NSRange range;  
    range.location = 0;  
    range.length = 2; 
	
    NSString *rString = [hexColor substringWithRange:range];  
	
    range.location = 2;  
    NSString *gString = [hexColor substringWithRange:range];  
	
    range.location = 4;  
    NSString *bString = [hexColor substringWithRange:range];  
	
	
    // Scan values  
    unsigned int r, g, b;  
    [[NSScanner scannerWithString:rString] scanHexInt:&r];  
    [[NSScanner scannerWithString:gString] scanHexInt:&g];  
    [[NSScanner scannerWithString:bString] scanHexInt:&b];  

	
    return [UIColor colorWithRed:((float) r / 255.0f)  
                           green:((float) g / 255.0f)  
                            blue:((float) b / 255.0f)  
                           alpha:1.0f];  
	
}

# pragma
# pragma AdControllerDelegate Methods Passthroughs
# pragma

-(void)adControllerWillLoadAd:(AdController*)adController{
	if ([self.delegate respondsToSelector:@selector(adControllerWillLoadAd:)]){
		[self.delegate adControllerWillLoadAd:self.adController];
	}
}

-(void)adControllerDidLoadAd:(AdController*)adController{
	if ([self.delegate respondsToSelector:@selector(interstitialDidLoad:)]){
		[self.delegate interstitialDidLoad:self];
	}	
}

- (void)adControllerFailedLoadAd:(AdController*)adController{
	if ([self.delegate respondsToSelector:@selector(adControllerFailedLoadAd:)]){
		[self.delegate adControllerFailedLoadAd:self.adController];
	}
}

- (void)adControllerAdWillOpen:(AdController*)adController{
	if ([self.delegate respondsToSelector:@selector(adControllerAdWillOpen:)]){
		[self.delegate adControllerAdWillOpen:self.adController];
	}
	
}


- (void)willPresentModalViewForAd:(AdController*)adController{
	if ([self.delegate respondsToSelector:@selector(willPresentModalViewForAd:)]){
		[self.delegate willPresentModalViewForAd:self.adController];
	}
	
}

- (void)didPresentModalViewForAd:(AdController*)adController{
	if ([self.delegate respondsToSelector:@selector(didPresentModalViewForAd:)]){
		[self.delegate didPresentModalViewForAd:self.adController];
	}
	
}

- (void)willDismissModalViewForAd:(AdController*)adController{
	if ([self.delegate respondsToSelector:@selector(willDismissModalViewForAd:)]){
		[self.delegate willDismissModalViewForAd:self.adController];
	}
}

- (void)didDismissModalViewForAd:(AdController*)adController{
	if ([self.delegate respondsToSelector:@selector(didDismissModalViewForAd:)]){
		[self.delegate didDismissModalViewForAd:self.adController];
	}
	
}

- (void)applicationWillResign:(id)sender{
	if ([self.delegate respondsToSelector:@selector(applicationWillResign:)]){
		[self.delegate applicationWillResign:sender];
	}
	
}


@end

