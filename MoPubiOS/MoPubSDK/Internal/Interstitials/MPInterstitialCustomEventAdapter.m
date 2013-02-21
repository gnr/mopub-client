//
//  MPInterstitialCustomEventAdapter.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPInterstitialCustomEventAdapter.h"

#import "MPAdConfiguration.h"
#import "MPInterstitialAdManager.h"
#import "MPLogging.h"

@implementation MPInterstitialCustomEventAdapter

- (void)dealloc
{
    _interstitialCustomEvent.delegate = nil;
    [_interstitialCustomEvent release];
    
    [super dealloc];
}

////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)getAdWithConfiguration:(MPAdConfiguration *)configuration
{
    Class customEventClass = configuration.customEventClass;
    
    MPLogInfo(@"Looking for custom event class named %@.", configuration.customEventClass);
    
    if (customEventClass) {
        [self loadAdFromCustomClass:customEventClass configuration:configuration];
        return;
    }
    
    MPLogInfo(@"Looking for custom event selector named %@.", configuration.customSelectorName);
    
    SEL customEventSelector = NSSelectorFromString(configuration.customSelectorName);
    if ([_manager interstitialDelegateRespondsToSelector:customEventSelector]) {
        [_manager performSelectorOnInterstitialDelegate:customEventSelector];
        return;
    }
    
    NSString *oneArgumentSelectorName = [configuration.customSelectorName
                                         stringByAppendingString:@":"];
    
    MPLogInfo(@"Looking for custom event selector named %@.", oneArgumentSelectorName);
    
    SEL customEventOneArgumentSelector = NSSelectorFromString(oneArgumentSelectorName);
    if ([_manager interstitialDelegateRespondsToSelector:customEventOneArgumentSelector]) {
        [_manager performSelector:customEventOneArgumentSelector
                  onInterstitialDelegateWithObject:self.interstitialAdController];
        return;
    }
    
    MPLogInfo(@"Could not handle custom event request.");
    
    [self.interstitialAdController adapter:self didFailToLoadAdWithError:nil];
}

- (void)showInterstitialFromViewController:(UIViewController *)controller
{
    [_interstitialCustomEvent showInterstitialFromRootViewController:controller];
}

////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)loadAdFromCustomClass:(Class)customClass configuration:(MPAdConfiguration *)configuration
{
    _interstitialCustomEvent = [[customClass alloc] init];
    _interstitialCustomEvent.delegate = self;
    [_interstitialCustomEvent requestInterstitialWithCustomEventInfo:configuration.customEventClassData];
}

#pragma mark - MPInterstitialCustomEventDelegate

- (void)interstitialCustomEvent:(MPInterstitialCustomEvent *)customEvent
                      didLoadAd:(id)ad
{
    [self.manager adapterDidFinishLoadingAd:self];
}

- (void)interstitialCustomEvent:(MPInterstitialCustomEvent *)customEvent
       didFailToLoadAdWithError:(NSError *)error
{
    [self.manager adapter:self didFailToLoadAdWithError:error];
}

- (void)interstitialCustomEventWillAppear:(MPInterstitialCustomEvent *)customEvent
{
    [self.manager interstitialWillAppearForAdapter:self];
}

- (void)interstitialCustomEventWillDisappear:(MPInterstitialCustomEvent *)customEvent
{
    [self.manager interstitialWillDisappearForAdapter:self];
}

- (void)interstitialCustomEventDidDisappear:(MPInterstitialCustomEvent *)customEvent
{
    [self.manager interstitialDidDisappearForAdapter:self];
}

- (void)interstitialCustomEventWillLeaveApplication:(MPInterstitialCustomEvent *)customEvent
{
    [self.manager interstitialWillLeaveApplicationForAdapter:self];
}

@end
