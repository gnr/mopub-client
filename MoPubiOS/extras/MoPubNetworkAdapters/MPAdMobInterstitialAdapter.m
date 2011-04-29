//
//  MPAdMobAdapter.m
//  TestRotation
//
//  Created by Nafis Jamal on 4/26/11.
//  Copyright 2011 MoPub. All rights reserved.
//

#import "MPAdMobInterstitialAdapter.h"
#import "CJSONDeserializer.h"
#import "MPInterstitialAdController.h"
#import "MPLogging.h"

@implementation MPAdMobInterstitialAdapter

- (void)getAdWithParams:(NSDictionary *)params
{	
	NSData *headerData = [(NSString *)[params objectForKey:@"X-Nativeparams"] dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *headerParams = [[CJSONDeserializer deserializer] deserializeAsDictionary:headerData
																					 error:NULL];	
	gAdInterstitial = [[GADInterstitial alloc] init];
	gAdInterstitial.adUnitID = [headerParams objectForKey:@"adUnitID"];
	gAdInterstitial.delegate = self;
	GADRequest *request = [GADRequest request];
	request.testing = YES;
	[gAdInterstitial loadRequest:request];
}

- (void)interstitialDidReceiveAd:(GADInterstitial *)interstitial{
	[_interstitialAdController adapterDidFinishLoadingAd:self];
}

- (void)interstitial:(GADInterstitial *)interstitial didFailToReceiveAdWithError:(GADRequestError *)error{
	[_interstitialAdController adapter:self didFailToLoadAdWithError:error];
}

- (void)showInterstitialFromViewController:(UIViewController *)rootViewController
{
	[gAdInterstitial presentFromRootViewController:rootViewController];
}
	

- (void)interstitialWillPresentScreen:(GADInterstitial *)interstitial
{
	[_interstitialAdController interstitialWillAppearForAdapter:self];
}

- (void)interstitialWillDismissScreen:(GADInterstitial *)ad
{
	[_interstitialAdController interstitialWillDissappearForAdapter:self];
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)ad
{
	[_interstitialAdController interstitialDidDissappearForAdapter:self];
}

- (void)dealloc{
	gAdInterstitial.delegate = nil;
	[gAdInterstitial release];
	[super dealloc];
}

@end
