//
//  MoPubCustomAdAdapter.m
//  SimpleAds
//
//  Created by Nafis Jamal on 10/25/10.
//  Copyright 2010 Stanford. All rights reserved.
//

#import "MoPubCustomAdAdapter.h"
#import "MoPubNativeSDKRegistry.h"
#import "AdController.h"

@implementation MoPubCustomAdAdapter

+ (NSString *)networkType{
	return @"custom";
}

+ (void)load {
	[[MoPubNativeSDKRegistry sharedRegistry] registerClass:self];
}

- (void)getAdWithParams:(NSDictionary *)params{	
	NSString *eventSelectorStr = [params objectForKey:@"X-Customsventstring"];
	SEL eventSelector = NSSelectorFromString(eventSelectorStr);
	if ([self.adController.delegate respondsToSelector:eventSelector]) {
		[self.adController.delegate performSelector:eventSelector];
	}
	else {
		NSString *eventSelectorColonStr = [NSString stringWithFormat:@"%@:", eventSelectorStr];
		SEL eventSelectorColon = NSSelectorFromString(eventSelectorColonStr);
		if ([self.adController.delegate respondsToSelector:eventSelectorColon]) {
			[self.adController.delegate performSelector:eventSelectorColon withObject:nil];
			[self.adController nativeAdLoadSucceededWithResults:nil];
		}
		else {
			NSLog(@"Delegate does not implement function %@ nor %@", eventSelectorStr, eventSelectorColonStr);
			[self.adController nativeAdLoadFailedwithError:nil];
		}
	}
}

- (void)dealloc{
	[super dealloc];
}

@end
