//
//  MPInterstitialAdManager+DeprecatedCustomEvents.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPInterstitialAdManager+DeprecatedCustomEvents.h"

#import "MPLogging.h"

@implementation MPInterstitialAdManager (DeprecatedCustomEvents)

- (void)customEventDidLoadAd
{
    if (![self isHandlingCustomEvent]) {
        MPLogWarn(@"-customEventDidLoadAd should not be called unless a custom event is in "
                  @"progress.");
        return;
    }
    
    _isReady = NO;
    _loading = NO;
    _hasRecordedImpressionForCurrentInterstitial = NO;
    _hasRecordedClickForCurrentInterstitial = NO;
    
    [_currentAdapter unregisterDelegate];
    [_currentAdapter release];
    _currentAdapter = _nextAdapter;
    _nextAdapter = nil;
    
    _currentConfiguration = _nextConfiguration;
    _nextConfiguration = nil;
    
    // XXX: The deprecated custom event behavior is to report an impression as soon as an ad loads,
    // rather than when the ad is actually displayed. Because of this, you may see impression-
    // reporting discrepancies between MoPub and your custom ad networks.
    [self reportImpressionForCurrentInterstitial];
}

- (void)customEventDidFailToLoadAd
{
    if (![self isHandlingCustomEvent]) {
        MPLogWarn(@"-customEventDidFailToLoadAd should not be called unless a custom event is in "
                  @"progress.");
        return;
    }
    
    [self adapter:_nextAdapter didFailToLoadAdWithError:nil];
}

- (void)customEventActionWillBegin
{
    if (![self isHandlingCustomEvent]) {
        MPLogWarn(@"-customEventActionWillBegin should not be called unless a custom event is in "
                  @"progress.");
        return;
    }
    
    [self reportClickForCurrentInterstitial];
}

@end
