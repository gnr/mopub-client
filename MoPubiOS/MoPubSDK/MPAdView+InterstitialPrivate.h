//
//  MPAdView+InterstitialPrivate.h
//  MoPub
//
//  Created by Andrew He on 5/17/11.
//  Copyright 2011 MoPub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPAdView.h"

/*
 * For now, only used for turning MPInterstitialAdController into a "friend" class of MPAdView.
 */
@interface MPAdView (InterstitialPrivate)
@property (nonatomic, assign) BOOL isLoading;
- (void)trackImpression;
@end
