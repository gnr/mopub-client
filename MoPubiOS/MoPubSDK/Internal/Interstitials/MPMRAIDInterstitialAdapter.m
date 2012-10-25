//
//  MPMraidInterstitialAdapter.m
//  MoPub
//
//  Created by Andrew He on 12/11/11.
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPMraidInterstitialAdapter.h"

#import "MPAdConfiguration.h"
#import "MPInterstitialAdController.h"
#import "MPInterstitialAdManager.h"
#import "MPLogging.h"

@implementation MPMRAIDInterstitialAdapter

- (void)getAdWithConfiguration:(MPAdConfiguration *)configuration
{
    _interstitial = [[MPMRAIDInterstitialViewController alloc]
                     initWithAdConfiguration:configuration];
    _interstitial.delegate = self;
    [_interstitial setCloseButtonStyle:MPInterstitialCloseButtonStyleAdControlled];
    [_interstitial startLoading];
}

- (void)dealloc
{
    _interstitial.delegate = nil;
    [_interstitial release];
    
    [super dealloc];
}

- (void)showInterstitialFromViewController:(UIViewController *)controller
{
    [_interstitial presentInterstitialFromViewController:controller];
}

#pragma mark - MPMRAIDInterstitialViewControllerDelegate

- (void)interstitialDidLoadAd:(MPMRAIDInterstitialViewController *)interstitial
{
    [self.manager adapterDidFinishLoadingAd:self];
}

- (void)interstitialDidFailToLoadAd:(MPMRAIDInterstitialViewController *)interstitial
{
    [self.manager adapter:self didFailToLoadAdWithError:nil];
}

- (void)interstitialWillAppear:(MPMRAIDInterstitialViewController *)interstitial
{
    [self.manager interstitialWillAppearForAdapter:self];
}

- (void)interstitialDidAppear:(MPMRAIDInterstitialViewController *)interstitial
{
    [self.manager interstitialDidAppearForAdapter:self];
}

- (void)interstitialWillDisappear:(MPMRAIDInterstitialViewController *)interstitial
{
    [self.manager interstitialWillDisappearForAdapter:self];
}

- (void)interstitialDidDisappear:(MPMRAIDInterstitialViewController *)interstitial
{
    [self.manager interstitialDidDisappearForAdapter:self];
}

// TODO: Tapped callback.

@end
