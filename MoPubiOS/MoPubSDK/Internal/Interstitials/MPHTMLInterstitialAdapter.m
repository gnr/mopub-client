//
//  MPHTMLInterstitialAdapter.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPHTMLInterstitialAdapter.h"

#import "MPAdConfiguration.h"
#import "MPInterstitialAdController.h"
#import "MPLogging.h"

@implementation MPHTMLInterstitialAdapter

- (void)getAdWithConfiguration:(MPAdConfiguration *)configuration
{
    MPLogTrace(@"Loading HTML interstitial with source: %@", [configuration adResponseHTMLString]);

    _interstitial = [[MPHTMLInterstitialViewController alloc] init];
    _interstitial.delegate = self;
    _interstitial.orientationType = configuration.orientationType;
    [_interstitial setCustomMethodDelegate:[self.interstitialAdController delegate]];
    [_interstitial loadConfiguration:configuration];
}

- (void)dealloc
{
    [_interstitial setDelegate:nil];
    [_interstitial setCustomMethodDelegate:nil];
    [_interstitial release];
    [super dealloc];
}

- (void)showInterstitialFromViewController:(UIViewController *)controller
{
    [_interstitial presentInterstitialFromViewController:controller];
}

#pragma mark - MPHTMLInterstitialViewControllerDelegate

- (void)interstitialDidLoadAd:(MPHTMLInterstitialViewController *)interstitial
{
    [self.manager adapterDidFinishLoadingAd:self];
}

- (void)interstitialDidFailToLoadAd:(MPHTMLInterstitialViewController *)interstitial
{
    [self.manager adapter:self didFailToLoadAdWithError:nil];
}

- (void)interstitialWillAppear:(MPHTMLInterstitialViewController *)interstitial
{
    [self.manager interstitialWillAppearForAdapter:self];
}

- (void)interstitialDidAppear:(MPHTMLInterstitialViewController *)interstitial
{
    [self.manager interstitialDidAppearForAdapter:self];
}

- (void)interstitialWillDisappear:(MPHTMLInterstitialViewController *)interstitial
{
    [self.manager interstitialWillDisappearForAdapter:self];
}

- (void)interstitialDidDisappear:(MPHTMLInterstitialViewController *)interstitial
{
    [self.manager interstitialDidDisappearForAdapter:self];
}

- (void)interstitialWasTapped:(MPHTMLInterstitialViewController *)interstitial
{
    [self.manager interstitialWasTappedForAdapter:self];
}

- (void)interstitialWillLeaveApplication:(MPHTMLInterstitialViewController *)interstitial
{
    [self.manager interstitialWillLeaveApplicationForAdapter:self];
}

@end
