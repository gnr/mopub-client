//
//  MPInterstitialAdController.h
//  MoPub
//
//  Created by Andrew He on 2/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPAdView.h"

enum {
	InterstitialCloseButtonTypeDefault,
	InterstitialCloseButtonTypeNone
};
typedef NSUInteger InterstitialCloseButtonType;

@protocol MPInterstitialAdControllerDelegate;

@interface MPInterstitialAdController : UIViewController <MPAdViewDelegate>
{
	MPAdView *_adView;
	UIViewController<MPInterstitialAdControllerDelegate> *_parent;
	NSString *_adUnitId;
	CGSize _adSize;
	InterstitialCloseButtonType _closeButtonType;
}

@property (nonatomic, assign) UIViewController<MPInterstitialAdControllerDelegate> *parent;
@property (nonatomic, copy) NSString *adUnitId;
@property (nonatomic, assign) CGSize adSize;
@property (nonatomic, assign) InterstitialCloseButtonType closeButtonType;

+ (NSMutableArray *)sharedInterstitialAdControllers;
+ (MPInterstitialAdController *)sharedInterstitialAdControllerForAdUnitId:(NSString *)ID;
+ (void)removeSharedInterstitialAdController:(MPInterstitialAdController *)controller;
- (id)initWithAdUnitId:(NSString *)ID parentViewController:(UIViewController *)parent;
- (void)loadAd;

@end

@protocol MPInterstitialAdControllerDelegate <MPAdViewDelegate>

@end

