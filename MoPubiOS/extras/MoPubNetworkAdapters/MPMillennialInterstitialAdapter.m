//
//  MPMillennialInterstitialAdapter.m
//  MoPub
//
//  Created by Nafis Jamal on 4/27/11.
//  Copyright 2011 MoPub. All rights reserved.
//

#import "MPMillennialInterstitialAdapter.h"
#import "MPInterstitialAdController.h"
#import "MMAdView.h"
#import "MPLogging.h"
#import "CJSONDeserializer.h"

@interface MPMillennialInterstitialAdapter ()

+ (MMAdView *)sharedMMAdViewForAPID:(NSString *)apid;
- (void)releaseMMAdViewSafely;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MPMillennialInterstitialAdapter

+ (MMAdView *)sharedMMAdViewForAPID:(NSString *)apid
{
	static NSMutableDictionary *sharedMMAdViews;
	
	if ([apid length] == 0)
	{
		MPLogWarn(@"Failed to create a Millennial interstitial. Have you set a Millennial "
				  @"publisher ID in your MoPub dashboard?");
		return nil;
	}
	
	@synchronized(self)
	{
		if (!sharedMMAdViews) sharedMMAdViews = [[NSMutableDictionary dictionary] retain];
		
		MMAdView *adView = [sharedMMAdViews objectForKey:apid];
		if (!adView)
		{
			adView = [MMAdView interstitialWithType:MMFullScreenAdTransition
											   apid:apid
										   delegate:self
											 loadAd:NO];
			[sharedMMAdViews setObject:adView forKey:apid];
		}
		
		return adView;
	}
}

- (void)getAdWithParams:(NSDictionary *)params
{	
	NSData *hdrData = [(NSString *)[params objectForKey:@"X-Nativeparams"] 
					   dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *hdrParams = [[CJSONDeserializer deserializer] deserializeAsDictionary:hdrData
																					 error:NULL];
	NSString *apid = [hdrParams objectForKey:@"adUnitID"];
	
	_mmInterstitialAdView = [[[self class] sharedMMAdViewForAPID:apid] retain];
	
	if (!_mmInterstitialAdView) {
		[_interstitialAdController adapter:self didFailToLoadAdWithError:nil];
		return;
	}
		
	[_mmInterstitialAdView setDelegate:self];
	[_mmInterstitialAdView refreshAd];
}

- (void)dealloc
{
	[self releaseMMAdViewSafely];
	[super dealloc];
}

- (void)releaseMMAdViewSafely
{
	if (_mmInterstitialAdView.delegate == self) _mmInterstitialAdView.delegate = nil;
	[_mmInterstitialAdView release]; _mmInterstitialAdView = nil;
}

- (void)showInterstitialFromViewController:(UIViewController *)controller
{
	// No-op: not supported.
}

# pragma mark - 
# pragma mark MMAdDelegate

- (NSDictionary *)requestData 
{
	NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								   @"mopubsdk", @"vendor", nil];
	
	NSArray *locationPair = [self.interstitialAdController locationDescriptionPair];
	if ([locationPair count] == 2) {
		[params setObject:[locationPair objectAtIndex:0] forKey:@"lat"];
		[params setObject:[locationPair objectAtIndex:1] forKey:@"lon"];
	}
	
	return params;
}

- (void)adRequestSucceeded:(MMAdView *)adView
{
	[_interstitialAdController adapterDidFinishLoadingAd:self];
}

- (void)adRequestFailed:(MMAdView *)adView
{
	[_interstitialAdController adapter:self didFailToLoadAdWithError:nil];
}

- (void)adRequestIsCaching:(MMAdView *)adView
{
	MPLogInfo(@"Millennial ad request is currently caching -- try showing it again later.");
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
