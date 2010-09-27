//
//  AdController.m
//  SimpleAds
//

#import "AdController.h"
#import "AdClickController.h"
#import <CoreLocation/CoreLocation.h>
#import <iAd/iAd.h>

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

int FORMAT_SIZES[][2] = {
	{320, 50},
	{300, 250},
	{728, 90},
	{468, 60},
	{320, 480},
};
NSString* FORMAT_CODES[] = {
	@"320x50",
	@"300x250",
	@"728x90",
	@"468x60",
	@"320x480",
};

@interface AdController (Internal)
- (void)backfillWithNothing;
- (void)backfillWithADBannerView;
- (NSString *)escapeURL:(NSURL *)urlIn;
- (void)adClickHelper:(NSURL *)desiredURL;
@end

	
@implementation AdController

@synthesize delegate;
@synthesize loaded;
@synthesize format, publisherId;
@synthesize webView, loadingIndicator;
@synthesize parent, keywords, location;
@synthesize data, url;
@synthesize nativeAdView;
@synthesize clickURL;
@synthesize adClickController;
@synthesize newPageURLString;

-(id)initWithFormat:(AdControllerFormat)f publisherId:(NSString *)p parentViewController:(UIViewController*)pvc {
	if (self = [super init]){
		self.data = [NSMutableData data];

		// set format + publisherId, the two immutable properties of this ad controller
		self.parent = pvc;
		self.format = f;
		self.publisherId = p;
		
		// init the webview and add self as the delegate
		webView = [[TouchableWebView alloc] initWithFrame:CGRectZero];
		webView.delegate = self;
		
		_isInterstitial = NO;
		
		// initialize ad Loading to False
		adLoading = NO;
		
		
		// init the exclude parameter list
		excludeParams = [[NSMutableArray alloc] initWithCapacity:1];
		
		// add self to receive notifications that the application will resign
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResign:) name:UIApplicationWillResignActiveNotification object:nil];
	}	

	// create the webview and activity indicator in the requisite shape
	return self;
		
}

- (void)dealloc{
	[data release];
	[parent release];
	[publisherId release];
	
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
	[clickURL release];
	[excludeParams release];
	
	adClickController.delegate = nil;
	[adClickController release];
	[super dealloc];
}

/*
 * Override the view loading mechanism to create a WebView with overlaid activity indicator
 */
-(void)loadView {
	// get dimensions for format
	int width = FORMAT_SIZES[self.format][0], height = FORMAT_SIZES[self.format][1];
	
	if (_isInterstitial) {
		width = [[UIScreen mainScreen] bounds].size.width;
		height = [[UIScreen mainScreen] bounds].size.height;
	}
	
	// create view substructure
	UIView *thisView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
	self.view = thisView;
	[thisView release];
	
	// activity indicator, placed in the center
	loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	loadingIndicator.frame = CGRectMake((width - self.loadingIndicator.bounds.size.width) / 2, (height - self.loadingIndicator.bounds.size.height) / 2, 
									self.loadingIndicator.bounds.size.width, self.loadingIndicator.bounds.size.height);
	loadingIndicator.hidesWhenStopped = YES;
	
	// web view - use a custom TouchableWebView to prevent "bouncing"
	self.webView.frame = self.view.frame;
	
	// add them 
	[self.view addSubview:self.loadingIndicator];	
	// put the webview on the page
	[self.view addSubview:self.webView];

}

- (void)loadAd{
	adLoading = YES;
	NSString* f = FORMAT_CODES[self.format];
	self.loaded = FALSE;
	
	// remove the native view
	if (self.nativeAdView) {
		[self.nativeAdView removeFromSuperview];
		self.nativeAdView = nil;
	}
	
	//
	// create URL based on the parameters provided to us
	//
	
	NSString *urlString = [NSString stringWithFormat:@"http://%@/m/ad?v=1&f=%@&udid=%@&q=%@&id=%@&w=%f&h=%f", 
						   HOSTNAME,
						   f,
						   [[UIDevice currentDevice] uniqueIdentifier],
						   [keywords stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
						   [publisherId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
						   0.0,
						   0.0
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
	
	//
	// This is a hack to always get back an interstitial
	//
	if (_isInterstitial){
		self.url = [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:8000/account/test/?w=%f&h=%f",
										 0.0,//self.view.frame.size.width,
										 0.0]];//self.view.frame.size.height]];
	}
	
	
	// inform delegate we are about to start loading...
	if ([(NSObject *)self.delegate respondsToSelector:@selector(adControllerWillLoadAd:)]) {
		[self.delegate adControllerWillLoadAd:self];
	}
	
	// We load manually so that we can check for a special backfill header 
	// that instructs us to do some native things on occasion 
	NSLog(@"MOPUB: ad loading via %@", self.url);
	
	// fire off request
	[self.loadingIndicator startAnimating];
	NSURLRequest *request = [NSURLRequest requestWithURL:self.url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:3.0];
	[[NSURLConnection alloc] initWithRequest:request delegate:self];
	

}

-(void)refresh {
	[excludeParams removeAllObjects];
	// remove the native view
	[self loadAd];
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

	// check for backfill headers
	NSString* adTypeKey = [[(NSHTTPURLResponse*)response allHeaderFields] objectForKey:@"X-Adtype"];
	if ([adTypeKey isEqualToString:@"iAd"]) {
		self.loaded = TRUE;
		[self.loadingIndicator stopAnimating];
		[connection cancel];
		[connection release];	
		[self backfillWithADBannerView];
	} else if ([adTypeKey isEqualToString:@"clear"]) {
		self.loaded = TRUE;
		[self.loadingIndicator stopAnimating];
		[connection cancel];
		[connection release];
		[self backfillWithNothing];
	}
	
	// grab the clickthrough URL from the headers as well 
	self.clickURL = [[(NSHTTPURLResponse*)response allHeaderFields] objectForKey:@"X-Clickthrough"];
	
	// grab the url string that should be intercepted for the launch of a new page (c.admob.com, c.google.com, etc)
	self.newPageURLString = [[(NSHTTPURLResponse*)response allHeaderFields] objectForKey:@"X-Launchpage"];
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
	
	// let delegate know that the ad has failed to load
	if ([(NSObject *)self.delegate respondsToSelector:@selector(adControllerFailedLoadAd:)]){
		[self.delegate adControllerFailedLoadAd:self];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	// set the content into the webview	
	[self.webView loadData:self.data MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:self.url];
	
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
	
	// if the ad has already been loaded or is in the process of being loaded
	// do nothing
	if (!adLoading && !loaded){
		[self loadAd];
	}
}

// when the content has loaded, we stop the loading indicator
- (void)webViewDidFinishLoad:(UIWebView *)_webView {
	[self.loadingIndicator stopAnimating];
	
	// show the webview because we know it has been loaded
	self.webView.hidden = NO;

}

- (void)didSelectClose:(id)sender{
	// no-op for non-interstitials
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	NSLog(@"MOPUB: shouldStartLoadWithRequest URL:%@ navigationType:%d", [[request URL] absoluteString], navigationType);
	if (navigationType == UIWebViewNavigationTypeOther){
		NSURL *requestURL = [request URL];
		if ([[requestURL scheme] isEqual:@"mopub"]){
			if ([[requestURL host] isEqual:@"done"]){
				// lets the delegate (self) that the webview would like to close itself, only really matter for interstital
				[self didSelectClose:nil];
				return NO;
			}
			else if ([[requestURL host] isEqual:@"finishLoad"]){
				loaded = YES;
				if ([(NSObject *)self.delegate respondsToSelector:@selector(adControllerDidLoadAd:)]) {
					adLoading = NO;
					[self.delegate adControllerDidLoadAd:self];
				}
				return NO;
			}
			else if ([[requestURL host] isEqual:@"failLoad"]){
				loaded = YES;
				if ([(NSObject *)self.delegate respondsToSelector:@selector(adControllerFailedLoadAd:)]) {
					adLoading = NO;
					[self.delegate adControllerFailedLoadAd:self];
				}
				return NO;
			}
		}
		if (self.newPageURLString){
			if ([[requestURL absoluteString] hasPrefix:self.newPageURLString]){
				[self adClickHelper:[request URL]];
				return NO;
			}
		}
	}
	else if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		[self adClickHelper:[request URL]];
		return NO;
	} else {
		// other javascript loads, etc. 
		return YES;
	}
	return YES;
}

- (void)adClickHelper:(NSURL *)desiredURL{
	// escape the redirect url
	NSString *redirectUrl = [self escapeURL:desiredURL];										
	
	// create ad click URL
	NSURL* adClickURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&r=%@",
											  self.clickURL,
											  redirectUrl]];
	
	
	if ([(NSObject *)self.delegate respondsToSelector:@selector(adControllerAdWillOpen:)]) {
		[self.delegate adControllerAdWillOpen:self];
	}
	
	adClickController = [[AdClickController alloc] initWithURL:adClickURL delegate:self.delegate];
	
	// if the ad is being show as an interstitial then this view may load another modal view
	// otherwise, the ad is just a subview of what is on screen, so the parent should load the modal view
	if (_isInterstitial){
		[self presentModalViewController:adClickController animated:YES];
	}
	else {
		[self.parent presentModalViewController:adClickController animated:YES];
	}
	
	[adClickController release];
	// go get it
	NSLog(@"%@", adClickURL);

}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	NSLog(@"Ad load failed with error: %@", error);
}


#pragma mark -
#pragma mark Special backfill strategies: ADBannerView, display a solid color

- (void)backfillWithNothing {
	self.webView.backgroundColor = [UIColor clearColor];
}

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
		[self backfillWithNothing];
	}
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
	NSLog(@"MOPUB: Failed to load iAd");
	
	// animate away the iAd
//	[UIView beginAnimations:@"animateAdBannerOff" context:NULL];
//	banner.frame = CGRectOffset(banner.frame, 0, 480);
//	[UIView commitAnimations];
	
	// ad iAd to the list of excludes
	[excludeParams addObject:@"iAd"];
	
	if (self.nativeAdView) {
		[self.nativeAdView removeFromSuperview];
		self.nativeAdView = nil;
	}
	
	// then try another ad call 
	[self loadAd];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {	
	// ping the clickURL without a redirect parameter, for logging
	NSURLRequest* iAdClickURL = [NSURLRequest requestWithURL:[NSURL URLWithString:self.clickURL]];
	NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:iAdClickURL delegate:nil];
	[connection start];
	
	// pass along to our own delegate
	if ([(NSObject *)self.delegate respondsToSelector:@selector(adControllerAdWillOpen:)]) {
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

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

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
