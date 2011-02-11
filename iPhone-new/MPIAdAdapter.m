//
//  MPIAdAdapter.m
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import "MPIAdAdapter.h"
#import "MPAdView.h"
#import "MPLogging.h"

@implementation MPIAdAdapter

- (void)dealloc
{
	_adBannerView.delegate = nil;
	[_adBannerView release];
	[super dealloc];
}

- (void)getAdWithParams:(NSDictionary *)params
{
	Class cls = NSClassFromString(@"ADBannerView");
	if (cls != nil) {
		CGSize size = self.adView.bounds.size;
		
		if (_adBannerView)
		{
			_adBannerView.delegate = nil;
			[_adBannerView release];
		}
		
		_adBannerView = [[cls alloc] initWithFrame:(CGRect){{0, 0}, size}];
		
		// iOS 4.2:
		if (&ADBannerContentSizeIdentifierPortrait != nil)
		{
			_adBannerView.requiredContentSizeIdentifiers = [NSSet setWithObjects:ADBannerContentSizeIdentifierPortrait, 
															ADBannerContentSizeIdentifierLandscape, nil];
			_adBannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
		}
		// Prior to iOS 4.2:
		else
		{
			_adBannerView.requiredContentSizeIdentifiers = [NSSet setWithObjects:ADBannerContentSizeIdentifier320x50, 
															ADBannerContentSizeIdentifier480x32, nil];
			_adBannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifier320x50;
		}
			
		_adBannerView.delegate = self;
	} 
	else 
	{
		// iAd not supported in iOS versions before 4.0.
		[self bannerView:nil didFailToReceiveAdWithError:nil];
	}
}

- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation
{
	if (!_adBannerView) 
		return;
	
	if (UIInterfaceOrientationIsLandscape(newOrientation))
	{
		_adBannerView.currentContentSizeIdentifier = (&ADBannerContentSizeIdentifierLandscape) ? 
			ADBannerContentSizeIdentifierLandscape : ADBannerContentSizeIdentifier480x32;
	}
	else
	{
		_adBannerView.currentContentSizeIdentifier = (&ADBannerContentSizeIdentifierPortrait) ?
			ADBannerContentSizeIdentifierPortrait : ADBannerContentSizeIdentifier320x50;
	}
		
	_adBannerView.frame = CGRectMake(0.0, 
									 0.0, 
									 _adBannerView.frame.size.width, 
									 _adBannerView.frame.size.height);
}

#pragma mark -
#pragma	mark ADBannerViewDelegate

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
	MPLog(@"MOPUB: iAd Failed To Receive Ad");
	[self.adView adapter:self didFailToLoadAdWithError:error];
	
	_adBannerView.delegate = nil;
	[_adBannerView release];
	_adBannerView = nil;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
	MPLog(@"MOPUB: iAd Finished Executing Banner Action");
	[self.adView userActionDidEndForAdapter:self];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
	MPLog(@"MOPUB: iAd Should Begin Banner Action");
	[self.adView userActionWillBeginForAdapter:self];
	return YES;
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
	MPLog(@"MOPUB: iAd Load Succeeded");
	[self.adView setAdContentView:_adBannerView];
	[self.adView adapterDidFinishLoadingAd:self];
}

@end
