//
//  MPMillennialAdapter.m
//  MoPub
//
//  Created by Andrew He on 5/1/11.
//  Copyright 2011 MoPub, Inc. All rights reserved.
//

#import "MPMillennialAdapter.h"
#import "CJSONDeserializer.h"
#import "MPAdView.h"
#import "MPLogging.h"

#define MM_SIZE_320x53	CGSizeMake(320, 53)

@interface MPMillennialAdapter ()
@property (nonatomic, retain) MMAdView *mmAdView;
@end


@implementation MPMillennialAdapter
@synthesize mmAdView = _mmAdView;

- (void)dealloc
{
	_mmAdView.refreshTimerEnabled = NO;
	_mmAdView.delegate = nil;
	[_mmAdView release];
	[super dealloc];
}

- (void)getAdWithParams:(NSDictionary *)params
{
	NSData *hdrData = [(NSString *)[params objectForKey:@"X-Nativeparams"] 
					   dataUsingEncoding:NSUTF8StringEncoding];
	NSDictionary *hdrParams = [[CJSONDeserializer deserializer] deserializeAsDictionary:hdrData
																				  error:NULL];
	// Ensure proper tear-down of any existing MMAdView.
	// See: http://wiki.millennialmedia.com/index.php/Apple_SDK#adWithFrame
	self.mmAdView.refreshTimerEnabled = NO;
	self.mmAdView.delegate = nil;
	
	self.mmAdView = [MMAdView adWithFrame:CGRectMake(0.0, 0.0, MM_SIZE_320x53.width, MM_SIZE_320x53.height) 
									 type:MMBannerAdTop 
									 apid:[hdrParams objectForKey:@"adUnitID"] 
								 delegate:self
								   loadAd:NO
							   startTimer:NO];
	[_mmAdView refreshAd];
}

#pragma mark -
#pragma mark MMAdViewDelegate

- (NSDictionary *)requestData 
{
	return [NSDictionary dictionaryWithObjectsAndKeys:@"mopubsdk", @"vendor", nil];
}

- (void)adRequestSucceeded:(MMAdView *)adView
{
	NSLog(@"success");
	[self.adView setAdContentView:adView];
	[self.adView adapterDidFinishLoadingAd:self];
}

- (void)adRequestFailed:(MMAdView *)adView
{
	NSLog(@"fail");
	[self.adView adapter:self didFailToLoadAdWithError:nil];
}

- (void)adWasTapped:(MMAdView *)adView
{
	[self.adView userActionWillBeginForAdapter:self];
}

- (void)applicationWillTerminateFromAd
{
	[self.adView userWillLeaveApplicationFromAdapter:self];
}

- (void)adModalWasDismissed
{
	[self.adView userActionDidEndForAdapter:self];
}

@end
