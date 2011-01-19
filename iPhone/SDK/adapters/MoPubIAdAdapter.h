//
//  MoPubIAdAdapter.h
//  SimpleAds
//
//  Created by Nafis Jamal on 10/25/10.
//  Copyright 2010 Stanford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MoPubNativeSDKAdapter.h"
#import "MoPubNativeSDKRegistry.h"

#import <iAd/iAd.h>

@interface MoPubIAdAdapter : MoPubNativeSDKAdapter <ADBannerViewDelegate> {
	ADBannerView *adBannerView;
}

@property (nonatomic,retain) ADBannerView *adView;

+ (NSString *)networkType;

@end

