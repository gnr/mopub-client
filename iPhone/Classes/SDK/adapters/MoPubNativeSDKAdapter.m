//
//  MoPubGoogleAdSenseAdapter.h
//  Copyright (c) 2010 MoPub Inc.
//
//  Created by Nafis Jamal on 9/21/10.
//

#import "MoPubNativeSDKAdapter.h"

@implementation MoPubNativeSDKAdapter

@synthesize adController;

- (id)initWithAdController:(AdController *)_adController{
	if (self = [super init]){
		self.adController = _adController;
	}
	return self;
}

- (void)getAd{
	[self getAdWithParams:nil];
}

- (void)getAdWithParams:(NSDictionary *)params {
  NSLog(@"Calling getAd not allowed. Subclass of AdWhirlAdNetworkAdapter must implement -getAdWithParams.");
  [self doesNotRecognizeSelector:_cmd];
}

- (void)rotateToOrientation:(UIInterfaceOrientation)orientation {
  // do nothing by default. Subclasses implement specific handling.
  NSLog(@"rotate to orientation %d called for adapter %@",
             orientation, NSStringFromClass([self class]));
}

//- (BOOL)isBannerAnimationOK:(AWBannerAnimationType)animType {
//  return YES;
//}

- (NSDictionary *)simpleJsonStringToDictionary:(NSString *)jsonString{
	// remove leading and trailing {","} respectively
	jsonString = [jsonString substringWithRange:NSMakeRange(2, [jsonString length] - 4)];
	NSMutableDictionary *jsonDictionary = [NSMutableDictionary dictionary]; // autoreleased
	NSArray *keyValuePairs = [jsonString componentsSeparatedByString:@"\",\""];
	for (NSString *keyValueString in keyValuePairs){
		NSArray *keyValue = [keyValueString componentsSeparatedByString:@"\":\""];
		NSString *key = [keyValue objectAtIndex:0];
		NSString *value = [keyValue objectAtIndex:1];
		[jsonDictionary setObject:value forKey:key];
	}
	return jsonDictionary;
}


- (void)dealloc {
  [adController release];	
  [super dealloc];
}

@end
