//
//  MoPubNativeSDKAdapter.h
//  Copyright (c) 2010 MoPub Inc.
//
//  Created by Nafis Jamal on 9/21/10.
//

#import <UIKit/UIKit.h>

@class AdController;

@interface MoPubNativeSDKAdapter : NSObject {
	AdController *adController;
}

@property (nonatomic,retain) AdController *adController;

/**
 * Subclasses must implement +networkType to return an NSString.
 */
//+ (NSString *)networkType;

/**
 * Subclasses must add itself to the MoPubNativeSDKRegistry. One way
 * to do so is to implement the +load function and register there.
 */
//+ (void)load;

/**
 * Default initializer. Subclasses do not need to override this method unless
 * they need to perform additional initialization. In which case, this
 * method must be called via the super keyword.
 */
//- (id)initWithAdWhirlDelegate:(id<AdWhirlDelegate>)delegate
//                         view:(AdWhirlView *)view
//                       config:(AdWhirlConfig *)config
//                networkConfig:(AdWhirlAdNetworkConfig *)netConf;

- (id)initWithAdController:(AdController *)adController;

/**
 * Ask the adapter to get an ad. This must be implemented by subclasses.
 */
- (void)getAdWithParams:(NSDictionary *)params;

- (void)getAd;

/**
 * Tell the adapter that the interface orientation changed or is about to change
 */
- (void)rotateToOrientation:(UIInterfaceOrientation)orientation;


- (NSDictionary *)simpleJsonStringToDictionary:(NSString *)jsonString;

/**
 * Some ad transition types may cause issues with particular ad networks. The
 * adapter should know whether the given animation type is OK. Defaults to
 * YES.
 */
//- (BOOL)isBannerAnimationOK:(AWBannerAnimationType)animType;

//@property (nonatomic,assign) id<AdWhirlDelegate> adWhirlDelegate;
//@property (nonatomic,assign) AdWhirlView *adWhirlView;
//@property (nonatomic,retain) AdWhirlConfig *adWhirlConfig;
//@property (nonatomic,retain) AdWhirlAdNetworkConfig *networkConfig;
//@property (nonatomic,retain) UIView *adNetworkView;

@end
