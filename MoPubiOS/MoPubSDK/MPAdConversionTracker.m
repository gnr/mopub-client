//
//  MPAdConversionTracker.m
//  MoPub
//
//  Created by Andrew He on 2/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MPAdConversionTracker.h"
#import "MPAdView.h"

@interface MPAdConversionTracker (Internal)
- (void)reportApplicationOpenSynchronous:(NSString *)appID;
@end

@implementation MPAdConversionTracker

+ (MPAdConversionTracker *)sharedConversionTracker
{
	static MPAdConversionTracker *sharedConversionTracker;
	
	@synchronized(self)
	{
		if (!sharedConversionTracker)
			sharedConversionTracker = [[MPAdConversionTracker alloc] init];
		return sharedConversionTracker;
	}
}

- (void)reportApplicationOpenForApplicationID:(NSString *)appID
{
	[self performSelectorInBackground:@selector(reportApplicationOpenSynchronous:) withObject:appID];
}

#pragma mark -
#pragma mark Internal

- (void)reportApplicationOpenSynchronous:(NSString *)appID{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; 
	
	// Have we already reported an app open?
	NSString *documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
																  NSUserDomainMask, YES) objectAtIndex:0];
	NSString *appOpenLogPath = [documentsDir stringByAppendingPathComponent:@"mopubAppOpen.log"];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:appOpenLogPath]) 
	{
		NSString *appOpenUrlString = [NSString stringWithFormat:@"http://%@/m/open?v=3&udid=%@&id=%@",
									  HOSTNAME,
									  [[UIDevice currentDevice] hashedMoPubUDID],
									  appID 
									  ];
		MPLog(@"MOPUB: Reporting application did launch for the first time to mopub: %@", appOpenUrlString);
		NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:appOpenUrlString]];
		NSURLResponse *response;
		NSError *error = nil;
		NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
		if ((!error) && ([(NSHTTPURLResponse *)response statusCode] == 200) && ([responseData length] > 0))
			[fileManager createFileAtPath:appOpenLogPath contents:nil attributes:nil];
	}
	[pool release];
}

@end
