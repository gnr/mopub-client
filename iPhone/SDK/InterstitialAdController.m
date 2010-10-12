//
//  InterstitialAdController.m
//  Copyright (c) 2010 MoPub Inc.
//
//  Created by Nafis Jamal on 9/21/10.
//

#import "InterstitialAdController.h"

@implementation InterstitialAdController

@synthesize closeButton;


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
	if (self = [super initWithSize:[[UIScreen mainScreen] bounds].size adUnitId:a parentViewController:pvc])
	{
		_isInterstitial = YES;
		self.parent = pvc;
	}
	return self;
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

- (void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	if ([self.delegate respondsToSelector:@selector(interstitialWillAppear:)]){
		[self.delegate performSelector:@selector(interstitialWillAppear:) withObject:self];
	}
}

- (void)viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
	if ([self.delegate respondsToSelector:@selector(interstitialDidAppear:)]){
		[self.delegate performSelector:@selector(interstitialDidAppear:) withObject:self];
	}
}
		
- (void)viewDidLoad{
	[super viewDidLoad];
	[self makeCloseButton];

}

- (void)loadView{
	[super loadView];
	
	// no-op if not in a navigation view
	wasNavigationBarHidden = self.navigationController.navigationBarHidden;
	// hide the navigation bar
	[self.navigationController setNavigationBarHidden:YES animated:NO];
		
	// store that the state of the status bar
	wasStatusBarHidden = [UIApplication sharedApplication].statusBarHidden;
	// hide the status bar
	[UIApplication sharedApplication].statusBarHidden = YES;
	
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
		closeButton.frame = CGRectMake(320-closeButton.frame.size.width-10.0, 10.0, closeButton.frame.size.width, closeButton.frame.size.height);
		[closeButton addTarget:self action:@selector(didSelectClose:) forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:closeButton];
		[self.view bringSubviewToFront:closeButton];
	}
	else if (closeButtonType == AdCloseButtonTypeNone){
		// remove the close button if it was already there
		[closeButton removeFromSuperview];
	}
	
}

- (void)didSelectClose:(id)sender{
	[super didSelectClose:sender];
	
	// return the state of the status bar
	[UIApplication sharedApplication].statusBarHidden = wasStatusBarHidden;
	// return the state of the navigation bar
	[self.navigationController setNavigationBarHidden:wasNavigationBarHidden animated:NO];
	
	// tell the delegate that the webview would like to be closed

	// resign from caring about any webview interactions
	self.webView.delegate = nil;
	
	//signal to the delegate to move on
	[self.delegate performSelector:@selector(interstitialDidClose:) withObject:self];
	
	if (_inNavigationController){
		[self.navigationController setNavigationBarHidden:NO animated:NO];
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
	[super dealloc];
}

@end

