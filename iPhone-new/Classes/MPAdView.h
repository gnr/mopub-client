//
//  MPAdView.h
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdClickController.h"

#define HOSTNAME @"ads.mopub.com"
#define PUB_ID_320x50 @"agltb3B1Yi1pbmNyDAsSBFNpdGUYkaoMDA"

@protocol MPAdViewProtocol
@required
- (UIViewController *)viewControllerForPresentingModalView;
@end

@interface MPAdView : UIView <UIWebViewDelegate, AdClickControllerDelegate> {
	id<MPAdViewProtocol> _delegate;
	
	UIView *_adContentView;
	UIWebView *_webView;
	NSString *_adUnitId;
	NSMutableData *_data;
	NSURL *_url;
	NSURLConnection *_conn;
	
	NSURL *_clickURL;
	
	BOOL _isLoading;
}

@property (nonatomic, assign) id<MPAdViewProtocol> delegate;
@property (nonatomic, copy) NSString *adUnitId;

- (void)loadAd;
- (void)refreshAd;
- (void)setAdContentView:(UIView *)view;

@end
