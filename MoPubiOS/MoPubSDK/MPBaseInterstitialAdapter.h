//
//  MPBaseInterstitialAdapter.h
//  TestRotation
//
//  Created by Nafis Jamal on 4/27/11.
//  Copyright 2011 MoPub. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPInterstitialAdController;

@interface MPBaseInterstitialAdapter : NSObject {
	MPInterstitialAdController *_interstitialAdController;
}

@property (nonatomic, readonly) MPInterstitialAdController *interstitialAdController;

/*
 * Creates an adapter with a reference to an MPAdView.
 */
- (id)initWithInterstitialAdController:(MPInterstitialAdController *)interstitialAdController;

/*
 * Sets the adapter's delegate to nil.
 */
- (void)unregisterDelegate;

/*
 * -getAdWithParams: needs to be implemented by adapter subclasses that want to load native ads.
 * -getAd simply calls -getAdWithParams: with a nil dictionary.
 */
- (void)getAd;
- (void)getAdWithParams:(NSDictionary *)params;

/*
 * TODO: NEEDS COMMENT
 *
 */
- (void)showInterstitialFromViewController:(UIViewController *)rootViewController;

@end

@protocol MPBaseInterstitialAdapterDelegate
@required
/*
 * These callbacks notify you that the adapter (un)successfully loaded an ad.
 */
- (void)adapterDidFinishLoadingAd:(MPBaseInterstitialAdapter *)adapter;
- (void)adapter:(MPBaseInterstitialAdapter *)adapter didFailToLoadAdWithError:(NSError *)error;
- (void)interstitialWillAppearForAdapter:(MPBaseInterstitialAdapter *)adapter;
- (void)interstitialDidAppearForAdapter:(MPBaseInterstitialAdapter *)adapter;
- (void)interstitialWillDissappearForAdapter:(MPBaseInterstitialAdapter *)adapter;
- (void)interstitialDidDissappearForAdapter:(MPBaseInterstitialAdapter *)adapter;
@end
