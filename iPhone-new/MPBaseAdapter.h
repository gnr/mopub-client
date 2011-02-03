//
//  MPBaseAdapter.h
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MPAdView;

@interface MPBaseAdapter : NSObject 
{
	MPAdView *_delegate;
}

@property (nonatomic, assign) MPAdView *delegate;

- (void)getAd;
- (void)getAdWithParams:(NSDictionary *)params;
- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation;

@end

@protocol MPAdapterDelegate
@required
- (void)adapterDidFinishLoadingAd:(MPBaseAdapter *)adapter;
- (void)adapter:(MPBaseAdapter *)adapter didFailToLoadAdWithError:(NSError *)error;
- (void)adClickedForAdapter:(MPBaseAdapter *)adapter;

@end