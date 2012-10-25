//
//  InMobiInterstitialCustomEvent.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "InMobiInterstitialCustomEvent.h"

#define kInMobiAppID    @"YOUR_INMOBI_APP_ID"

@implementation InMobiInterstitialCustomEvent

#pragma mark - MPInterstitialCustomEvent Subclass Methods

- (void)requestInterstitialWithCustomEventInfo:(NSDictionary *)info
{
    NSLog(@"Requesting InMobi interstitial.");
    
    _inmobiInterstitial = [[IMAdInterstitial alloc] init];
    _inmobiInterstitial.delegate = self;
    _inmobiInterstitial.imAppId = kInMobiAppID;
    
    IMAdRequest *request = [IMAdRequest request];
    [_inmobiInterstitial loadRequest:request];
}

- (void)showInterstitialFromRootViewController:(UIViewController *)rootViewController
{
    [_inmobiInterstitial presentFromRootViewController:rootViewController animated:YES];
}

- (void)dealloc
{
    [_inmobiInterstitial setDelegate:nil];
    [_inmobiInterstitial release];
    
    [super dealloc];
}

#pragma mark - IMAdInterstitialDelegate

- (void)interstitialDidFinishRequest:(IMAdInterstitial *)ad
{
    NSLog(@"Successfully loaded InMobi interstitial.");
    
    [self.delegate interstitialCustomEvent:self didLoadAd:ad];
}

- (void)interstitial:(IMAdInterstitial *)ad didFailToReceiveAdWithError:(IMAdError *)error
{
    NSLog(@"Failed to load InMobi interstitial.");
    
    [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:nil];
}

- (void)interstitialWillPresentScreen:(IMAdInterstitial *)ad
{
    NSLog(@"InMobi interstitial will be shown.");
    
    [self.delegate interstitialCustomEventWillAppear:self];
}

- (void)interstitial:(IMAdInterstitial *)ad didFailToPresentScreenWithError:(IMAdError *)error
{
    [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:nil];
}

- (void)interstitialDidDismissScreen:(IMAdInterstitial *)ad
{
    NSLog(@"InMobi interstitial was dismissed.");
    
    [self.delegate interstitialCustomEventDidDisappear:self];
}

@end
