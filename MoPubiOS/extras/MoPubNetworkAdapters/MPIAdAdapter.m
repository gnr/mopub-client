//
//  MPIAdAdapter.m
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 MoPub, Inc. All rights reserved.
//

#import "MPIAdAdapter.h"
#import "MPAdView.h"
#import "MPLogging.h"

@interface MPIAdAdapter ()
+ (ADBannerView *)sharedAdBannerView;
- (void)releaseBannerViewDelegateSafely;
- (void)setBannerViewContentSizeIdentifierForOrientation:(UIInterfaceOrientation)orientation;
@end

@implementation MPIAdAdapter

+ (ADBannerView *)sharedAdBannerView
{
	static ADBannerView *sharedAdBannerView;
	
	@synchronized(self)
	{
		if (!sharedAdBannerView)
		{
			sharedAdBannerView = [[ADBannerView alloc] initWithFrame:CGRectZero];
		}
	}
	return sharedAdBannerView;
}

- (void)dealloc
{
	[self releaseBannerViewDelegateSafely];
	[super dealloc];
}

- (void)releaseBannerViewDelegateSafely
{
	if (_adBannerView.delegate == self) _adBannerView.delegate = nil;
	[_adBannerView release];
}

- (void)getAdWithParams:(NSDictionary *)params
{
	Class cls = NSClassFromString(@"ADBannerView");
	if (cls != nil) 
	{
		if (_adBannerView) [self releaseBannerViewDelegateSafely];
		
		_adBannerView = [[MPIAdAdapter sharedAdBannerView] retain];
		
		CGSize size = self.adView.bounds.size;
		_adBannerView.frame = (CGRect){{0, 0}, size};
		_adBannerView.delegate = self;

		MPNativeAdOrientation allowedOrientation = [self.adView allowedNativeAdsOrientation];
		UIInterfaceOrientation currentOrientation = 
			[UIApplication sharedApplication].statusBarOrientation;
		switch (allowedOrientation)
		{
			case MPNativeAdOrientationPortrait:
				[self setBannerViewContentSizeIdentifierForOrientation:
					UIInterfaceOrientationPortrait];
				break;
			case MPNativeAdOrientationLandscape:
				[self setBannerViewContentSizeIdentifierForOrientation:
					UIInterfaceOrientationLandscapeLeft];
				break;
			default:
				[self setBannerViewContentSizeIdentifierForOrientation:currentOrientation];
				break;
		}
		
		if ([_adBannerView isBannerLoaded])
		{
			MPLogInfo(@"iAd banner has previously loaded an ad, so just show it.");
			[self.adView setAdContentView:_adBannerView];
			[self.adView adapterDidFinishLoadingAd:self shouldTrackImpression:NO];
		}
	} 
	else 
	{
		// iAd not supported in iOS versions before 4.0.
		[self bannerView:nil didFailToReceiveAdWithError:nil];
	}
}

- (void)setBannerViewContentSizeIdentifierForOrientation:(UIInterfaceOrientation)orientation
{
	// iOS 4.2:
	if (&ADBannerContentSizeIdentifierPortrait != nil)
	{
		_adBannerView.requiredContentSizeIdentifiers = [NSSet setWithObjects:
														ADBannerContentSizeIdentifierPortrait, 
														ADBannerContentSizeIdentifierLandscape, 
														nil];
		if (UIInterfaceOrientationIsLandscape(orientation))
			_adBannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
		else
			_adBannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
	}
	// Prior to iOS 4.2:
	else
	{
		_adBannerView.requiredContentSizeIdentifiers = [NSSet setWithObjects:
														ADBannerContentSizeIdentifier320x50, 
														ADBannerContentSizeIdentifier480x32, 
														nil];
		if (UIInterfaceOrientationIsLandscape(orientation))
			_adBannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifier480x32;
		else
			_adBannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifier320x50;
		
	}
}

- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation
{
	if (!_adBannerView) 
		return;
	
	MPNativeAdOrientation allowedOrientation = [self.adView allowedNativeAdsOrientation];
	switch (allowedOrientation)
	{
		case MPNativeAdOrientationPortrait:
			[self setBannerViewContentSizeIdentifierForOrientation:
				UIInterfaceOrientationPortrait];
			break;
		case MPNativeAdOrientationLandscape:
			[self setBannerViewContentSizeIdentifierForOrientation:
				UIInterfaceOrientationLandscapeLeft];
			break;
		default:
			[self setBannerViewContentSizeIdentifierForOrientation:newOrientation];
			break;
	}
	
	// Prevent this view from automatically positioning itself in the center of its superview.
	_adBannerView.frame = CGRectMake(0.0, 
									 0.0, 
									 _adBannerView.frame.size.width, 
									 _adBannerView.frame.size.height);
}

#pragma mark -
#pragma	mark ADBannerViewDelegate

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
	MPLogInfo(@"iAd failed in trying to load or refresh an ad.");

	// Edge case: This method schedules the banner view to be deallocated. If this method
	// was called due to a failed internal iAd refresh, there is a chance the user could
	// initiate a banner action, only to have the banner view be deallocated during that action.
	// So, just don't allow the user to interact with the iAd.
	[_adBannerView setUserInteractionEnabled:NO];
	
	[self.adView adapter:self didFailToLoadAdWithError:error];
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
	MPLogInfo(@"iAd finished executing banner action.");
	[self.adView userActionDidEndForAdapter:self];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
	MPLogInfo(@"iAd should begin banner action.");
	[self.adView userActionWillBeginForAdapter:self];
	if (willLeave) [self.adView userWillLeaveApplicationFromAdapter:self];
	return YES;
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
	MPLogInfo(@"iAd has successfully loaded a new ad.");
	[self.adView setAdContentView:_adBannerView];
	[self.adView adapterDidFinishLoadingAd:self shouldTrackImpression:YES];
}

@end
