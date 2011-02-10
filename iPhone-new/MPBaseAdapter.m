//
//  MPBaseAdapter.m
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import "MPBaseAdapter.h"
#import "MPAdView.h"

@implementation MPBaseAdapter

@synthesize adView = _adView;

- (void)getAd
{
	[self getAdWithParams:nil];
}

- (void)getAdWithParams:(NSDictionary *)params
{
	// To be implemented by subclasses.
	[self doesNotRecognizeSelector:_cmd];
}

- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation
{
	// Do nothing by default. Subclasses can override.
	NSLog(@"MOPUB: rotateToOrientation %d called for adapter %@",
		  newOrientation, NSStringFromClass([self class]));
}

@end
