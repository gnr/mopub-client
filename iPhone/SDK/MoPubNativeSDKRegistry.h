//
//  MoPubNativeSDKRegistry.h
//  Copyright (c) 2010 MoPub Inc.
//
//  Created by Nafis Jamal on 9/21/10.
//

#import <Foundation/Foundation.h>

@class MoPubNativeSDKAdapter;
//@class MoPubClassWrapper;

@interface MoPubNativeSDKRegistry : NSObject {
  NSMutableDictionary *adapterDictionary;
}

+ (MoPubNativeSDKRegistry *)sharedRegistry;
- (void)registerClass:(Class)adapterClass;
- (Class)adapterClassForNetworkType:(NSString *)adType;

@end
