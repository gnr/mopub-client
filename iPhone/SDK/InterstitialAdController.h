//
//  InterstitialAdController.h
//  SimpleAds
//
//  Created by Nafis Jamal on 9/21/10.
//  Copyright 2010 Stanford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AdController.h"

enum {
	AdCloseButtonTypeDefault,
	AdCloseButtonTypeNone,
	AdCloseButtonTypeNext,
};
typedef NSUInteger AdCloseButtonType;

@interface InterstitialAdController : AdController {
	BOOL wasStatusBarHidden;
	UIButton *closeButton;
	AdCloseButtonType closeButtonType;
	BOOL _inNavigationController;
}

@property (nonatomic,retain) UIButton *closeButton;

- (id)initWithPublisherId:(NSString *)p parentViewController:(UIViewController*)pvc;
- (void)makeCloseButton;

@end

@protocol InterstitialAdControllerDelegate

@optional

-(void)interstitialDidClose:(InterstitialAdController *)interstitialAdController;

@end
