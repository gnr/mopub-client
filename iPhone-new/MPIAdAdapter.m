//
//  MPIAdAdapter.m
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import "MPIAdAdapter.h"
#import "MPAdView.h"

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
		CGSize size = self.delegate.frame.size;
		
		if (_adBannerView)
		{
			_adBannerView.delegate = nil;
			[_adBannerView release];
		}
		
		_adBannerView = [[cls alloc] initWithFrame:(CGRect){{0, 0}, size}];
		
		// iOS 4.2:
		if (&ADBannerContentSizeIdentifierPortrait != nil)
		{
			_adBannerView.requiredContentSizeIdentifiers = [NSSet setWithObjects:ADBannerContentSizeIdentifierPortrait, ADBannerContentSizeIdentifierLandscape, nil];
			_adBannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
		}
		// Prior to iOS 4.2:
		else
		{
			_adBannerView.requiredContentSizeIdentifiers = [NSSet setWithObjects:ADBannerContentSizeIdentifier320x50, ADBannerContentSizeIdentifier480x32, nil];
			_adBannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifier320x50;
		}
			
		_adBannerView.delegate = self;
	} 
	else 
	{
		// iAd isn't supported in iOS versions before 4.0
		[self bannerView:nil didFailToReceiveAdWithError:nil];
	}
}

- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation
{
	if (!_adBannerView) 
		return;
	
	if (UIInterfaceOrientationIsLandscape(newOrientation))
		_adBannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifier480x32;//ADBannerContentSizeIdentifierLandscape;
	else 
		_adBannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifier320x50;//ADBannerContentSizeIdentifierPortrait;
	
	// ADBannerView positions itself in the center of its superview, which
	// we don't want, since we rely on publishers to resize the container view.
	_adBannerView.frame = CGRectMake(0.0, 
									 0.0, 
									 _adBannerView.frame.size.width, 
									 _adBannerView.frame.size.height);
}

#pragma mark -
#pragma	mark ADBannerViewDelegate

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
	NSLog(@"MOPUB: iAd Failed To Receive Ad");
	[self.delegate adapter:self didFailToLoadAdWithError:error];
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
	NSLog(@"MOPUB: iAd Finished Executing Banner Action");
	// TODO: bannerview action finish
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
	NSLog(@"MOPUB: iAd Should Begin Banner Action");
	[self.delegate adClickedForAdapter:self];
	return YES;
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
	NSLog(@"MOPUB: iAd Load Succeeded");
	[self.delegate setAdContentView:_adBannerView];
	[self.delegate adapterDidFinishLoadingAd:self];
}

@end
