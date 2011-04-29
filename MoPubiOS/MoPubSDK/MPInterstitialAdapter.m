//
//  MPInterstitialAdapter.m
//  TestRotation
//
//  Created by Nafis Jamal on 4/26/11.
//  Copyright 2011 MoPub. All rights reserved.
//

#import "MPInterstitialAdapter.h"
#import "MPAdapterMap.h"

@implementation MPInterstitialAdapter

- (void)getAdWithParams:(NSDictionary *)params
{
	NSString *interstialAdapterString = [params objectForKey:@"X-Fulladtype"];
	NSString *classString = [[MPAdapterMap sharedAdapterMap] 
								classStringForAdapterType:interstialAdapterString];
	Class cls = NSClassFromString(classString);
	// fail fast if the adapter isn't present
	if (!cls)
	{
		[self.adView adapter:self didFailToLoadAdWithError:nil];
	}	
	else {
		// the real interstitial adapter will take over from here
	}

}


@end
