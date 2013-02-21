//
//  InMobiBannerCustomEvent.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "InMobiBannerCustomEvent.h"
#import "MPConstants.h"

#define kInMobiAppID            @"YOUR_INMOBI_APP_ID"
#define INVALID_INMOBI_AD_SIZE  -1

@interface InMobiBannerCustomEvent ()

- (int)imAdSizeConstantForCGSize:(CGSize)size;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation InMobiBannerCustomEvent

#pragma mark - MPBannerCustomEvent Subclass Methods

- (void)requestAdWithSize:(CGSize)size customEventInfo:(NSDictionary *)info
{
    NSLog(@"Requesting InMobi banner.");
    
    UIViewController *rootViewController = [self.delegate viewControllerForPresentingModalView];
    
    int imAdSizeConstant = [self imAdSizeConstantForCGSize:size];
    if (imAdSizeConstant == INVALID_INMOBI_AD_SIZE) {
        NSLog(@"Failed to load InMobi banner: ad size %@ is not supported.",
              NSStringFromCGSize(size));
        [self.delegate bannerCustomEvent:self didFailToLoadAdWithError:nil];
    }
    
   _inmobiAdView = [[IMAdView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)
                                           imAppId:kInMobiAppID
                                          imAdSize:imAdSizeConstant
                                rootViewController:rootViewController];
    _inmobiAdView.delegate = self;
    _inmobiAdView.refreshInterval = REFRESH_INTERVAL_OFF;
    
    IMAdRequest *request = [IMAdRequest request];
    [_inmobiAdView loadIMAdRequest:request];
}

- (int)imAdSizeConstantForCGSize:(CGSize)size
{
    if (CGSizeEqualToSize(size, MOPUB_BANNER_SIZE)) {
        return IM_UNIT_320x50;
    } else if (CGSizeEqualToSize(size, MOPUB_MEDIUM_RECT_SIZE)) {
        return IM_UNIT_300x250;
    } else if (CGSizeEqualToSize(size, MOPUB_LEADERBOARD_SIZE)) {
        return IM_UNIT_728x90;
    } else {
        return INVALID_INMOBI_AD_SIZE;
    }
}

- (void)dealloc
{
    [_inmobiAdView setDelegate:nil];
    [_inmobiAdView release];
    
    [super dealloc];
}

#pragma mark - IMAdDelegate

- (void)adViewDidFinishRequest:(IMAdView *)adView
{
    NSLog(@"Successfully loaded InMobi banner.");
    
    [self.delegate bannerCustomEvent:self didLoadAd:adView];
}

- (void)adView:(IMAdView *)view didFailRequestWithError:(IMAdError *)error
{
    NSLog(@"Failed to load InMobi banner.");
    
    [self.delegate bannerCustomEvent:self didFailToLoadAdWithError:error];
}

- (void)adViewWillPresentScreen:(IMAdView *)adView
{
    NSLog(@"InMobi banner will present screen.");
    
    [self.delegate bannerCustomEventWillBeginAction:self];
}

- (void)adViewWillDismissScreen:(IMAdView *)adView
{
    NSLog(@"InMobi banner did dismiss screen.");
    
    [self.delegate bannerCustomEventDidFinishAction:self];
}

- (void)adViewWillLeaveApplication:(IMAdView *)adView
{
    NSLog(@"InMobi banner will leave application.");
    
    [self.delegate bannerCustomEventWillLeaveApplication:self];
}

@end
