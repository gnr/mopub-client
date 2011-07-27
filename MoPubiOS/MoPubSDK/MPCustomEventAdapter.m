//
//  MPCustomEventAdapter.m
//  MoPub
//
//  Created by Andrew He on 2/9/11.
//  Copyright 2011 MoPub, Inc. All rights reserved.
//

#import "MPCustomEventAdapter.h"
#import "MPAdView.h"
#import "MPLogging.h"

@implementation MPCustomEventAdapter

- (void)getAdWithParams:(NSDictionary *)params
{
	NSString *selectorString = [params objectForKey:@"X-Customselector"];
	if (!selectorString)
	{
		MPLogError(@"Custom event requested, but no custom selector was provided.",
			  selectorString);
		[self.delegate adapter:self didFailToLoadAdWithError:nil];
	}

	SEL selector = NSSelectorFromString(selectorString);
	MPAdView *adView = [self.delegate adView];
	
	// First, try calling the no-object selector.
	if ([adView.delegate respondsToSelector:selector])
	{
		[adView.delegate performSelector:selector];
	}
	// Then, try calling the selector passing in the ad view.
	else 
	{
		NSString *selectorWithObjectString = [NSString stringWithFormat:@"%@:", selectorString];
		SEL selectorWithObject = NSSelectorFromString(selectorWithObjectString);
		
		if ([adView.delegate respondsToSelector:selectorWithObject])
		{
			[adView.delegate performSelector:selectorWithObject withObject:adView];
		}
		else
		{
			MPLogError(@"Ad view delegate does not implement custom event selectors %@ or %@.",
				  selectorString,
				  selectorWithObjectString);
			[self.delegate adapter:self didFailToLoadAdWithError:nil];
		}
	}

}

@end
