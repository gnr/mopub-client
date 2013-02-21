//
//  MPInterstitialAdManager+DeprecatedCustomEvents.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPInterstitialAdManager.h"

@interface MPInterstitialAdManager (DeprecatedCustomEvents)

- (void)customEventDidLoadAd;
- (void)customEventDidFailToLoadAd;
- (void)customEventActionWillBegin;

@end
