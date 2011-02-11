//
//  MPInterstitialAdController.h
//  MoPub
//
//  Created by Andrew He on 2/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPAdView.h"

enum 
{
	InterstitialCloseButtonTypeDefault,
	InterstitialCloseButtonTypeNone
};
typedef NSUInteger InterstitialCloseButtonType;

enum 
{
	InterstitialOrientationTypePortrait,
	InterstitialOrientationTypeLandscape,
	InterstitialOrientationTypeBoth
};
typedef NSUInteger InterstitialOrientationType;

@protocol MPInterstitialAdControllerDelegate;

@interface MPInterstitialAdController : UIViewController <MPAdViewDelegate>
{
	BOOL _statusBarWasHidden;
	BOOL _navigationBarWasHidden;
	BOOL _ready;
	MPAdView *_adView;
	UIViewController<MPInterstitialAdControllerDelegate> *_parent;
	NSString *_adUnitId;
	CGSize _adSize;
	InterstitialCloseButtonType _closeButtonType;
	InterstitialOrientationType _orientationType;
	UIButton *_closeButton;
}

@property (nonatomic, readonly, assign) BOOL ready;
@property (nonatomic, assign) UIViewController<MPInterstitialAdControllerDelegate> *parent;
@property (nonatomic, copy) NSString *adUnitId;

+ (NSMutableArray *)sharedInterstitialAdControllers;
+ (MPInterstitialAdController *)sharedInterstitialAdControllerForAdUnitId:(NSString *)ID;
+ (void)removeSharedInterstitialAdController:(MPInterstitialAdController *)controller;
- (id)initWithAdUnitId:(NSString *)ID parentViewController:(UIViewController *)parent;
- (void)loadAd;
- (void)show;

@end

@protocol MPInterstitialAdControllerDelegate <MPAdViewDelegate>
@required
- (void)dismissInterstitial:(MPInterstitialAdController *)interstitial;

@optional
- (void)interstitialDidLoadAd:(MPInterstitialAdController *)interstitial;
- (void)interstitialDidFailToLoadAd:(MPInterstitialAdController *)interstitial;
- (void)interstitialWillAppear:(MPInterstitialAdController *)interstitial;
@end

