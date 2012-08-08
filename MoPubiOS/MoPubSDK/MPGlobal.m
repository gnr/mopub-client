//
//  MPGlobal.m
//  MoPub
//
//  Created by Andrew He on 5/5/11.
//  Copyright 2011 MoPub, Inc. All rights reserved.
//

#import "MPGlobal.h"
#import "MPConstants.h"
#import <CommonCrypto/CommonDigest.h>

BOOL MPViewHasHiddenAncestor(UIView *view);
BOOL MPViewIsDescendantOfKeyWindow(UIView *view);
BOOL MPViewIntersectsKeyWindow(UIView *view);
NSString *MPGenerateIdentifierForAdvertising();
BOOL MPSDKVersionIsGreaterThan(NSString *version);

UIInterfaceOrientation MPInterfaceOrientation()
{
	return [UIApplication sharedApplication].statusBarOrientation;
}

UIWindow *MPKeyWindow()
{
    return [UIApplication sharedApplication].keyWindow;
}

CGFloat MPStatusBarHeight() {
    if ([UIApplication sharedApplication].statusBarHidden) return 0.0;
    
    UIInterfaceOrientation orientation = MPInterfaceOrientation();
    
    return UIInterfaceOrientationIsLandscape(orientation) ?
        CGRectGetWidth([UIApplication sharedApplication].statusBarFrame) :
        CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
}

CGRect MPApplicationFrame()
{
    CGRect frame = MPScreenBounds();
    
    frame.origin.y += MPStatusBarHeight();
    frame.size.height -= MPStatusBarHeight();
    
    return frame;
}

CGRect MPScreenBounds()
{
	CGRect bounds = [UIScreen mainScreen].bounds;
	
	if (UIInterfaceOrientationIsLandscape(MPInterfaceOrientation()))
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

NSDictionary *MPDictionaryFromQueryString(NSString *query) {
    NSMutableDictionary *queryDict = [NSMutableDictionary dictionary];
	NSArray *queryElements = [query componentsSeparatedByString:@"&"];
	for (NSString *element in queryElements) {
		NSArray *keyVal = [element componentsSeparatedByString:@"="];
		NSString *key = [keyVal objectAtIndex:0];
		NSString *value = [keyVal lastObject];
		[queryDict setObject:[value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] 
					  forKey:key];
	}
	return queryDict;
}

NSString *MPIdentifierForAdvertising()
{
	static NSString *cachedIdentifier = nil;
    
    if (cachedIdentifier) return cachedIdentifier;
    
    NSString *cachedIdVersion;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    cachedIdentifier = [[userDefaults objectForKey:MOPUB_IDENTIFIER_DEFAULTS_KEY] retain];
    cachedIdVersion = [userDefaults objectForKey:MOPUB_IDENTIFIER_VERSION_DEFAULTS_KEY];
    
    if (!cachedIdentifier || !cachedIdVersion || MPSDKVersionIsGreaterThan(cachedIdVersion)) {
        [cachedIdentifier release];
        cachedIdentifier = [MPGenerateIdentifierForAdvertising() retain];
        [userDefaults setObject:cachedIdentifier forKey:MOPUB_IDENTIFIER_DEFAULTS_KEY];
        [userDefaults setObject:MP_SDK_VERSION forKey:MOPUB_IDENTIFIER_VERSION_DEFAULTS_KEY];
        [userDefaults synchronize];
    }
    
	return cachedIdentifier;
}

NSString *MPGenerateIdentifierForAdvertising()
{
    // In iOS 6, the identifierForAdvertising property of UIDevice can be used to uniquely identify
    // a device for advertising purposes. Devices running OS versions prior to iOS 6 will not be
    // identifiable.
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 60000
    if (![UIDevice instancesRespondToSelector:@selector(identifierForAdvertising)]) {
        return @"";
    }
    
    NSString *identifier = [[[UIDevice currentDevice] identifierForAdvertising] UUIDString];
    return [NSString stringWithFormat:@"ifa:%@", [identifier uppercaseString]];
#else
    return @"";
#endif
}

BOOL MPSDKVersionIsGreaterThan(NSString *version)
{
    return ([MP_SDK_VERSION compare:version options:NSNumericSearch] == NSOrderedDescending);
}

BOOL MPViewIsVisible(UIView *view)
{
    // In order for a view to be visible, it:
    // 1) must not be hidden,
    // 2) must not have an ancestor that is hidden,
    // 3) must be a descendant of the key window, and
    // 4) must be within the frame of the key window.
    //
    // Note: this function does not check whether any part of the view is obscured by another view.
    
    return (!view.hidden &&
            !MPViewHasHiddenAncestor(view) &&
            MPViewIsDescendantOfKeyWindow(view) &&
            MPViewIntersectsKeyWindow(view));
}

BOOL MPViewHasHiddenAncestor(UIView *view)
{
    UIView *ancestor = view.superview;
    while (ancestor) {
        if (ancestor.hidden) return YES;
        ancestor = ancestor.superview;
    }
    return NO;
}

BOOL MPViewIsDescendantOfKeyWindow(UIView *view)
{
    UIView *ancestor = view.superview;
    UIWindow *keyWindow = MPKeyWindow();
    while (ancestor) {
        if (ancestor == keyWindow) return YES;
        ancestor = ancestor.superview;
    }
    return NO;
}

BOOL MPViewIntersectsKeyWindow(UIView *view)
{
    UIWindow *keyWindow = MPKeyWindow();
    
    // We need to call convertRect:toView: on this view's superview rather than on this view itself.
    CGRect viewFrameInWindowCoordinates = [view.superview convertRect:view.frame toView:keyWindow];
    
    return CGRectIntersectsRect(viewFrameInWindowCoordinates, keyWindow.frame);
}

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CJSONDeserializer (MPAdditions)

+ (CJSONDeserializer *)deserializerWithNullObject:(id)obj
{
    CJSONDeserializer *deserializer = [CJSONDeserializer deserializer];
    deserializer.nullObject = obj;
    return deserializer;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

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
