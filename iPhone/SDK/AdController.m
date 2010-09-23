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
	{300, 250},
};
NSString* FORMAT_CODES[] = {
	@"320x50",
	@"300x250",
	@"728x90",
	@"468x60",
	@"300x250",
};

@interface AdController (Internal)
- (void)backfillWithNothing;
- (void)backfillWithADBannerView;
@end

	
@implementation AdController

@synthesize delegate;
@synthesize loaded;
@synthesize format, publisherId;
@synthesize webView, loading;
@synthesize parent, keywords, location;
@synthesize data, url;
@synthesize nativeAdView;
@synthesize clickURL;

-(id)initWithFormat:(AdControllerFormat)f publisherId:(NSString *)p parentViewController:(UIViewController*)pvc {
	if (self = [super init]){
		self.data = [NSMutableData data];

		// set format + publisherId, the two immutable properties of this ad controller
		self.parent = pvc;
		self.format = f;
		self.publisherId = p;
		
		self.webView = [[TouchableWebView alloc] initWithFrame:CGRectZero];
		self.webView.delegate = self;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResign:) name:UIApplicationWillResignActiveNotification object:nil];
	}	

	// create the webview and activity indicator in the requisite shape
	return self;
		
}

- (void)dealloc{
	[data release];
	[parent release];
	[publisherId release];
	webView.delegate = nil;
	[webView release];
	
	[keywords release];
	[location release];
	[loading release];
	[url release];
	[nativeAdView release];
	[clickURL release];
	
	[super dealloc];
}

/*
 * Override the view loading mechanism to create a WebView with overlaid activity indicator
 */
-(void)loadView {
	// get dimensions for format
	int width = FORMAT_SIZES[self.format][0], height = FORMAT_SIZES[self.format][1];
		
	// create view substructure
	self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
	
	// activity indicator, placed in the center
	self.loading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	self.loading.frame = CGRectMake((width - self.loading.bounds.size.width) / 2, (height - self.loading.bounds.size.height) / 2, 
									self.loading.bounds.size.width, self.loading.bounds.size.height);
	self.loading.hidesWhenStopped = YES;
	
	// web view - use a custom TouchableWebView to prevent "bouncing"
	self.webView.frame = self.view.frame;
	
	// add them 
	[self.view addSubview:self.webView];
	[self.view addSubview:self.loading];	
}

- (void)loadAd{
	[self refresh];
}

-(void)refresh {
	NSString* f = FORMAT_CODES[self.format];
	self.loaded = FALSE;
	
	// remove the native view
	if (self.nativeAdView) {
		[self.nativeAdView removeFromSuperview];
		[self.nativeAdView release];
		self.nativeAdView = nil;
	}

	//
	// determine the appropriate URL based on the parameters provided to us
	//
	if (self.location) {
		self.url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/m/ad?v=1&f=%@&udid=%@&ll=%f,%f&q=%@&id=%@", 
										 HOSTNAME,
										 f,
										 [[UIDevice currentDevice] uniqueIdentifier],
										 location.coordinate.latitude,
										 location.coordinate.longitude,
										 [keywords stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
										 [publisherId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	} else {
		self.url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/m/ad?v=1&f=%@&udid=%@&q=%@&id=%@", 
										 HOSTNAME,
										 f,
										 [[UIDevice currentDevice] uniqueIdentifier],
										 [keywords stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
										 [publisherId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	}
	
	// inform delegate we are about to start loading...
	if ([(NSObject *)self.delegate respondsToSelector:@selector(adControllerWillLoadAd:)]) {
		[self.delegate adControllerWillLoadAd:self];
	}
	
	// We load manually so that we can check for a special backfill header 
	// that instructs us to do some native things on occasion 
	NSLog(@"ad loading via %@", self.url);
	
	// fire off request
	[self.loading startAnimating];
	NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
	[[NSURLConnection alloc] initWithRequest:request delegate:self];	
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[self.data setLength:0];

	// check for backfill headers
	NSString* backfillKey = [[(NSHTTPURLResponse*)response allHeaderFields] objectForKey:@"X-Backfill"];
	if ([backfillKey isEqualToString:@"iAd"]) {
		self.loaded = TRUE;
		[self.loading stopAnimating];
		[connection cancel];
		
		[self backfillWithADBannerView];
	} else if ([backfillKey isEqualToString:@"clear"]) {
		self.loaded = TRUE;
		[self.loading stopAnimating];
		[connection cancel];
		
		[self backfillWithNothing];
	}
	
	// grab the clickthrough URL from the headers as well 
	self.clickURL = [[(NSHTTPURLResponse*)response allHeaderFields] objectForKey:@"X-Clickthrough"];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d {
	[self.data appendData:d];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSLog(@"failed to load ad content... %@", error);
	[self backfillWithNothing];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	// set the content into the webview	
	NSLog(@"connection did finish loading");
	[self.webView loadData:self.data MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:self.url];
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
	[self refresh];
}

// when the content has loaded, we stop the loading indicator
- (void)webViewDidFinishLoad:(UIWebView *)webView {
	[self.loading stopAnimating];
}

- (void)didSelectClose:(id)sender{
	// no-op interstitials
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	NSLog(@"shouldStartLoadWithRequest URL:%@ navigationType:%d", [[request URL] absoluteString], navigationType);
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
					[self.delegate adControllerDidLoadAd:self];
				}
				return NO;
			}
		}
	}
	else if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		// escape the redirect url
		NSMutableString *redirectUrl = [NSMutableString stringWithString:[[request URL] absoluteString]];
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
		
		// create ad click URL
		NSURL* adClickURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&r=%@",
													   self.clickURL,
													   redirectUrl]];
		
		// go get it
		NSLog(@"%@", adClickURL);
		if ([(NSObject *)self.delegate respondsToSelector:@selector(adControllerAdWillOpen:)]) {
			[self.delegate adControllerAdWillOpen:self];
		}
		AdClickController* adClickController = [[AdClickController alloc] initWithURL:adClickURL delegate:self.delegate];
		[self.parent presentModalViewController:adClickController animated:TRUE];
		return NO;
	} else {
		// other javascript loads, etc. 
		return YES;
	}
	
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
	} else {
		// iOS versions before 4 
		[self backfillWithNothing];
	}
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
	[UIView beginAnimations:@"animateAdBannerOff" context:NULL];
	banner.frame = CGRectOffset(banner.frame, 0, 480);
	[UIView commitAnimations];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {	
	// ping the clickURL without a redirect parameter, for logging
	NSURLRequest* iAdClickURL = [NSURLRequest requestWithURL:[NSURL URLWithString:self.clickURL]];
	NSURLConnection* c = [[NSURLConnection alloc] initWithRequest:iAdClickURL delegate:nil];
	[c start];
	
	// pass along to our own delegate
	if ([(NSObject *)self.delegate respondsToSelector:@selector(adControllerAdWillOpen:)]) {
		[self.delegate adControllerAdWillOpen:self];
	}
	return YES;
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

- (void)dealloc {
    [super dealloc];
}


@end
