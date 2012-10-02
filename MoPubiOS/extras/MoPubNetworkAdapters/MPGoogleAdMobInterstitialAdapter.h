//
//  MPGoogleAdMobInterstitialAdapter.h
//  MoPub
//
//  Created by Nafis Jamal on 4/26/11.
//  Copyright 2011 MoPub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GADInterstitial.h"
#import "MPBaseInterstitialAdapter.h"

/*
 * Compatible with version 6.2.0 of the Google AdMob Ads SDK.
 */

@interface MPGoogleAdMobInterstitialAdapter : MPBaseInterstitialAdapter <GADInterstitialDelegate> 
{
	GADInterstitial *_gAdInterstitial;
}

@end
