//
//  MPHTMLInterstitialViewController.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MPAdWebView.h"
#import "MPInterstitialViewController.h"

////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol MPHTMLInterstitialViewControllerDelegate;
@class MPAdConfiguration;

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface MPHTMLInterstitialViewController : MPInterstitialViewController <MPAdWebViewDelegate>
{
    id<MPHTMLInterstitialViewControllerDelegate> _delegate;
    MPAdWebView *_interstitialView;
}

@property (nonatomic, assign) id<MPHTMLInterstitialViewControllerDelegate> delegate;

- (id)customMethodDelegate;
- (void)setCustomMethodDelegate:(id)delegate;
- (void)loadConfiguration:(MPAdConfiguration *)configuration;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol MPHTMLInterstitialViewControllerDelegate <NSObject>

- (void)interstitialDidLoadAd:(MPHTMLInterstitialViewController *)interstitial;
- (void)interstitialDidFailToLoadAd:(MPHTMLInterstitialViewController *)interstitial;
- (void)interstitialWillAppear:(MPHTMLInterstitialViewController *)interstitial;
- (void)interstitialDidAppear:(MPHTMLInterstitialViewController *)interstitial;
- (void)interstitialWillDisappear:(MPHTMLInterstitialViewController *)interstitial;
- (void)interstitialDidDisappear:(MPHTMLInterstitialViewController *)interstitial;
- (void)interstitialWasTapped:(MPHTMLInterstitialViewController *)interstitial;
- (void)interstitialWillLeaveApplication:(MPHTMLInterstitialViewController *)interstitial;

@end