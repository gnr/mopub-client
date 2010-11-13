//
//  MoPubGoogleAdSenseAdapter.h
//  Copyright (c) 2010 MoPub Inc.
//
//  Created by Nafis Jamal on 9/21/10.
//

#import "MoPubGoogleAdSenseAdapter.h"
#import "AdController.h"

static NSDictionary *GAdHdrToAttr;

@interface MoPubGoogleAdSenseAdapter (Internal)

- (NSNumber *)GtestadrequestKeyConvert:(NSString *)str;
- (NSArray *)GchannelidsKeyConvert:(NSString *)str;
- (NSString *)GadtypeKeyConvert:(NSString *)str;

@end


@implementation MoPubGoogleAdSenseAdapter

@synthesize adViewController;

+ (NSString *)networkType {
  return @"adsense";
}

+ (void)load {
	[[MoPubNativeSDKRegistry sharedRegistry] registerClass:self];
	
	GAdHdrToAttr = [[NSDictionary alloc] initWithObjectsAndKeys:
					kGADAdSenseClientID,@"Gclientid",
					kGADAdSenseCompanyName,@"Gcompanyname",
					kGADAdSenseAppName,@"Gappname",
					kGADAdSenseApplicationAppleID,@"Gappid",
					kGADAdSenseKeywords,@"Gkeywords",
					kGADAdSenseIsTestAdRequest,@"Gtestadrequest",
					kGADAdSenseAppWebContentURL,@"Gappwebcontenturl", 
					kGADAdSenseChannelIDs,@"Gchannelids",
					kGADAdSenseAdType,@"Gadtype",
					kGADAdSenseHostID,@"Ghostid",
					kGADAdSenseAdBackgroundColor,@"Gbackgroundcolor",
					kGADAdSenseAdTopBackgroundColor,@"Gadtopbackgroundcolor",
					kGADAdSenseAdBorderColor,@"Gadbordercolor",
					kGADAdSenseAdLinkColor,@"Gadlinkcolor",
					kGADAdSenseAdTextColor,@"Gadtextcolor",
					kGADAdSenseAdURLColor,@"Gadurlolor",
					kGADExpandDirection,@"Gexpandirection",
					kGADAdSenseAlternateAdColor,@"Galternateadcolor",
					kGADAdSenseAlternateAdURL,@"Galternateadurl",
					kGADAdSenseAllowAdsafeMedium,@"Gallowadsafemedium",
					nil];
	
}

- (NSNumber *)GtestadrequestKeyConvert:(NSString *)str{
	return [NSNumber numberWithInt:[str intValue]];
}

- (NSArray *)GchannelidsKeyConvert:(NSString *)str{
	// chop off [" and "]
	str = [str substringWithRange:NSMakeRange(2, [str length] - 4)];
	return [str componentsSeparatedByString:@"', '"]; 
}

- (NSString *)GadtypeKeyConvert:(NSString *)str{
	if ([str isEqual:@"GADAdSenseTextAdType"])
		return kGADAdSenseTextAdType;
	if ([str isEqual:@"GADAdSenseImageAdType"])
		return kGADAdSenseImageAdType;
	if ([str isEqual:@"GADAdSenseTextImageAdType"])
		return kGADAdSenseTextImageAdType; 
	return kGADAdSenseTextImageAdType;
}


- (void)getAdWithParams:(NSDictionary *)params{	
	NSLog(@"MOPUB: fetching GAd");
	adViewController = [[GADAdViewController alloc] initWithDelegate:self];
	
	NSMutableDictionary *attributes = [[NSMutableDictionary alloc] initWithCapacity:5];
	
	NSDictionary *adSenseParameters = [self simpleJsonStringToDictionary:[params objectForKey:@"X-Nativeparams"]];
	
	for (NSString *key in adSenseParameters){
		NSObject *value = [adSenseParameters objectForKey:key];
		if (value && ![(NSString *)value isEqual:@""]) {
			SEL selector = NSSelectorFromString([NSString stringWithFormat:@"%@KeyConvert:",key]);
			if ([self respondsToSelector:selector]){
				value = [self performSelector:selector withObject:(NSString *)value];
			}
			[attributes setObject:value forKey:[GAdHdrToAttr objectForKey:key]];
		}				
	}
	
	
	CGFloat width = [[params objectForKey:@"X-Width"] floatValue];
	CGFloat height = [[params objectForKey:@"X-Height"] floatValue];
	
	if (width == 320.0 && height == 50.0){
		adViewController.adSize = kGADAdSize320x50; 
	}
	else if (width == 300.0 && height == 250.0){
		adViewController.adSize = kGADAdSize300x250;
	}
	else if (width == 468.0 && height == 60.0){
		adViewController.adSize = kGADAdSize468x60;
	}
	else if (width == 728.0 && height == 90.0){
		adViewController.adSize = kGADAdSize728x90;
	}
	
	[adViewController loadGoogleAd:attributes];
	[attributes release];
	
	adViewController.view.frame = CGRectMake(adController.view.frame.origin.x, adController.view.frame.origin.y, width, height);
	self.adController.nativeAdView = adViewController.view;
	self.adController.nativeAdViewController = adViewController;
	
	[self.adController.view addSubview:adViewController.view];
	
	// hide the webview so that it doesn't shine through
	self.adController.webView.hidden = YES;
		
}

- (void)dealloc {
  adViewController.delegate = nil;
  [adViewController release];
  [super dealloc];
}


#pragma mark GADAdViewControllerDelegate required methods

- (UIViewController *)viewControllerForModalPresentation:(GADAdViewController *)controller {
	return self.adController.parent;
}

#pragma mark GADAdViewControllerDelegate notification methods

- (void)loadSucceeded:(GADAdViewController *)_adController withResults:(NSDictionary *)results {
	NSLog(@"MOPUB: GAd Load Succeeded");
	[self.adController nativeAdLoadSucceededWithResults:results];
}

- (void)loadFailed:(GADAdViewController *)_adController withError:(NSError *) error {	
	[self.adController nativeAdLoadFailedwithError:error];
}

- (GADAdClickAction)adControllerActionModelForAdClick:(GADAdViewController *)controller {
	[self.adController nativeAdTrackAdClick];
	return GAD_ACTION_DISPLAY_INTERNAL_WEBSITE_VIEW; // full screen web view
}

- (void)adControllerDidCloseWebsiteView:(GADAdViewController *)controller {
//  [self helperNotifyDelegateOfFullScreenModalDismissal];
}

- (void)adControllerDidExpandAd:(GADAdViewController *)controller {
//  [self helperNotifyDelegateOfFullScreenModal];
}

- (void)adControllerDidCollapseAd:(GADAdViewController *)controller {
//  [self helperNotifyDelegateOfFullScreenModalDismissal];
}

@end
