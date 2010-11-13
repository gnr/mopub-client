//
//  MoPubGoogleAdSenseAdapter.h
//  Copyright (c) 2010 MoPub Inc.
//
//  Created by Nafis Jamal on 9/21/10.
//

#import "MoPubNativeSDKAdapter.h"
#import "MoPubNativeSDKRegistry.h"

#import "GADAdViewController.h"
#import "GADAdSenseParameters.h"

@interface MoPubGoogleAdSenseAdapter : MoPubNativeSDKAdapter <GADAdViewControllerDelegate> {
	GADAdViewController *adViewController;
}

@property (nonatomic,retain) GADAdViewController *adViewController;

+ (NSString *)networkType;

@end
