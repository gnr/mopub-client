//
//  InterstitialAdController.m
//  SimpleAds
//
//  Created by Nafis Jamal on 9/21/10.
//  Copyright 2010 Stanford. All rights reserved.
//

#import "InterstitialAdController.h"

@implementation InterstitialAdController

-(id)initWithPublisherId:(NSString *)p parentViewController:(UIViewController*)pvc {
	if (self = [super initWithFormat:AdControllerFormatFullScreen publisherId:p parentViewController:pvc]){
		
	}
	return self;
}


- (void)loadView{
	[super loadView];
	
	// we add a close button to the top right corner of the screen
	UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	UIImage *closeButtonImage = [UIImage imageNamed:@"moPubCloseButton.png"];
	[closeButton setImage:closeButtonImage forState:UIControlStateNormal];
	[closeButton sizeToFit];
	closeButton.frame = CGRectMake(320-closeButton.frame.size.width-10.0, 10.0, closeButton.frame.size.width, closeButton.frame.size.height);
	[closeButton addTarget:self action:@selector(didSelectClose:) forControlEvents:UIControlEventTouchUpInside];
	
	[self.view addSubview:closeButton];
}

- (void)didSelectClose:(id)sender{
	// tell the webpage that the webview has been dismissed by the user
	// this is a good place to record time spent on site
	[self.webView stringByEvaluatingJavaScriptFromString:@"webviewDidClose();"]; 

	// tell the delegate that the webview would like to be closed
	[(NSObject *)self.delegate performSelector:@selector(interstitialDidClose:) withObject:self];
}

																		  
- (void)dealloc{
	[super dealloc];
}

@end

