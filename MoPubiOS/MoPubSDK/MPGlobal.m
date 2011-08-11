//
//  MPGlobal.m
//  MoPub
//
//  Created by Andrew He on 5/5/11.
//  Copyright 2011 MoPub, Inc. All rights reserved.
//

#import "MPGlobal.h"
#import <CommonCrypto/CommonDigest.h>

CGRect MPScreenBounds()
{
	CGRect bounds = [UIScreen mainScreen].bounds;
	
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (UIInterfaceOrientationIsLandscape(orientation))
	{
		CGFloat width = bounds.size.width;
		bounds.size.width = bounds.size.height;
		bounds.size.height = width;
	}
	
	return bounds;
}

CGFloat MPDeviceScaleFactor()
{
	if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
		[[UIScreen mainScreen] respondsToSelector:@selector(scale)])
	{
		return [[UIScreen mainScreen] scale];
	}
	else return 1.0;
}


NSString *MPHashedUDID()
{
	static NSString *hashedUDID = nil;
	
	if (!hashedUDID) 
	{
		unsigned char digest[20];
		
		NSString *udid = [NSString stringWithFormat:@"%@", 
						  [[UIDevice currentDevice] uniqueIdentifier]];
		NSData *data = [udid dataUsingEncoding:NSASCIIStringEncoding];
		CC_SHA1([data bytes], [data length], digest);
		
		NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
		
		for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) 
		{
			[output appendFormat:@"%02x", digest[i]];
		}
		
		hashedUDID = [[NSString stringWithFormat:@"sha:%@", [output uppercaseString]] retain];
	}
	return hashedUDID;
}

NSString *MPUserAgentString()
{
	static NSString *userAgent = nil;
	
    if (!userAgent) {
        UIWebView *webview = [[UIWebView alloc] init];
        userAgent = [[webview stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"] copy];  
        [webview release];
    }
    return userAgent;
}

@implementation NSString (MPAdditions)

- (NSString *)URLEncodedString
{
	NSString *result = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
																		   (CFStringRef)self,
																		   NULL,
																		   (CFStringRef)@"!*'();:@&=+$,/?%#[]<>",
																		   kCFStringEncodingUTF8);
	return [result autorelease];
}

@end
