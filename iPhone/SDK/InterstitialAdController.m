//
//  InterstitialAdController.m
//  SimpleAds
//
//  Created by Nafis Jamal on 9/21/10.
//  Copyright 2010 Stanford. All rights reserved.
//

#import "InterstitialAdController.h"

@implementation InterstitialAdController

@synthesize closeButton;


-(id)initWithPublisherId:(NSString *)p parentViewController:(UIViewController*)pvc{
	if (self = [super initWithFormat:AdControllerFormatFullScreen publisherId:p parentViewController:pvc]){
		_isInterstitial = YES;
		_inNavigationController = [pvc isKindOfClass:[UINavigationController class]];
		
		if (_inNavigationController) {
			closeButtonType = AdCloseButtonTypeNext;
		}
		else {
			closeButtonType = AdCloseButtonTypeDefault;
		}

	}
	return self;
}


- (void)loadView{
	[super loadView];
	
	// no-op if not in a navigation view
	[self.navigationController setNavigationBarHidden:YES animated:YES];
	// store that the state of the status bar
	wasStatusBarHidden = [UIApplication sharedApplication].statusBarHidden;
	// hide the status bar
	[UIApplication sharedApplication].statusBarHidden = YES;
	
	[self makeCloseButton];
}

- (void)makeCloseButton{
	// we add a close button to the top right corner of the screen
	if (closeButtonType == AdCloseButtonTypeDefault || closeButtonType == AdCloseButtonTypeNext){
		[self.closeButton removeFromSuperview];
		self.closeButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain]; 
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
		NSLog(@"%f,%f,%f,%f",closeButton.frame.origin.x,closeButton.frame.origin.y,closeButton.frame.size.width,closeButton.frame.size.height);
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
	// tell the webpage that the webview has been dismissed by the user
	// this is a good place to record time spent on site
	[self.webView stringByEvaluatingJavaScriptFromString:@"webviewDidClose();"]; 
	
	// return the state of the status bar
	[UIApplication sharedApplication].statusBarHidden = wasStatusBarHidden;
	// tell the delegate that the webview would like to be closed

	// resign from caring about any webview interactions
	self.webView.delegate = nil;
	//signal to the delegate to move on
	[(NSObject *)self.delegate performSelector:@selector(interstitialDidClose:) withObject:self];


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
//	[self makeCloseButton];
	[super connection:connection didReceiveResponse:response];
}
																		  
- (void)dealloc{
	[closeButton release];
	[super dealloc];
}

@end

