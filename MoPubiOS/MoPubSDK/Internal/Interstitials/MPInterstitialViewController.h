//
//  MPInterstitialViewController.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    MPInterstitialCloseButtonStyleAlwaysVisible,
    MPInterstitialCloseButtonStyleAlwaysHidden,
    MPInterstitialCloseButtonStyleAdControlled
};
typedef NSUInteger MPInterstitialCloseButtonStyle;

enum {
    MPInterstitialOrientationTypePortrait,
    MPInterstitialOrientationTypeLandscape,
    MPInterstitialOrientationTypeAll
};
typedef NSUInteger MPInterstitialOrientationType;

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface MPInterstitialViewController : UIViewController
{
    MPInterstitialCloseButtonStyle _closeButtonStyle;
    UIButton *_closeButton;
    
    MPInterstitialOrientationType _orientationType;
    
    BOOL _applicationHasStatusBar;
    BOOL _isOnViewControllerStack;
}

@property (nonatomic, assign) MPInterstitialCloseButtonStyle closeButtonStyle;
@property (nonatomic, assign) MPInterstitialOrientationType orientationType;

- (void)presentInterstitialFromViewController:(UIViewController *)controller;
- (void)dismissInterstitialAnimated:(BOOL)animated;
- (BOOL)shouldDisplayCloseButton;
- (void)willPresentInterstitial;
- (void)didPresentInterstitial;
- (void)willDismissInterstitial;
- (void)didDismissInterstitial;
- (void)layoutCloseButton;

@end
