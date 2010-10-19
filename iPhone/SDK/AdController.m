//
//  AdController.m
//  Copyright (c) 2010 MoPub Inc.
//

#import "AdController.h"
#import "AdClickController.h"
#import <CoreLocation/CoreLocation.h>
#import <iAd/iAd.h>

#ifdef GoogleAdSenseAvailable
	#import "GADAdViewController.h"
	#import "GADAdSenseParameters.h"
#endif

@interface TouchableWebView : UIWebView  {
}
@end

@implementation TouchableWebView

- (id) initWithFrame:(CGRect)frame{
		if (self = [super initWithFrame:frame]){
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
		
		// WebViews are subclass of NSObject and not UIScrollView and therefore don't allow customization.
		// However, a UIWebView is a UIScrollViewDelegate, so it must CONTAIN a ScrollView somewhere.
		// To use a web view like a scroll view, let's traverse the view hierarchy to find the scroll view inside the web view.
		UIScrollView* _scrollView = nil;
		for (UIView* v in self.subviews){
			if ([v isKindOfClass:[UIScrollView class]]){
				_scrollView = (UIScrollView*)v; 
				break;
			}
		}
		if (_scrollView) {
			_scrollView.scrollEnabled = NO;
			_scrollView.bounces = NO;
		}
	}
	return self;
}
@end

@interface AdController (Internal)
- (void)backfillWithNothing;
- (void)backfillWithADBannerView;
- (void)backfillWithAdSenseWithParams:(NSDictionary *)params;

- (NSString *)escapeURL:(NSURL *)urlIn;
- (void)adClickHelper:(NSURL *)desiredURL;
- (void)loadAdWithURL:(NSURL *)adUrl;
@end

# ifdef GoogleAdSenseAvailable
static NSDictionary *GAdHdrToAttr;
# endif
	
@implementation AdController

@synthesize delegate;
@synthesize loaded;
@synthesize adUnitId;
@synthesize size;
@synthesize webView, loadingIndicator;
@synthesize parent, keywords, location;
@synthesize data, url, failURL;
@synthesize nativeAdView, nativeAdViewController;
@synthesize clickURL;
@synthesize newPageURLString;


# ifdef GoogleAdSenseAvailable
+ (void)load {
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
# endif


- (id)initWithSize:(CGSize)_size adUnitId:(NSString*)a parentViewController:(UIViewController*)pvc{
	if (self = [super init]){
		self.data = [NSMutableData data];
		
		// set format + publisherId, the two immutable properties of this ad controller
		self.parent = pvc;
		self.size = _size;
		self.adUnitId = a;
		
		// init the webview and add self as the delegate
		webView = [[TouchableWebView alloc] initWithFrame:CGRectZero];
		webView.delegate = self;
		
		// initialize ad Loading to False
		adLoading = NO;
		_isInterstitial = NO;
		
		// init the exclude parameter list
		excludeParams = [[NSMutableArray alloc] initWithCapacity:1];
		
		// add self to receive notifications that the application will resign
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResign:) name:UIApplicationWillResignActiveNotification object:nil];
	}	
	return self;
}

- (void)setNativeAdViewController:(UIViewController *)vc{
	[vc retain];
	// unsubscribe as delegate
	if ([nativeAdViewController respondsToSelector:@selector(setDelegate:)]){
		[nativeAdViewController performSelector:@selector(setDelegate:) withObject:nil];
	}
	[nativeAdViewController release];
	nativeAdViewController = vc;
}

- (void)dealloc{
	[data release];
	[parent release];
	[adUnitId release];
	
	// first nil out the delegate so that this
	// object doesn't receive any more messages
	// then release the webview
	webView.delegate = nil;
	[webView release];

	[keywords release];
	[location release];
	[loadingIndicator release];
	[url release];
	[nativeAdView release];
	
	if ([nativeAdViewController respondsToSelector:@selector(setDelegate:)]){
		[nativeAdViewController performSelector:@selector(setDelegate:) withObject:nil];
	}
	[nativeAdViewController release];
	
	[clickURL release];
	[excludeParams release];
	[newPageURLString release];
	
	[failURL release];
	[super dealloc];
}

/*
 * Override the view loading mechanism to create a WebView with overlaid activity indicator
 */
-(void)loadView {
	
	// create view substructure
	UIView *thisView = [[UIView alloc] initWithFrame:CGRectMake(0.0,0.0,self.size.width,self.size.height)];
	self.view = thisView;
	[thisView release];
	
}

- (void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
}

- (void)loadAdWithURL:(NSURL *)adUrl{
	// only loads if its not already in the process of getting the assets
	if (!adLoading){
		adLoading = YES;
		self.loaded = FALSE;
		
		// remove the native view
		if (self.nativeAdView) {
			[self.nativeAdView removeFromSuperview];
			((ADBannerView *)self.nativeAdView).delegate = nil;
			self.nativeAdView = nil;
		}
		
		//
		// create URL based on the parameters provided to us if a url was not passed in
		//
		if (!adUrl){
			NSString *urlString = [NSString stringWithFormat:@"http://%@/m/ad?v=2&udid=%@&q=%@&id=%@", 
								   HOSTNAME,
								   [[UIDevice currentDevice] uniqueIdentifier],
								   [keywords stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
								   [adUnitId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
								   ];
			
			// append on location if it has been passed in
			if (self.location){
				urlString = [urlString stringByAppendingFormat:@"&ll=%f,%f",location.coordinate.latitude,location.coordinate.longitude];
			}
			
			// add all the exclude parameters
			for (NSString *excludeParam in excludeParams){
				urlString = [urlString stringByAppendingFormat:@"&exclude=%@",excludeParam];
			}
			
			self.url = [NSURL URLWithString:urlString];
		}
		else {
			self.url = adUrl;
		}

		
		// inform delegate we are about to start loading...
		if ([self.delegate respondsToSelector:@selector(adControllerWillLoadAd:)]) {
			[self.delegate adControllerWillLoadAd:self];
		}
		
		// We load manually so that we can check for a special backfill header 
		// that instructs us to do some native things on occasion 
		NSLog(@"MOPUB: ad loading via %@", self.url);

		// start the spinner
		[self.loadingIndicator startAnimating];
		
		// fire off request
		NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:3.0];
		
		// sets the user agent so that we know where the request is coming from !important for targeting!
		if ([request respondsToSelector:@selector(setValue:forHTTPHeaderField:)]) {
			NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
			NSString *systemName = [[UIDevice currentDevice] systemName];
			NSString *model = [[UIDevice currentDevice] model];
			NSString *bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
			NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];			
			NSString *userAgentString = [NSString stringWithFormat:@"%@/%@ (%@; U; CPU %@ %@ like Mac OS X; %@)",
																	bundleName,appVersion,model,
																	systemName,systemVersion,[[NSLocale currentLocale] localeIdentifier]];
			[request setValue:userAgentString forHTTPHeaderField:@"User_Agent"];
		}		
		
		[[NSURLConnection alloc] initWithRequest:request delegate:self];
	}
}

-(void) loadAd{
	[self loadAdWithURL:nil];
}

-(void)refresh {
	// start afresh 
	[excludeParams removeAllObjects];
	// load the ad again
	[self loadAd];
}

- (void)closeAd{
	// act as though the application close of the ad is the same as the user's
	[self didSelectClose:nil];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	
	//
	// if the response is anything but a 200 (OK) or 300 (redirect) we call the response a failure and bail
	//
	if ([response respondsToSelector:@selector(statusCode)])
	{
		int statusCode = [((NSHTTPURLResponse *)response) statusCode];
		if (statusCode >= 400)
		{
			[connection cancel];  // stop connecting; no more delegate messages
			NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:
												  NSLocalizedString(@"Server returned status code %d",@""),
												  statusCode]
										  forKey:NSLocalizedDescriptionKey];
			NSError *statusError = [NSError errorWithDomain:@"mopub.com"
								  code:statusCode
							  userInfo:errorInfo];
			[self connection:connection didFailWithError:statusError];
			return;
		}
	}
	
	// initialize the data
	[self.data setLength:0];
	
	if ([delegate respondsToSelector:@selector(adControllerDidReceiveResponseParams:)]){
		[delegate performSelector:@selector(adControllerDidReceiveResponseParams:) withObject:[(NSHTTPURLResponse*)response allHeaderFields]];
	}
	
	// grab the clickthrough URL from the headers as well 
	self.clickURL = [[(NSHTTPURLResponse*)response allHeaderFields] objectForKey:@"X-Clickthrough"];
	
	// grab the url string that should be intercepted for the launch of a new page (c.admob.com, c.google.com, etc)
	self.newPageURLString = [[(NSHTTPURLResponse*)response allHeaderFields] objectForKey:@"X-Launchpage"];
	
	// grab the fail URL for rollover from the headers as well
	NSString *failURLString = [[(NSHTTPURLResponse*)response allHeaderFields] objectForKey:@"X-Failurl"];
	if (failURLString)
		self.failURL = [NSURL URLWithString:failURLString];

	// check for ad types
	NSString* adTypeKey = [[(NSHTTPURLResponse*)response allHeaderFields] objectForKey:@"X-Adtype"];
	if ([adTypeKey isEqualToString:@"iAd"]) {
		self.loaded = TRUE;
		[self.loadingIndicator stopAnimating];
		adLoading = NO;
		[connection cancel];
		[connection release];	
		[self backfillWithADBannerView];
	} else if ([adTypeKey isEqualToString:@"adsense"]){
		self.loaded = TRUE;
		[self.loadingIndicator stopAnimating];
		adLoading = NO;
		[connection cancel];
		[connection release];
		[self backfillWithAdSenseWithParams:[(NSHTTPURLResponse *)response allHeaderFields]];	
	} else if ([adTypeKey isEqualToString:@"clear"]) {
		self.loaded = TRUE;
		[self.loadingIndicator stopAnimating];
		adLoading = NO;
		[connection cancel];
		[connection release];
		[self backfillWithNothing];
	}
	
}

// standard data appending
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d {
	[self.data appendData:d];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSLog(@"MOPUB: failed to load ad content... %@", error);
	
	[self backfillWithNothing];
	[connection release];
	adLoading = NO;
	[loadingIndicator stopAnimating];
	
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	// set the content into the webview	
	[self.webView loadData:self.data MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:self.url];

	// print out the response for debugging purposes
	NSString *response = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
	NSLog(@"MOPUB: %@",response);
	[response release];
	
	// set ad loading to be False
	adLoading = NO;
	
	// release the connection
	[connection release];
}

- (void)viewDidAppear:(BOOL)animated{
	// tell the webpage that the webview has been presented to the user
	// this is a good place to fire of the tracking pixel and/or begin animations
	[self.webView stringByEvaluatingJavaScriptFromString:@"webviewDidAppear();"]; 
	[super viewDidAppear:animated];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	// activity indicator, placed in the center
	loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];

	loadingIndicator.center = self.view.center;
	loadingIndicator.hidesWhenStopped = YES;
	
	// web view - use a custom TouchableWebView to prevent "bouncing"
	self.webView.frame = self.view.frame;
	self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	
	// add them 
	[self.view addSubview:self.loadingIndicator];	
	
	// put the webview on the page but hide it until its loaded
	[self.view addSubview:self.webView];
	
	
	// if the ad has already been loaded or is in the process of being loaded
	// do nothing otherwise load the ad
	if (!adLoading && !loaded){
		[self loadAd];
	}
}

// when the content has loaded, we stop the loading indicator
- (void)webViewDidFinishLoad:(UIWebView *)_webView {
	[self.loadingIndicator stopAnimating];
//	[self.webView setNeedsDisplay];

	// show the webview because we know it has been loaded
	self.webView.hidden = NO;

}

- (void)didSelectClose:(id)sender{
	// tell the webpage that the webview has been dismissed by the user
	// this is a good place to record time spent on site
	[self.webView stringByEvaluatingJavaScriptFromString:@"webviewDidClose();"]; 
}


// Intercept special urls
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	NSLog(@"MOPUB: shouldStartLoadWithRequest URL:%@ navigationType:%d", [[request URL] absoluteString], navigationType);
	
	if (navigationType == UIWebViewNavigationTypeOther){
		NSURL *requestURL = [request URL];
		
		// intercept mopub specific urls mopub://close, mopub://finishLoad, mopub://failLoad
		if ([[requestURL scheme] isEqual:@"mopub"]){
			if ([[requestURL host] isEqual:@"close"]){
				// lets the delegate (self) that the webview would like to close itself, only really matter for interstital
				[self didSelectClose:nil];
				return NO;
			}
			else if ([[requestURL host] isEqual:@"finishLoad"]){
				//lets the delegate know that the the ad has succesfully loaded 
				loaded = YES;
				adLoading = NO;
				if ([self.delegate respondsToSelector:@selector(adControllerDidLoadAd:)]) {
					[self.delegate adControllerDidLoadAd:self];
				}
				self.webView.hidden = NO;
				return NO;
			}
			else if ([[requestURL host] isEqual:@"failLoad"]){
				//lets the delegate know that the the ad has failed to be loaded 
				loaded = YES;
				adLoading = NO;
				if ([self.delegate respondsToSelector:@selector(adControllerFailedLoadAd:)]) {
					[self.delegate adControllerFailedLoadAd:self];
				}
				self.webView.hidden = NO;
				return NO;
			}
		}
		// interecepts special url that we want to intercept ex: c.admob.com
		if (self.newPageURLString){
			if ([[requestURL absoluteString] hasPrefix:self.newPageURLString]){
				[self adClickHelper:[request URL]];
				return NO;
			}
		}
	}
	// interecept user clicks to open appropriately
	else if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		[self adClickHelper:[request URL]];
		return NO;
	}
	// other javascript loads, etc. 
	return YES;
}

- (void)adClickHelper:(NSURL *)desiredURL{
	// escape the redirect url
	NSString *redirectUrl = [self escapeURL:desiredURL];										
	
	// create ad click URL
	NSURL* adClickURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&r=%@",
											  self.clickURL,
											  redirectUrl]];
	
	
	if ([self.delegate respondsToSelector:@selector(adControllerAdWillOpen:)]) {
		[self.delegate adControllerAdWillOpen:self];
	}
	
	
	// inited but release in the dealloc
	AdClickController *_adClickController = [[AdClickController alloc] initWithURL:adClickURL delegate:self]; 
	
	// signal to the delegate if it cares that the click controller is about to be presented
	if ([self.delegate respondsToSelector:@selector(willPresentModalViewForAd:)]){
		[self.delegate performSelector:@selector(willPresentModalViewForAd:) withObject:self];
	}
	
	// if the ad is being show as an interstitial then this view may load another modal view
	// otherwise, the ad is just a subview of what is on screen, so the parent should load the modal view
	if (_isInterstitial){
		[self presentModalViewController:_adClickController animated:YES];
	}
	else {
		[self.parent presentModalViewController:_adClickController animated:YES];
	}
	
	// signal to the delegate if it cares that the click controller has been presented
	if ([self.delegate respondsToSelector:@selector(didPresentModalViewForAd:)]){
		[self.delegate performSelector:@selector(didPresentModalViewForAd:) withObject:self];
	}
	
	[_adClickController release];
}


- (void)dismissModalViewForAdClickController:(AdClickController *)_adClickController{
	// signal to the delegate if it cares that the click controller is about to be torn down
	if ([self.delegate respondsToSelector:@selector(willPresentModalViewForAd:)]){
		[self.delegate performSelector:@selector(willPresentModalViewForAd:) withObject:self];
	}
	
	
	[_adClickController dismissModalViewControllerAnimated:YES];
	
	// signal to the delegate if it cares that the click controller has been torn down
	if ([self.delegate respondsToSelector:@selector(didPresentModalViewForAd:)]){
		[self.delegate performSelector:@selector(didPresentModalViewForAd:) withObject:self];
	}
	
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	NSLog(@"MOPUB: Ad load failed with error: %@", error);
}


#pragma mark -
#pragma mark Special backfill strategies: ADBannerView, display a solid color

- (void)backfillWithNothing {
	self.webView.backgroundColor = [UIColor clearColor];

	// let delegate know that the ad has failed to load
	if ([self.delegate respondsToSelector:@selector(adControllerFailedLoadAd:)]){
		[self.delegate adControllerFailedLoadAd:self];
	}
	
}

#pragma mark
#pragma mark AFMA implementation
#pragma mark 

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

- (void)backfillWithAdSenseWithParams:(NSDictionary *)params{
# ifdef GoogleAdSenseAvailable
	NSLog(@"MOPUB: fetching GAd");
	GADAdViewController *adViewController = [[GADAdViewController alloc] initWithDelegate:(id<GADAdViewControllerDelegate>)self];
	
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
	adViewController.view.frame = CGRectMake(0.0, 0.0, width, height);
	self.nativeAdView = adViewController.view;
	self.nativeAdViewController = adViewController;
		
	[self.view addSubview:self.nativeAdView];
	
	// hide the webview so that it doesn't shine through
	self.webView.hidden = YES;

# else
	[self loadAdWithURL:self.failURL];
# endif	
	
}

# ifdef GoogleAdSenseAvailable
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


- (UIViewController *)viewControllerForModalPresentation:
(GADAdViewController *)adController {
	return parent;
}

// Called each time the ad has been clicked
- (GADAdClickAction)adControllerActionModelForAdClick:
(GADAdViewController *)adController {
	// track the click on the mopub servers
	NSURLRequest* gAdClickURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:self.clickURL]];
	[[[NSURLConnection alloc] initWithRequest:gAdClickURLRequest delegate:nil] autorelease];
	NSLog(@"MOPUB: Tracking click %@",[gAdClickURLRequest URL]);

	return GAD_ACTION_DISPLAY_INTERNAL_WEBSITE_VIEW;
}

- (void)loadSucceeded:(GADAdViewController *)adController
          withResults:(NSDictionary *)results {
	// Successful load. You can examine the results for interesting things.
	NSLog(@"GAd Load Succeeded: %@", results);
	adLoading = NO;
	if ([self.delegate respondsToSelector:@selector(adControllerDidLoadAd:)]) {
		[self.delegate adControllerDidLoadAd:self];
	}
	
}

- (void)loadFailed:(GADAdViewController *)adController
         withError:(NSError *) error {
	// Handle error here.
	NSLog(@"MOPUB: Failed to load GAD %@",error);
	
	if (self.nativeAdView) {
		[self.nativeAdView removeFromSuperview];
		self.nativeAdView = nil;
	}
	
	// then try another ad call to verify see if there is another ad creative that can fill this spot
	// if this fails the delegate will be notified
	[self loadAdWithURL:self.failURL];
}
#endif


#pragma mark -
#pragma mark iAd implementation

- (void)backfillWithADBannerView {
	// put an ad in place.
	Class cls = NSClassFromString(@"ADBannerView");
	if (cls != nil) {
		ADBannerView* adBannerView = [[ADBannerView alloc] initWithFrame:self.view.frame];
		adBannerView.requiredContentSizeIdentifiers = [NSSet setWithObjects:ADBannerContentSizeIdentifier320x50, ADBannerContentSizeIdentifier480x32, nil];
		adBannerView.currentContentSizeIdentifier = ADBannerContentSizeIdentifier320x50;
		adBannerView.delegate = self;
		
		// put an AdBanner on top of the current view so it can 
		// do animations and Z ordering properly on click... 
		self.nativeAdView = adBannerView;
		[self.view.superview addSubview:self.nativeAdView];
		[adBannerView release];
				
		// hide the webview so that it doesn't shine through
		self.webView.hidden = YES;
	} else {
		// iOS versions before 4 
		[self loadAdWithURL:self.failURL];
	}
}

- (void)bannerViewDidLoadAd:(ADBannerView *)banner{
	adLoading = NO;
	if ([self.delegate respondsToSelector:@selector(adControllerDidLoadAd:)]) {
		[self.delegate adControllerDidLoadAd:self];
	}
	
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
	NSLog(@"MOPUB: Failed to load iAd");
	
	
	if (self.nativeAdView) {
		[self.nativeAdView removeFromSuperview];
		self.nativeAdView = nil;
	}
	
	// then try another ad call to verify see if there is another ad creative that can fill this spot
	// if this fails the delegate will be notified
	[self loadAdWithURL:self.failURL];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {	
	// ping the clickURL without a redirect parameter, for logging
	NSURLRequest* iAdClickURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:self.clickURL]];
	[[[NSURLConnection alloc] initWithRequest:iAdClickURLRequest delegate:nil] autorelease];
	NSLog(@"MOPUB: Tracking click %@",[iAdClickURLRequest URL]);

	
	// pass along to our own delegate
	if ([self.delegate respondsToSelector:@selector(adControllerAdWillOpen:)]) {
		[self.delegate adControllerAdWillOpen:self];
	}
	return YES;
}

- (NSString *)escapeURL:(NSURL *)urlIn{
	NSMutableString *redirectUrl = [NSMutableString stringWithString:[urlIn absoluteString]];
	NSRange wholeString = NSMakeRange(0, [redirectUrl length]);
	[redirectUrl replaceOccurrencesOfString:@"&" withString:@"%26" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"+" withString:@"%2B" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"," withString:@"%2C" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"/" withString:@"%2F" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@":" withString:@"%3A" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@";" withString:@"%3B" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"=" withString:@"%3D" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"?" withString:@"%3F" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"@" withString:@"%40" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@" " withString:@"%20" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"\t" withString:@"%09" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"#" withString:@"%23" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"<" withString:@"%3C" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@">" withString:@"%3E" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"\"" withString:@"%22" options:NSCaseInsensitiveSearch range:wholeString];
	[redirectUrl replaceOccurrencesOfString:@"\n" withString:@"%0A" options:NSCaseInsensitiveSearch range:wholeString];
	
	return redirectUrl;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

// we should tell the webview that the application would like to close
// this may be called more than once, so in our logs we'll assume the last close the it correct one
- (void)applicationWillResign:(id)sender{
	[self didSelectClose:sender];
}

@end
