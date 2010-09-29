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
	BOOL wasNavigationBarHidden;
	
	UIButton *closeButton;
	AdCloseButtonType closeButtonType;
	BOOL _inNavigationController;
}

@property (nonatomic,retain) UIButton *closeButton;

+ (InterstitialAdController *)sharedInterstitialAdControllerForAdUnitId:(NSString *)a;
// if you are initing from the application delegate then you can say parentViewController = nil
- (id)initWithAdUnitId:(NSString *)p parentViewController:(UIViewController*)pvc;
- (void)makeCloseButton;

@end

@protocol InterstitialAdControllerDelegate <AdControllerDelegate>


// Sent when the interstitial would like to be removed from the screen, its up to the delegate to
// remove it
- (void)interstitialDidClose:(InterstitialAdController *)interstitialAdController;

@optional

// Sent with the interstitial is about to appear, it is a good place to save state in case
// the user leaves the application from the interstitial
- (void)interstitialWillAppear:(InterstitialAdController *)interstitialAdController;

// Sent when the interstitial is on screen
- (void)interstitialDidAppear:(InterstitialAdController *)interstitialAdController;




@end
