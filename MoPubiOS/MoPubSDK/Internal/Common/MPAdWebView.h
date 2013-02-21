//
//  MPAdWebView.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MPAdBrowserController.h"
#import "MPProgressOverlayView.h"

enum {
    MPAdWebViewEventAdDidAppear     = 0,
    MPAdWebViewEventAdDidDisappear  = 1
};
typedef NSUInteger MPAdWebViewEvent;

NSString * const kMoPubURLScheme;
NSString * const kMoPubCloseHost;
NSString * const kMoPubFinishLoadHost;
NSString * const kMoPubFailLoadHost;
NSString * const kMoPubInAppPurchaseHost;
NSString * const kMoPubCustomHost;

@protocol MPAdWebViewDelegate;
@class MPAdConfiguration;

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface MPAdWebView : UIView <UIWebViewDelegate, MPAdBrowserControllerDelegate,
    MPProgressOverlayViewDelegate>
{
    UIWebView *_webView;
    id<MPAdWebViewDelegate> _delegate;
    id _customMethodDelegate;
    
    MPAdConfiguration *_configuration;
    MPAdBrowserController *_browserController;
    
    // Only used when the MPAdWebView is the backing view for an interstitial ad.
    BOOL _dismissed;
}

@property (nonatomic, readonly, retain) UIWebView *webView;
@property (nonatomic, assign) id<MPAdWebViewDelegate> delegate;
@property (nonatomic, assign) id customMethodDelegate;
@property (nonatomic, readonly, retain) MPAdBrowserController *browserController;
@property (nonatomic, assign, getter=isDismissed) BOOL dismissed;

- (void)loadConfiguration:(MPAdConfiguration *)configuration;
- (void)loadURL:(NSURL *)URL;
- (void)loadData:(NSData *)data MIMEType:(NSString *)MIMEType
textEncodingName:(NSString *)textEncodingName baseURL:(NSURL *)baseURL;
- (void)rotateToOrientation:(UIInterfaceOrientation)orientation;
- (void)invokeJavaScriptForEvent:(MPAdWebViewEvent)event;
- (void)forceRedraw;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol MPAdWebViewDelegate <NSObject>

@required
- (UIViewController *)viewControllerForPresentingModalView;

@optional
- (void)adDidClose:(MPAdWebView *)ad;
- (void)adDidFinishLoadingAd:(MPAdWebView *)ad;
- (void)adDidFailToLoadAd:(MPAdWebView *)ad;
- (void)adActionWillBegin:(MPAdWebView *)ad;
- (void)adActionWillLeaveApplication:(MPAdWebView *)ad;
- (void)adActionDidFinish:(MPAdWebView *)ad;
- (void)ad:(MPAdWebView *)ad
        didInitiatePurchaseForProductIdentifier:(NSString *)productID;
- (void)ad:(MPAdWebView *)ad
        didInitiatePurchaseForProductIdentifier:(NSString *)productID
        quantity:(NSInteger)quantity;

@end
