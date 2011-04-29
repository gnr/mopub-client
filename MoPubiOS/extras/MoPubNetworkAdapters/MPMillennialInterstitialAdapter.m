//
//  MPMillennialInterstitialAdapter.m
//  TestRotation
//
//  Created by Nafis Jamal on 4/27/11.
//  Copyright 2011 MoPub. All rights reserved.
//

#import "MPMillennialInterstitialAdapter.h"
#import "MMAdView.h"
#import "CJSONDeserializer.h"

@implementation MPMillennialInterstitialAdapter

- (void)getAdWithParams:(NSDictionary *)params
{	
	NSData *headerData = [(NSString *)[params objectForKey:@"X-Nativeparams"] dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *headerParams = [[CJSONDeserializer deserializer] deserializeAsDictionary:headerData
																					 error:NULL];	
	mmInterstitialAdView = [[MMAdView interstitialWithType:MMFullScreenAdLaunch 
												   apid:[headerParams objectForKey:@"adUnitID"]
											   delegate:self
												 loadAd:YES]
							retain];
}


- (void)dealloc{
	mmInterstitialAdView.delegate = nil;
	[mmInterstitialAdView release];
	[super dealloc];
}

- (void)showInterstitialFromViewController:(UIViewController *)rootViewController
{
	//  no-op
}

# pragma mark - 
# pragma mark MMAdViewDelegate

- (NSDictionary *)requestData 
{
    return [NSDictionary dictionaryWithObjectsAndKeys:@"mopubsdk", @"vendor", nil];
}

- (void)adRequestSucceeded:(MMAdView *) adView
{
	[_interstitialAdController adapterDidFinishLoadingAd:self];
}

- (void)adRequestFailed:(MMAdView *) adView
{
	[_interstitialAdController adapter:self didFailToLoadAdWithError:nil];
}

- (void)adModalWillAppear
{
	[_interstitialAdController interstitialWillAppearForAdapter:self];
}

- (void)adModalDidAppear
{
	[_interstitialAdController interstitialDidAppearForAdapter:self];
}

- (void)adModalWasDismissed
{
	[_interstitialAdController interstitialDidDissappearForAdapter:self];
}



@end
