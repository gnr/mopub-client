//
//  MPAdView.h
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdClickController.h"
#import "MPBaseAdapter.h"

@protocol MPAdViewDelegate;

#define HOSTNAME @"ads.mopub.com"
#define PUB_ID_320x50 @"agltb3B1Yi1pbmNyDAsSBFNpdGUYkaoMDA"

@interface MPAdView : UIView <UIWebViewDelegate, AdClickControllerDelegate, MPAdapterDelegate> {
	NSObject<MPAdViewDelegate> *_delegate;
	
	UIView *_adContentView;
	UIWebView *_webView;
	NSString *_adUnitId;
	NSMutableData *_data;
	NSURL *_URL;
	NSURLConnection *_conn;
	MPBaseAdapter *_adapter;
	
	NSURL *_clickURL;
	NSURL *_failURL;
	
	BOOL _isLoading;
}

@property (nonatomic, assign) NSObject<MPAdViewDelegate> *delegate;
@property (nonatomic, copy) NSString *adUnitId;
@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, copy) NSURL *clickURL;
@property (nonatomic, copy) NSURL *failURL;

- (void)loadAd;
- (void)loadAdWithURL:(NSURL *)URL;
- (void)refreshAd;
- (void)setAdContentView:(UIView *)view;

@end

@protocol MPAdViewDelegate

@required
- (UIViewController *)viewControllerForPresentingModalView;

@optional
- (void)adViewDidFailToLoadAd:(MPAdView *)view;
- (void)adViewDidLoadAd:(MPAdView *)view;

@end
