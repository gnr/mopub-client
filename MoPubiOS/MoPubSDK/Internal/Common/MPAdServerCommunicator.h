//
//  MPAdServerCommunicator.h
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MPAdConfiguration.h"
#import "MPGlobal.h"

@protocol MPAdServerCommunicatorDelegate;

////////////////////////////////////////////////////////////////////////////////////////////////////

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= MP_IOS_5_0
@interface MPAdServerCommunicator : NSObject <NSURLConnectionDataDelegate>
#else
@interface MPAdServerCommunicator : NSObject
#endif
{
    id<MPAdServerCommunicatorDelegate> _delegate;
    NSURL *_URL;
    NSURLConnection *_connection;
    NSMutableData *_responseData;
    NSDictionary *_responseHeaders;
}

@property (nonatomic, assign) id<MPAdServerCommunicatorDelegate> delegate;
@property (nonatomic, copy) NSURL *URL;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, retain) NSDictionary *responseHeaders;

- (void)loadURL:(NSURL *)URL;
- (void)cancel;

- (NSError *)errorForStatusCode:(NSInteger)statusCode;
- (NSURLRequest *)adRequestForURL:(NSURL *)URL;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@protocol MPAdServerCommunicatorDelegate <NSObject>

@required
- (void)communicatorDidReceiveAdConfiguration:(MPAdConfiguration *)configuration;
- (void)communicatorDidFailWithError:(NSError *)error;

@end
