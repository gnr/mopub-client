//
//  MPGoogleAdMobAdapter.m
//  MoPub
//
//  Created by Andrew He on 5/1/11.
//  Copyright 2011 MoPub, Inc. All rights reserved.
//

#import "MPGoogleAdMobAdapter.h"
#import "CJSONDeserializer.h"
#import "MPAdView.h"
#import "MPLogging.h"

@interface MPGoogleAdMobAdapter ()

- (void)setAdPropertiesFromNativeParams:(NSDictionary *)params;

@end


@implementation MPGoogleAdMobAdapter

- (id)initWithAdView:(MPAdView *)adView
{
	if (self = [super initWithAdView:adView])
	{
		CGRect frame = CGRectMake(0.0, 0.0, GAD_SIZE_320x50.width, GAD_SIZE_320x50.height);
		_adBannerView = [[GADBannerView alloc] initWithFrame:frame];
		_adBannerView.delegate = self;
	}
	return self;
}

- (void)dealloc
{
	_adBannerView.delegate = nil;
	[_adBannerView release];
	[super dealloc];
}

- (void)getAdWithParams:(NSDictionary *)params
{
	NSData *hdrData = [(NSString *)[params objectForKey:@"X-Nativeparams"] 
					   dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *hdrParams = [[CJSONDeserializer deserializer] deserializeAsDictionary:hdrData
																				  error:NULL];
	
	[self setAdPropertiesFromNativeParams:hdrParams];
	_adBannerView.rootViewController = [self.adView.delegate viewControllerForPresentingModalView];
	
	GADRequest *request = [GADRequest request];
	// Here, you can specify a list of devices that will receive test ads.
	// See: http://code.google.com/mobile/ads/docs/ios/intermediate.html#testdevices
	request.testDevices = [NSArray arrayWithObjects:
						   // GAD_SIMULATOR_ID, 
						   // more UDIDs here,
						   nil];
	
	[_adBannerView loadRequest:request];
}

- (void)setAdPropertiesFromNativeParams:(NSDictionary *)params
{
	CGFloat width = [(NSString *)[params objectForKey:@"adWidth"] floatValue];
	CGFloat height = [(NSString *)[params objectForKey:@"adHeight"] floatValue];
	_adBannerView.frame = CGRectMake(0, 0, width, height);
	_adBannerView.adUnitID = [params objectForKey:@"adUnitID"];
}

#pragma mark -
#pragma mark GADBannerViewDelegate methods

- (void)adViewDidReceiveAd:(GADBannerView *)bannerView
{
	[self.adView setAdContentView:bannerView];
	[self.adView adapterDidFinishLoadingAd:self shouldTrackImpression:YES];
}

- (void)adView:(GADBannerView *)bannerView
		didFailToReceiveAdWithError:(GADRequestError *)error
{
	[self.adView adapter:self didFailToLoadAdWithError:nil];
}

- (void)adViewWillPresentScreen:(GADBannerView *)bannerView
{
	[self.adView userActionWillBeginForAdapter:self];
}

- (void)adViewDidDismissScreen:(GADBannerView *)bannerView
{
	[self.adView userActionDidEndForAdapter:self];
}

- (void)adViewWillLeaveApplication:(GADBannerView *)bannerView
{
	[self.adView userWillLeaveApplicationFromAdapter:self];
}

@end
