//
//  MPAdView.h
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "AdClickController.h"
#import "MPBaseAdapter.h"

@protocol MPAdViewDelegate;

//#define HOSTNAME @"192.168.1.120:8080"
//#define PUB_ID_320x50 @"agltb3B1Yi1pbmNyDAsSBFNpdGUYkaoMDA"
//#define HOSTNAME @"ads.mopub.com"
#define HOSTNAME @"36-newui.latest.mopub-inc.appspot.com"
#define PUB_ID_320x50 @"agltb3B1Yi1pbmNyDAsSBFNpdGUYkaoMDA"

@interface MPAdView : UIView <UIWebViewDelegate, AdClickControllerDelegate, MPAdapterDelegate> {
	NSObject<MPAdViewDelegate> *_delegate;
	
	NSString *_keywords;
	CLLocation *_location;
	
	UIView *_adContentView;
	UIWebView *_webView;
	NSString *_adUnitId;
	NSMutableData *_data;
	NSURL *_URL;
	NSURLConnection *_conn;
	MPBaseAdapter *_adapter;
	
	NSURL *_clickURL;
	NSURL *_interceptURL;
	NSURL *_failURL;
	NSMutableArray *_excludeParams;
	
	BOOL _shouldInterceptLinks;
	BOOL _scrollable;
	
	BOOL _webViewIsLoading;
	BOOL _isLoading;
}

@property (nonatomic, assign) NSObject<MPAdViewDelegate> *delegate;
@property (nonatomic, copy) NSString *adUnitId;
@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, copy) NSURL *clickURL;
@property (nonatomic, copy) NSURL *interceptURL;
@property (nonatomic, copy) NSURL *failURL;

@property (nonatomic, assign) BOOL shouldInterceptLinks;
@property (nonatomic, assign) BOOL scrollable;

@property (nonatomic, copy) NSString *keywords;
@property (nonatomic, retain) CLLocation *location;

- (void)loadAd;
- (void)loadAdWithURL:(NSURL *)URL;
- (void)refreshAd;
- (void)setAdContentView:(UIView *)view;
- (void)viewDidAppear;

// Informs the ad unit that the device orientation has changed.
- (void)rotateToOrientation:(UIInterfaceOrientation)newOrientation;

- (void)didCloseAd:(id)sender;

@end

@protocol MPAdViewDelegate

@required
- (UIViewController *)viewControllerForPresentingModalView;

@optional
- (void)adViewWillLoadAd:(MPAdView *)view;
- (void)adViewDidFailToLoadAd:(MPAdView *)view;
- (void)adViewDidLoadAd:(MPAdView *)view;
- (void)nativeAdClicked:(MPAdView *)view;
- (void)willPresentModalViewForAd:(MPAdView *)view;
- (void)didPresentModalViewForAd:(MPAdView *)view;
- (void)adViewDidReceiveResponseParams:(NSDictionary *)params;

@end
