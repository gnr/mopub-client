//
//  MoPubAlertAdAdapter.h
//  MillionPhoto
//
//  Created by Nafis Jamal on 12/12/10.
//  Copyright 2010 Stanford. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MoPubNativeSDKAdapter.h"

@interface MoPubAlertAdAdapter : MoPubNativeSDKAdapter <UIAlertViewDelegate> {
	NSDictionary *alertParameters;
}

+ (NSString *)networkType;

@end
