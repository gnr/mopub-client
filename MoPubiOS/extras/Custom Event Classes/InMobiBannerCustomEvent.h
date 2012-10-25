//
//  InMobiBannerCustomEvent.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPBannerCustomEvent.h"
#import "IMAdView.h"

@interface InMobiBannerCustomEvent : MPBannerCustomEvent <IMAdDelegate>
{
    IMAdView *_inmobiAdView;
}

@end
