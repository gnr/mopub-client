//
//  MPAdConversionTracker.h
//  MoPub
//
//  Created by Andrew He on 2/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MPAdConversionTracker : NSObject 
{
}

+ (MPAdConversionTracker *)sharedConversionTracker;
- (void)reportApplicationOpenForApplicationID:(NSString *)appID;

@end
