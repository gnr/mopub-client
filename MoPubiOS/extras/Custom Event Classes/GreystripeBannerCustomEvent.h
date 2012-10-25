//
//  GreystripeBannerCustomEvent.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPBannerCustomEvent.h"
#import "GSMobileBannerAdView.h"
#import "GSMediumRectangleAdView.h"
#import "GSLeaderboardAdView.h"
#import "GSAdDelegate.h"

@interface GreystripeBannerCustomEvent : MPBannerCustomEvent <GSAdDelegate>
{
    GSBannerAdView *_greystripeBannerAdView;
}

@end
