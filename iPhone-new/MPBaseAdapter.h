//
//  MPBaseAdapter.h
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPAdView.h"

@interface MPBaseAdapter : NSObject {
	MPAdView *_delegate;
}

@property (nonatomic, assign) MPAdView *delegate;

- (void)getAd;
- (void)getAdWithParams:(NSDictionary *)params;

@end
