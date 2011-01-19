//
//  MoPubAlertAdAdapter.m
//  MillionPhoto
//
//  Created by Nafis Jamal on 12/12/10.
//  Copyright 2010 Stanford. All rights reserved.
//

#import "MoPubAlertAdAdapter.h"

@implementation MoPubAlertAdAdapter

+ (NSString *)networkType {
	return @"alert";
}

- (void) dealloc{
	[alertParameters release];
	[super dealloc];
}

+ (void)load {
	[[MoPubNativeSDKRegistry sharedRegistry] registerClass:self];	
}

- (NSNumber *)GtestadrequestKeyConvert:(NSString *)str{
	return [NSNumber numberWithInt:[str intValue]];
}

- (void)getAdWithParams:(NSDictionary *)params{	
	NSLog(@"MOPUB: fetching alert ad");
	
	
	// expecting title (optional), message, cancelButtonTitle (optional), otherButtonTitle (only one), clickURL
	alertParameters = [[self simpleJsonStringToDictionary:[params objectForKey:@"X-Nativeparams"]] retain];
	
//	for (NSString *key in alertParameters){
//		NSObject *value = [alertParameters objectForKey:key];
//		if (value && ![(NSString *)value isEqual:@""]) {
//			SEL selector = NSSelectorFromString([NSString stringWithFormat:@"%@KeyConvert:",key]);
//			if ([self respondsToSelector:selector]){
//				value = [self performSelector:selector withObject:(NSString *)value];
//			}
//			[attributes setObject:value forKey:key];
//		}				
//	}
	
	NSString *cancelButtonTitle = [alertParameters objectForKey:@"cancelButtonTitle"];
	if (!cancelButtonTitle || [cancelButtonTitle isEqual:@""]){
		cancelButtonTitle = @"Cancel"; // should be localized or just passed from server
	}
	
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[alertParameters objectForKey:@"title"] 
													message:[alertParameters objectForKey:@"message"] 
												   delegate:self 
										  cancelButtonTitle:cancelButtonTitle 
										  otherButtonTitles:[alertParameters objectForKey:@"otherButtonTitle"],nil];
	[alertView show];
	[alertView release];

}

# pragma
# pragma UIAlertView Delegate
# pragma
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
	if (buttonIndex == 0) return; // cancel
	if (buttonIndex == 1){
		NSURLRequest *fakeRequest = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:[alertParameters objectForKey:@"clickURL"]]];
		[self.adController webView:nil 
		shouldStartLoadWithRequest:fakeRequest
					navigationType:UIWebViewNavigationTypeLinkClicked];
		[fakeRequest release];
	}
}

- (void)willPresentAlertView:(UIAlertView *)alertView{
	if ([self.adController.delegate respondsToSelector:@selector(willPresentModalViewForAd:)]){
		[self.adController.delegate willPresentModalViewForAd:self.adController];
	}
}

- (void)didPresentAlertView:(UIAlertView *)alertView{
	if ([self.adController.delegate respondsToSelector:@selector(didPresentModalViewForAd:)]){
		[self.adController.delegate didPresentModalViewForAd:self.adController];
	}
 }
	 

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex{
	if ([self.adController.delegate respondsToSelector:@selector(willDismissModalViewForAd:)]){
		[self.adController.delegate willDismissModalViewForAd:self.adController];
	}
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
	if ([self.adController.delegate respondsToSelector:@selector(didDismissModalViewForAd:)]){
		[self.adController.delegate didDismissModalViewForAd:self.adController];
	}
}

@end
