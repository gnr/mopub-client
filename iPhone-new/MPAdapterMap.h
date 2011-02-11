//
//  MPAdapterMap.h
//  MoPub
//
//  Created by Andrew He on 1/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPAdapterMap : NSObject
{
	NSDictionary *_map;
}

+ (id)sharedAdapterMap;
- (NSString *)classStringForAdapterType:(NSString *)type;
- (Class)classForAdapterType:(NSString *)type;

@end