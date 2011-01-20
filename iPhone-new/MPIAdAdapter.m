//
//  MPIAdAdapter.m
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import "MPIAdAdapter.h"


@implementation MPIAdAdapter

- (void)getAdWithParams:(NSDictionary *)params
{
	Class cls = NSClassFromString(@"ADBannerView");
	if (cls != nil) {
		CGSize size = self.delegate.frame.size;
		ADBannerView *adBannerView;
		adBannerView = [[cls alloc] initWithFrame:(CGRect){{0, 0}, size}];
		adBannerView.requiredContentSizeIdentifiers = [NSSet setWithObjects:ADBannerContentSizeIdentifier320x50, ADBannerContentSizeIdentifier480x32, nil];
		adBannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifier320x50;
		adBannerView.delegate = self;
		
		// put an AdBanner on top of the current view so it can 
		// do animations and Z ordering properly on click... 
		[self.delegate setAdContentView:adBannerView];
		[adBannerView release];
	} else {
		// iOS versions before 4 
		//[self bannerView:nil didFailToReceiveAdWithError:nil];
	}
}

@end
