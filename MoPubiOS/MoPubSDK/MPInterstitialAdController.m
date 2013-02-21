//
//  MPInterstitialAdController.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPInterstitialAdController.h"
#import "MPInterstitialAdManager+DeprecatedCustomEvents.h"

#import "MPLogging.h"

@interface MPInterstitialAdController ()

+ (NSMutableArray *)sharedInterstitials;
- (id)initWithAdUnitId:(NSString *)adUnitId;

@end

@implementation MPInterstitialAdController

@synthesize delegate = _delegate;
@synthesize ready = _ready;
@synthesize adUnitId = _adUnitId;
@synthesize keywords = _keywords;
@synthesize location = _location;
@synthesize locationEnabled = _locationEnabled;
@synthesize locationPrecision = _locationPrecision;
@synthesize testing = _testing;
@synthesize adWantsNativeCloseButton = _adWantsNativeCloseButton;

- (id)initWithAdUnitId:(NSString *)adUnitId
{
    if (self = [super init]) {
        _manager = [[MPInterstitialAdManager alloc] init];
        
        // TODO: Consolidate these references.
        _manager.interstitialAdController = self;
        _manager.delegate = self;
        
        _adUnitId = [adUnitId copy];
    }
    return self;
}

- (void)dealloc
{
    _delegate = nil;
    _parent = nil;
    
    [_manager setInterstitialAdController:nil];
    [_manager setDelegate:nil];
    [_manager release];
    
    [_adUnitId release];
    [_keywords release];
    [_location release];
    
    [super dealloc];
}

#pragma mark - Public

+ (MPInterstitialAdController *)interstitialAdControllerForAdUnitId:(NSString *)adUnitId
{
    NSMutableArray *interstitials = [[self class] sharedInterstitials];

    @synchronized(self) {
        // Find the correct ad controller based on the ad unit ID.
        MPInterstitialAdController *interstitial = nil;
        for (MPInterstitialAdController *currentInterstitial in interstitials) {
            if ([currentInterstitial.adUnitId isEqualToString:adUnitId]) {
                interstitial = currentInterstitial;
                break;
            }
        }
        
        // Create a new ad controller for this ad unit ID if one doesn't already exist.
        if (!interstitial) {
            interstitial = [[[[self class] alloc] initWithAdUnitId:adUnitId] autorelease];
            [interstitials addObject:interstitial];
        }
        
        return interstitial;
    }
}

- (void)loadAd
{
    [_manager loadInterstitial];
}

- (void)showFromViewController:(UIViewController *)controller
{
    if (_parent) {
        MPLogWarn(@"The `parent` property of MPInterstitialAdController is deprecated. "
                  @"Use the `delegate` property instead.");
    }
    
    if (!controller) {
        MPLogWarn(@"The interstitial could not be shown: "
                  @"a nil view controller was passed to -showFromViewController:.");
        return;
    }
    
    [_manager presentInterstitialFromViewController:controller];
}

#pragma mark - Internal

+ (NSMutableArray *)sharedInterstitials
{
    static NSMutableArray *sharedInterstitials;
    
    @synchronized(self) {
        if (!sharedInterstitials) {
            sharedInterstitials = [[NSMutableArray array] retain];
        }
    }
    
    return sharedInterstitials;
}

#pragma mark - MPInterstitialAdManagerDelegate

- (void)managerDidLoadInterstitial:(MPInterstitialAdManager *)manager
{
    _ready = YES;
    
    if ([self.delegate respondsToSelector:@selector(interstitialDidLoadAd:)]) {
        [self.delegate interstitialDidLoadAd:self];
    }
}

- (void)manager:(MPInterstitialAdManager *)manager
        didFailToLoadInterstitialWithError:(NSError *)error
{
    _ready = NO;
    
    if ([self.delegate respondsToSelector:@selector(interstitialDidFailToLoadAd:)]) {
        [self.delegate interstitialDidFailToLoadAd:self];
    }
}

- (void)managerWillPresentInterstitial:(MPInterstitialAdManager *)manager
{
    if ([self.delegate respondsToSelector:@selector(interstitialWillAppear:)]) {
        [self.delegate interstitialWillAppear:self];
    }
}

- (void)managerDidPresentInterstitial:(MPInterstitialAdManager *)manager
{
    if ([self.delegate respondsToSelector:@selector(interstitialDidAppear:)]) {
        [self.delegate interstitialDidAppear:self];
    }
}

- (void)managerWillDismissInterstitial:(MPInterstitialAdManager *)manager
{
    if ([self.delegate respondsToSelector:@selector(interstitialWillDisappear:)]) {
        [self.delegate interstitialWillDisappear:self];
    }
}

- (void)managerDidDismissInterstitial:(MPInterstitialAdManager *)manager
{
    _ready = NO;
    
    if ([self.delegate respondsToSelector:@selector(interstitialDidDisappear:)]) {
        [self.delegate interstitialDidDisappear:self];
    }
}

- (void)managerDidExpireInterstitial:(MPInterstitialAdManager *)manager
{
    _ready = NO;
    
    if ([self.delegate respondsToSelector:@selector(interstitialDidExpire:)]) {
        [self.delegate interstitialDidExpire:self];
    }
}

- (void)managerDidReceiveTapEventForInterstitial:(MPInterstitialAdManager *)manager
{
    // TODO: Add interstitial 'onClick' delegate method.
}

#pragma mark - Deprecated

+ (NSMutableArray *)sharedInterstitialAdControllers
{
    return [[self class] sharedInterstitials];
}

+ (void)removeSharedInterstitialAdController:(MPInterstitialAdController *)controller
{
    [[[self class] sharedInterstitials] removeObject:controller];
}

- (void)show
{
    MPLogWarn(@"-[MPInterstitialAdController show] is deprecated. "
              @"Use -showFromViewController: instead.");
    
    if (_parent && !self.delegate) {
        MPLogError(@"Interstitial could not be shown. Call -showFromViewController: instead of"
                   @"-show when using the `delegate` property.");
        return;
    }
    
    if (_parent && self.delegate) {
        MPLogError(@"Interstitial could not be shown: "
                   @"the `delegate` and `parent` properties should not be both set.");
        return;
    }
    
    [_manager presentInterstitialFromViewController:_parent];
}

- (void)setAdWantsNativeCloseButton:(BOOL)adWantsNativeCloseButton
{
    _adWantsNativeCloseButton = adWantsNativeCloseButton;
}

- (NSArray *)locationDescriptionPair
{
    // TODO: Generate this.
    return nil;
}

- (void)customEventDidLoadAd
{
    [_manager customEventDidLoadAd];
}

- (void)customEventDidFailToLoadAd
{
    [_manager customEventDidFailToLoadAd];
}

- (void)customEventActionWillBegin
{
    [_manager customEventActionWillBegin];
}

#pragma mark - Deprecated MPBaseInterstitialAdapterDelegate (for compatibility w/ adapters)

- (void)adapterDidFinishLoadingAd:(MPBaseInterstitialAdapter *)adapter
{
    [_manager adapterDidFinishLoadingAd:adapter];
}

- (void)adapter:(MPBaseInterstitialAdapter *)adapter didFailToLoadAdWithError:(NSError *)error
{
    [_manager adapter:adapter didFailToLoadAdWithError:error];
}

- (void)interstitialWillAppearForAdapter:(MPBaseInterstitialAdapter *)adapter
{
    [_manager interstitialWillAppearForAdapter:adapter];
}

- (void)interstitialDidAppearForAdapter:(MPBaseInterstitialAdapter *)adapter
{
    [_manager interstitialDidAppearForAdapter:adapter];
}

- (void)interstitialWillDisappearForAdapter:(MPBaseInterstitialAdapter *)adapter
{
    [_manager interstitialWillDisappearForAdapter:adapter];
}

- (void)interstitialDidDisappearForAdapter:(MPBaseInterstitialAdapter *)adapter
{
    [_manager interstitialDidDisappearForAdapter:adapter];
}

- (void)interstitialWasTappedForAdapter:(MPBaseInterstitialAdapter *)adapter
{
    [_manager interstitialWasTappedForAdapter:adapter];
}

- (void)interstitialDidExpireForAdapter:(MPBaseInterstitialAdapter *)adapter
{
    [_manager interstitialDidExpireForAdapter:adapter];
}

- (void)interstitialWillLeaveApplicationForAdapter:(MPBaseInterstitialAdapter *)adapter
{
    [_manager interstitialWillLeaveApplicationForAdapter:adapter];
}

@end
