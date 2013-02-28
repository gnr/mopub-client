//
//  ChartboostInterstitialCustomEvent.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "ChartboostInterstitialCustomEvent.h"

#define kChartboostAppID        @"YOUR_CHARTBOOST_APP_ID"
#define kChartboostAppSignature @"YOUR_CHARTBOOST_APP_SIGNATURE"

@implementation ChartboostInterstitialCustomEvent

#pragma mark - MPInterstitialCustomEvent Subclass Methods

- (void)requestInterstitialWithCustomEventInfo:(NSDictionary *)info
{
    NSLog(@"Requesting Chartboost interstitial.");
    
    Chartboost *cb = [Chartboost sharedChartboost];
    cb.appId = kChartboostAppID;
    cb.appSignature = kChartboostAppSignature;
    cb.delegate = self;
    
    [cb startSession];
    [cb cacheInterstitial];
}

- (void)showInterstitialFromRootViewController:(UIViewController *)rootViewController
{
    Chartboost *cb = [Chartboost sharedChartboost];
    
    if ([cb hasCachedInterstitial]) {
        NSLog(@"Chartboost interstitial will be shown.");
        
        // Normally, we would call this method when a callback notifies us that an ad is about to be
        // presented. Chartboost doesn't seem to have such a callback, so we'll call this method
        // right before we show the ad.
        [self.delegate interstitialCustomEventWillAppear:self];
        
        [cb showInterstitial];
    } else {
        NSLog(@"Failed to show Chartboost interstitial.");
        [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:nil];
    }
}

- (void)dealloc
{
    Chartboost *cb = [Chartboost sharedChartboost];

    // Don't set the delegate to nil unless we are the delegate, because another instance of
    // this custom class could be active (which would make it the active delegate instead). Note:
    // this check is only necessary because the Chartboost object is a shared instance.
    if (cb.delegate == self) {
        cb.delegate = nil;
    }
    
    [super dealloc];
}

#pragma mark - ChartboostDelegate

- (void)didCacheInterstitial:(NSString *)location
{
    NSLog(@"Successfully loaded Chartboost interstitial.");
    
    [self.delegate interstitialCustomEvent:self didLoadAd:[Chartboost sharedChartboost]];
}

- (void)didFailToLoadInterstitial:(NSString *)location
{
    NSLog(@"Failed to load Chartboost interstitial.");
    
    [self.delegate interstitialCustomEvent:self didFailToLoadAdWithError:nil];
}

- (void)didDismissInterstitial:(NSString *)location
{
    NSLog(@"Chartboost interstitial was dismissed.");
    
    [self.delegate interstitialCustomEventDidDisappear:self];
}

@end
