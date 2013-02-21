//
//  MPBaseInterstitialAdapter.h
//  MoPub
//
//  Created by Nafis Jamal on 4/27/11.
//  Copyright 2011 MoPub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class MPInterstitialAdController;
@class MPInterstitialAdManager;
@class MPAdConfiguration;

@interface MPBaseInterstitialAdapter : NSObject 
{
	MPInterstitialAdController *_interstitialAdController;
    MPInterstitialAdManager *_manager;
}

@property (nonatomic, readonly) MPInterstitialAdController *interstitialAdController;
@property (nonatomic, assign) MPInterstitialAdManager *manager;

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
- (void)_getAdWithParams:(NSDictionary *)params;

- (void)getAdWithConfiguration:(MPAdConfiguration *)configuration;
- (void)_getAdWithConfiguration:(MPAdConfiguration *)configuration;

/*
 * Presents the interstitial from the specified view controller.
 */
- (void)showInterstitialFromViewController:(UIViewController *)controller;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol MPBaseInterstitialAdapterDelegate

@required
/*
 * These callbacks notify you that the adapter (un)successfully loaded an ad.
 */
- (void)adapterDidFinishLoadingAd:(MPBaseInterstitialAdapter *)adapter;
- (void)adapter:(MPBaseInterstitialAdapter *)adapter didFailToLoadAdWithError:(NSError *)error;

/*
 *
 */
- (void)interstitialWillAppearForAdapter:(MPBaseInterstitialAdapter *)adapter;
- (void)interstitialDidAppearForAdapter:(MPBaseInterstitialAdapter *)adapter;
- (void)interstitialWillDisappearForAdapter:(MPBaseInterstitialAdapter *)adapter;
- (void)interstitialDidDisappearForAdapter:(MPBaseInterstitialAdapter *)adapter;

- (void)interstitialWasTappedForAdapter:(MPBaseInterstitialAdapter *)adapter;
- (void)interstitialDidExpireForAdapter:(MPBaseInterstitialAdapter *)adapter;

- (void)interstitialWillLeaveApplicationForAdapter:(MPBaseInterstitialAdapter *)adapter;

@end
