//
//  MPHTMLInterstitialViewController.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPHTMLInterstitialViewController.h"

@interface MPHTMLInterstitialViewController ()

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MPHTMLInterstitialViewController

@synthesize delegate = _delegate;

- (id)init//WithAdConfiguration:(MPAdConfiguration *)configuration
{
    self = [super init];
    if (self) {
        _interstitialView = [[MPAdWebView alloc] init];
        _interstitialView.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    _interstitialView.delegate = nil;
    _interstitialView.customMethodDelegate = nil;
    [_interstitialView release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    _interstitialView.frame = self.view.bounds;
    _interstitialView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_interstitialView];
}

#pragma mark - Public

- (id)customMethodDelegate
{
    return [_interstitialView customMethodDelegate];
}

- (void)setCustomMethodDelegate:(id)delegate
{
    [_interstitialView setCustomMethodDelegate:delegate];
}

- (void)loadConfiguration:(MPAdConfiguration *)configuration
{
    [self view];
    [_interstitialView loadConfiguration:configuration];
}

- (void)willPresentInterstitial
{
    _interstitialView.alpha = 0.0;
    
    if ([self.delegate respondsToSelector:@selector(interstitialWillAppear:)]) {
        [self.delegate interstitialWillAppear:self];
    }
}

- (void)didPresentInterstitial
{
    _interstitialView.dismissed = NO;
    
    [_interstitialView invokeJavaScriptForEvent:MPAdWebViewEventAdDidAppear];
    
    // XXX: In certain cases, UIWebView's content appears off-center due to rotation / auto-
    // resizing while off-screen. -forceRedraw corrects this issue, but there is always a brief
    // instant when the old content is visible. We mask this using a short fade animation.
    [_interstitialView forceRedraw];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    _interstitialView.alpha = 1.0;
    [UIView commitAnimations];
    
    if ([self.delegate respondsToSelector:@selector(interstitialDidAppear:)]) {
        [self.delegate interstitialDidAppear:self];
    }
}

- (void)willDismissInterstitial
{
    _interstitialView.dismissed = YES;
    
    if ([self.delegate respondsToSelector:@selector(interstitialWillDisappear:)]) {
        [self.delegate interstitialWillDisappear:self];
    }
}

- (void)didDismissInterstitial
{
    if ([self.delegate respondsToSelector:@selector(interstitialDidDisappear:)]) {
        [self.delegate interstitialDidDisappear:self];
    }
}

#pragma mark - Autorotation

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [_interstitialView rotateToOrientation:self.interfaceOrientation];
}

#pragma mark - MPAdWebViewDelegate

- (UIViewController *)viewControllerForPresentingModalView
{
    return self;
}

- (void)adDidFinishLoadingAd:(MPAdWebView *)ad
{
    if ([self.delegate respondsToSelector:@selector(interstitialDidLoadAd:)]) {
        [self.delegate interstitialDidLoadAd:self];
    }
}

- (void)adDidFailToLoadAd:(MPAdWebView *)ad
{
    if ([self.delegate respondsToSelector:@selector(interstitialDidFailToLoadAd:)]) {
        [self.delegate interstitialDidFailToLoadAd:self];
    }
}

- (void)adActionWillBegin:(MPAdWebView *)ad
{
    if ([self.delegate respondsToSelector:@selector(interstitialWasTapped:)]) {
        [self.delegate interstitialWasTapped:self];
    }
}

- (void)adActionWillLeaveApplication:(MPAdWebView *)ad
{
    if ([self.delegate respondsToSelector:@selector(interstitialWillLeaveApplication:)]) {
        [self.delegate interstitialWillLeaveApplication:self];
    }
    
    [self dismissInterstitialAnimated:NO];
}

- (void)adActionDidFinish:(MPAdWebView *)ad
{
    // TODO: Signal to delegate.
}

@end
