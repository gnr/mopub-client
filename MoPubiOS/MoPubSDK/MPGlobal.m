//
//  MPGlobal.m
//  SimpleAds
//
//  Created by Andrew He on 5/5/11.
//  Copyright 2011 MoPub, Inc. All rights reserved.
//

#import "MPGlobal.h"

CGRect MPScreenBounds()
{
	CGRect bounds = [UIScreen mainScreen].bounds;
	
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (UIInterfaceOrientationIsLandscape(orientation))
	{
		CGFloat width = bounds.size.width;
		bounds.size.width = bounds.size.height;
		bounds.size.height = width;
	}
	
	return bounds;
}
