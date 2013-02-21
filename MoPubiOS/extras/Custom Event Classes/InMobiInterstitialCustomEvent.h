//
//  InMobiInterstitialCustomEvent.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPInterstitialCustomEvent.h"

#import "IMAdInterstitial.h"
#import "IMAdInterstitialDelegate.h"

@interface InMobiInterstitialCustomEvent : MPInterstitialCustomEvent <IMAdInterstitialDelegate>
{
    IMAdInterstitial *_inmobiInterstitial;
}

@end
