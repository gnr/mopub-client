//
//  MPMillennialInterstitialAdapter.m
//  MoPub
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
	NSData *hdrData = [(NSString *)[params objectForKey:@"X-Nativeparams"] 
					   dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *hdrParams = [[CJSONDeserializer deserializer] deserializeAsDictionary:hdrData
																					 error:NULL];
	
	_mmInterstitialAdView = [[MMAdView interstitialWithType:MMFullScreenAdLaunch
													   apid:[hdrParams objectForKey:@"adUnitID"]
												   delegate:self
													 loadAd:YES] retain];
}

- (void)dealloc
{
	_mmInterstitialAdView.delegate = nil;
	[_mmInterstitialAdView release];
	[super dealloc];
}

- (void)showInterstitialFromViewController:(UIViewController *)controller
{
	// No-op: not supported.
}

# pragma mark - 
# pragma mark MMAdViewDelegate

- (NSDictionary *)requestData 
{
    return [NSDictionary dictionaryWithObjectsAndKeys:@"mopubsdk", @"vendor", nil];
}

- (void)adRequestSucceeded:(MMAdView *)adView
{
	[_interstitialAdController adapterDidFinishLoadingAd:self];
}

- (void)adRequestFailed:(MMAdView *)adView
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
	[_interstitialAdController interstitialWillDisappearForAdapter:self];
	[_interstitialAdController interstitialDidDisappearForAdapter:self];
}

@end
