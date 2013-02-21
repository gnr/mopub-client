//
//  GreystripeInterstitialCustomEvent.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "GreystripeInterstitialCustomEvent.h"

#define kGreystripeGUID @"YOUR_GREYSTRIPE_GUID"

@implementation GreystripeInterstitialCustomEvent

#pragma mark - MPInterstitialCustomEvent Subclass Methods

- (void)requestInterstitialWithCustomEventInfo:(NSDictionary *)info
{
    NSLog(@"Requesting Greystripe interstitial.");
    
    _greystripeFullscreenAd = [[GSFullscreenAd alloc] initWithDelegate:self
                                                                  GUID:kGreystripeGUID];
    [_greystripeFullscreenAd fetch];
}

- (void)showInterstitialFromRootViewController:(UIViewController *)rootViewController
{
    if ([_greystripeFullscreenAd isAdReady]) {
        [_greystripeFullscreenAd displayFromViewController:rootViewController];
    } else {
        NSLog(@"Failed to show Chartboost interstitial.");
        [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:nil];
    }
}

- (void)dealloc
{
    [_greystripeFullscreenAd setDelegate:nil];
    [_greystripeFullscreenAd release];
    
    [super dealloc];
}

#pragma mark - GSAdDelegate

- (void)greystripeAdFetchSucceeded:(id<GSAd>)a_ad
{
    NSLog(@"Successfully loaded Greystripe interstitial.");
    
    [self.delegate interstitialCustomEvent:self didLoadAd:a_ad];
}

- (void)greystripeAdFetchFailed:(id<GSAd>)a_ad withError:(GSAdError)a_error
{
    NSLog(@"Failed to load Greystripe interstitial.");
    
    [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:nil];
}

- (void)greystripeWillPresentModalViewController
{
    NSLog(@"Greystripe interstitial will be shown.");
    
    [self.delegate interstitialCustomEventWillAppear:self];
}

- (void)greystripeDidDismissModalViewController
{
    NSLog(@"Greystripe interstitial was dismissed.");
    
    [self.delegate interstitialCustomEventDidDisappear:self];
}

@end
