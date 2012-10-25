//
//  GreystripeInterstitialCustomEvent.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPInterstitialCustomEvent.h"

#import "GSFullscreenAd.h"
#import "GSAdDelegate.h"

@interface GreystripeInterstitialCustomEvent : MPInterstitialCustomEvent <GSAdDelegate>
{
    GSFullscreenAd *_greystripeFullscreenAd;
}

@end
