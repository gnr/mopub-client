//
//  MoPubNativeSDKRegistry.m
//  Copyright (c) 2010 MoPub Inc.
//
//  Created by Nafis Jamal on 9/21/10.
//


#import "MoPubNativeSDKRegistry.h"
#import "MoPubNativeSDKAdapter.h"
#import "MoPubClassWrapper.h"

@implementation MoPubNativeSDKRegistry

+ (MoPubNativeSDKRegistry *)sharedRegistry {
  static MoPubNativeSDKRegistry *registry = nil;
  if (registry == nil) {
    registry = [[MoPubNativeSDKRegistry alloc] init];
  }
  return registry;
}

- (id)init {
  self = [super init];
  if (self != nil) {
    adapterDictionary = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)registerClass:(Class)adapterClass {
  // have to do all these to avoid compiler warnings...
  NSInteger (*networkTypeMethod)(id, SEL);
  networkTypeMethod = (NSInteger (*)(id, SEL))[adapterClass methodForSelector:@selector(networkType)];
  NSString *networkType = (NSString *)networkTypeMethod(adapterClass, @selector(networkType));
  MoPubClassWrapper *wrapper = [[MoPubClassWrapper alloc] initWithClass:adapterClass];
  [adapterDictionary setObject:wrapper forKey:networkType];
  [wrapper release];
}

- (Class)adapterClassForNetworkType:(NSString *)adType{
  return ((MoPubClassWrapper *)[adapterDictionary objectForKey:adType]).theClass;
}

- (void)dealloc {
  [adapterDictionary release];
  [super dealloc];
}

@end
