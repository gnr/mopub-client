//
//  MPAdMobAdapter.h
//  TestRotation
//
//  Created by Nafis Jamal on 4/26/11.
//  Copyright 2011 MoPub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GADInterstitial.h"
#import "MPBaseInterstitialAdapter.h"

@interface MPAdMobInterstitialAdapter : MPBaseInterstitialAdapter <GADInterstitialDelegate> 
{
	GADInterstitial *gAdInterstitial;
}

@end
