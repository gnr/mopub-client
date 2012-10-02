//
//  MPGoogleAdMobAdapter.h
//  MoPub
//
//  Created by Andrew He on 5/1/11.
//  Copyright 2011 MoPub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPBaseAdapter.h"
#import "GADBannerView.h"

/*
 * Compatible with version 6.2.0 of the Google AdMob Ads SDK.
 */

@interface MPGoogleAdMobAdapter : MPBaseAdapter <GADBannerViewDelegate>
{
	GADBannerView *_adBannerView;
}

@end
