//
//  GreystripeBannerCustomEvent.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "GreystripeBannerCustomEvent.h"
#import "MPConstants.h"

#define kGreystripeGUID @"YOUR_GREYSTRIPE_GUID"

@implementation GreystripeBannerCustomEvent

#pragma mark - MPBannerCustomEvent Subclass Methods

- (void)requestAdWithSize:(CGSize)size customEventInfo:(NSDictionary *)info
{
    NSLog(@"Requesting Greystripe banner.");
    
    if (CGSizeEqualToSize(size, MOPUB_BANNER_SIZE)) {
        _greystripeBannerAdView = [[GSMobileBannerAdView alloc] initWithDelegate:self
                                                                            GUID:kGreystripeGUID
                                                                        autoload:NO];
    } else if (CGSizeEqualToSize(size, MOPUB_MEDIUM_RECT_SIZE)) {
        _greystripeBannerAdView = [[GSMediumRectangleAdView alloc] initWithDelegate:self
                                                                               GUID:kGreystripeGUID
                                                                           autoload:NO];
    } else if (CGSizeEqualToSize(size, MOPUB_LEADERBOARD_SIZE)) {
        _greystripeBannerAdView = [[GSLeaderboardAdView alloc] initWithDelegate:self
                                                                           GUID:kGreystripeGUID
                                                                       autoload:NO];
    } else {
        NSLog(@"Failed to load Greystripe banner: ad size %@ is not supported.",
              NSStringFromCGSize(size));
        [self.delegate bannerCustomEvent:self didFailToLoadAdWithError:nil];
    }
    
    [_greystripeBannerAdView fetch];
}

- (UIViewController *)greystripeBannerDisplayViewController
{
    return [self.delegate viewControllerForPresentingModalView];
}

- (void)dealloc
{
    _greystripeBannerAdView.delegate = nil;
    [_greystripeBannerAdView release];
    
    [super dealloc];
}

#pragma mark - GSAdDelegate

- (void)greystripeAdFetchSucceeded:(id<GSAd>)a_ad
{
    NSLog(@"Successfully loaded Greystripe banner.");
    
    [self.delegate bannerCustomEvent:self didLoadAd:_greystripeBannerAdView];
}

- (void)greystripeAdFetchFailed:(id<GSAd>)a_ad withError:(GSAdError)a_error
{
    NSLog(@"Failed to load Greystripe banner.");
    
    [self.delegate bannerCustomEvent:self didFailToLoadAdWithError:nil];
}

- (void)greystripeWillPresentModalViewController
{
    NSLog(@"Greystripe banner will present screen.");
    
    [self.delegate bannerCustomEventWillBeginAction:self];
}

- (void)greystripeDidDismissModalViewController
{
    NSLog(@"Greystripe banner did dismiss screen.");
    
    [self.delegate bannerCustomEventDidFinishAction:self];
}

@end
