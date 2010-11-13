//
//  AdController.m
//  Copyright (c) 2010 MoPub Inc.
//

#import "AdController.h"
#import "AdClickController.h"
#import <CoreLocation/CoreLocation.h>

#import "MoPubNativeSDKRegistry.h"
#import "MoPubNativeSDKAdapter.h"

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
@synthesize currentAdapter, lastAdapter;



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
	
	[currentAdapter release];
	[lastAdapter release];
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

- (void)loadAdWithURL:(NSURL *)adUrl{
	// only loads if its not already in the process of getting the assets
	if (!adLoading){
		adLoading = YES;
		self.loaded = FALSE;
		
		// remove the native view
		if (self.nativeAdView) {
			[self.nativeAdView removeFromSuperview];
			if ([self respondsToSelector:@selector(setDelegate:)]) {
				[self performSelector:@selector(setDelegate:) withObject:nil];
			}
			self.nativeAdView = nil;
		}
		
		//
		// create URL based on the parameters provided to us if a url was not passed in
		//
		if (!adUrl){
			NSString *urlString = [NSString stringWithFormat:@"http://%@/m/ad?v=3&udid=%@&q=%@&id=%@", 
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
			[request setValue:userAgentString forHTTPHeaderField:@"User-Agent"];
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
	
	if (!adTypeKey || [adTypeKey isEqual:@"html"]) {
		return;
	} 
	else if ([adTypeKey isEqualToString:@"clear"]) {
		self.loaded = TRUE;
		[self.loadingIndicator stopAnimating];
		adLoading = NO;
		[connection cancel];
		[connection release];
		[self backfillWithNothing];
		return;
	}
					   
	
	Class adapterClass = [[MoPubNativeSDKRegistry sharedRegistry] adapterClassForNetworkType:adTypeKey];
	if (!adapterClass){
		adLoading = NO; // weird
		[connection cancel];
		[connection release];
		[self loadAdWithURL:self.failURL];	
		return;
	} 

	self.loaded = TRUE;
	[self.loadingIndicator stopAnimating];
	adLoading = NO;
	[connection cancel];
	[connection release];
					   
	MoPubNativeSDKAdapter *adapter = [[adapterClass alloc] initWithAdController:self];
	NSLog(@"adapterClass :%@",adapter);
	[adapter getAdWithParams:[(NSHTTPURLResponse *)response allHeaderFields]];
	self.lastAdapter = self.currentAdapter;
	self.currentAdapter = adapter;
	[adapter release];

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
	
	webView.delegate = self;
	[self.webView loadData:self.data MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:self.url];


	// print out the response for debugging purposes
	NSString *response = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
	NSLog(@"MOPUB: response %@",response);
	[response release];
	
	// set ad loading to be False
	adLoading = NO;
	
	// release the connection
	[connection release];
}

- (void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
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
	[self.webView setNeedsDisplay];

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
	self.webView.hidden = YES;

	// let delegate know that the ad has failed to load
	if ([self.delegate respondsToSelector:@selector(adControllerFailedLoadAd:)]){
		[self.delegate adControllerFailedLoadAd:self];
	}
	
}

- (void)nativeAdLoadSucceededWithResults:(NSDictionary *)results {
	// Successful load. You can examine the results for interesting things.
	adLoading = NO;
	if ([self.delegate respondsToSelector:@selector(adControllerDidLoadAd:)]) {
		[self.delegate adControllerDidLoadAd:self];
	}	
}

- (void)nativeAdTrackAdClick{
	[self nativeAdTrackAdClickWithURL:self.clickURL];
}

- (void)nativeAdTrackAdClickWithURL:(NSString *)adClickURL{
	NSURLRequest* clickURLRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:adClickURL]];
	[[[NSURLConnection alloc] initWithRequest:clickURLRequest delegate:nil] autorelease];
	NSLog(@"MOPUB: Tracking click %@",[clickURLRequest URL]);
	
	// pass along to our own delegate
	if ([self.delegate respondsToSelector:@selector(adControllerAdWillOpen:)]) {
		[self.delegate adControllerAdWillOpen:self];
	}
}

- (void)nativeAdLoadFailedwithError:(NSError *)error{
	if (self.nativeAdView) {
		[self.nativeAdView removeFromSuperview];
		self.nativeAdView = nil;
	}
	// then try another ad call to verify see if there is another ad creative that can fill this spot
	// if this fails the delegate will be notified
	[self loadAdWithURL:self.failURL];	
}

- (void)rollOver{
	[self nativeAdLoadFailedwithError:nil];
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
