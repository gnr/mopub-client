//
//  MPInterstitialAdManager.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPAdServerCommunicator.h"
#import "MPBaseInterstitialAdapter.h"

@class MPInterstitialAdController;
@protocol MPInterstitialAdManagerDelegate;

@interface MPInterstitialAdManager : NSObject <MPAdServerCommunicatorDelegate,
    MPBaseInterstitialAdapterDelegate>
{
    MPInterstitialAdController *_interstitialAdController;
    id<MPInterstitialAdManagerDelegate> _delegate;
    
    MPAdServerCommunicator *_communicator;
    BOOL _loading;
    
    NSURL *_failoverURL;
    
    MPBaseInterstitialAdapter *_currentAdapter;
    MPBaseInterstitialAdapter *_nextAdapter;
    
    MPAdConfiguration *_currentConfiguration;
    MPAdConfiguration *_nextConfiguration;
    
    BOOL _isReady;
    BOOL _hasRecordedImpressionForCurrentInterstitial;
    BOOL _hasRecordedClickForCurrentInterstitial;
    
    NSMutableURLRequest *_request;
}

@property (nonatomic, assign, getter=isLoading) BOOL loading;
@property (nonatomic, assign) MPInterstitialAdController *interstitialAdController;
@property (nonatomic, assign) id<MPInterstitialAdManagerDelegate> delegate;
@property (nonatomic, readonly, copy) NSURL *failoverURL;

- (void)loadAdWithURL:(NSURL *)URL;
- (void)loadInterstitial;
- (void)presentInterstitialFromViewController:(UIViewController *)controller;
- (BOOL)isHandlingCustomEvent;
- (void)reportClickForCurrentInterstitial;
- (void)reportImpressionForCurrentInterstitial;

- (BOOL)interstitialDelegateRespondsToSelector:(SEL)selector;
- (void)performSelectorOnInterstitialDelegate:(SEL)selector;
- (void)performSelector:(SEL)selector onInterstitialDelegateWithObject:(id)arg;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol MPInterstitialAdManagerDelegate <NSObject>

- (NSString *)adUnitId;
- (void)managerDidLoadInterstitial:(MPInterstitialAdManager *)manager;
- (void)manager:(MPInterstitialAdManager *)manager
        didFailToLoadInterstitialWithError:(NSError *)error;
- (void)managerWillPresentInterstitial:(MPInterstitialAdManager *)manager;
- (void)managerDidPresentInterstitial:(MPInterstitialAdManager *)manager;
- (void)managerWillDismissInterstitial:(MPInterstitialAdManager *)manager;
- (void)managerDidDismissInterstitial:(MPInterstitialAdManager *)manager;
- (void)managerDidExpireInterstitial:(MPInterstitialAdManager *)manager;
- (void)managerDidReceiveTapEventForInterstitial:(MPInterstitialAdManager *)manager;

@end