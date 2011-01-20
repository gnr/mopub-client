//
//  MPBaseAdapter.m
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import "MPBaseAdapter.h"


@implementation MPBaseAdapter

@synthesize delegate = _delegate;

- (void)getAd
{
	[self getAdWithParams:nil];
}

- (void)getAdWithParams:(NSDictionary *)params
{
	// To be implemented by subclasses.
}

@end
