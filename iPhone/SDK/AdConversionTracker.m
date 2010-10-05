//
//  AdConversionTracking.m
//  SimpleAds
//
//  Created by Nafis Jamal on 10/5/10.
//  Copyright 2010 Stanford. All rights reserved.
//

#import "AdConversionTracker.h"
#import <UIKit/UIKit.h>


#define HOSTNAME @"ads.mopub.com"

@interface AdConversionTracker (Internal)
- (void) reportApplicationOpenSynchronous;
@end


@implementation AdConversionTracker

+ (AdConversionTracker *)sharedConversionTracker
{
	static AdConversionTracker *sharedConversionTracker;
	
	@synchronized(self)
	{
		if (!sharedConversionTracker)
			sharedConversionTracker = [[AdConversionTracker alloc] init];
		
		return sharedConversionTracker;
	}
}

- (void) reportApplicationOpen{
	[self performSelectorInBackground:@selector(reportApplicationOpenSynchronous) withObject:nil];
}

- (void) reportApplicationOpenSynchronous{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; 
	// Have we already reported an app open?

	NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
																		NSUserDomainMask, YES) objectAtIndex:0];
	NSString *appOpenLogPath = [documentsDir stringByAppendingPathComponent:@"mopubAppOpen.log"];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if(![fileManager fileExistsAtPath:appOpenLogPath]) {
		NSString *appOpenUrlString = [NSString stringWithFormat:@"http://%@/m/open?v=2&udid=%@&id=%@",
																HOSTNAME,
																[[UIDevice currentDevice] uniqueIdentifier],
																  @"agltb3B1Yi1pbmNyCQsSA0FwcBgBDA" // Application ID
									 ];
		NSLog(@"MOPUB: Reporing application did launch for the first time to mopub: %@",appOpenUrlString);
		NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:appOpenUrlString]];
		NSURLResponse *response;
		NSError *error = nil;
		NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		if((!error) && ([(NSHTTPURLResponse *)response statusCode] == 200) && ([responseData length] > 0)) {
			[fileManager createFileAtPath:appOpenLogPath contents:nil attributes:nil]; 
		}
	}
	[pool release];
}

@end
