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
	self = [super initWithFrame:frame];
	self.backgroundColor = [UIColor clearColor];
	self.opaque = NO;
	
	// WebViews are subclass of NSObject and not UIScrollView and therefore don't allow customization.
	// However, a UIWebView is a UIScrollViewDelegate, so it must CONTAIN a ScrollView somewhere.
	// To use a web view like a scroll view, let's traverse the view hierarchy to find the scroll view inside the web view.
	UIScrollView* _scrollView = NULL;
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
	
	return self;
}
@end

int FORMAT_SIZES[][2] = {
	{320, 50},
	{300, 250},
	{728, 90},
	{468, 60}
};
NSString* FORMAT_CODES[] = {
	@"320x50",
	@"300x250",
	@"728x90",
	@"468x60"
};

@interface AdController ()
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
	[super init];
	self.data = [NSMutableData data];

	// set format + publisherId, the two immutable properties of this ad controller
	self.parent = [pvc retain];
	self.format = f;
	self.publisherId = [p copy];
	
	// create the webview and activity indicator in the requisite shape
	return self;
}

/*
 * Override the view loading mechanism to create a WebView with overlaid activity indicator
 */
-(void)loadView {
	// get dimensions for format
	int w = FORMAT_SIZES[self.format][0], h = FORMAT_SIZES[self.format][1];
	
	// create view substructure
	self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
	
	// activity indicator, placed in the center
	self.loading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	self.loading.frame = CGRectMake((w - self.loading.bounds.size.width) / 2, (h - self.loading.bounds.size.height) / 2, 
									self.loading.bounds.size.width, self.loading.bounds.size.height);
	self.loading.hidesWhenStopped = YES;
	
	// web view - use a custom TouchableWebView to prevent "bouncing"
	self.webView = [[TouchableWebView alloc] initWithFrame:self.view.frame];
	self.webView.delegate = self;
	
	// add them 
	[self.view addSubview:self.webView];
	[self.view addSubview:self.loading];	
}

-(void)refresh {
	NSString* f = FORMAT_CODES[self.format];
	self.loaded = FALSE;
	
	// remove the native view
	if (self.nativeAdView) {
		[self.nativeAdView removeFromSuperview];
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
	if ([self.delegate respondsToSelector:@selector(adControllerWillLoadAd:)]) {
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
	[self.webView loadData:self.data MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:self.url];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	[self refresh];
}

// when the content has loaded, we stop the loading indicator
- (void)webViewDidFinishLoad:(UIWebView *)webView {
	self.loaded = TRUE;
	[self.loading stopAnimating];
	if ([self.delegate respondsToSelector:@selector(adControllerDidLoadAd:)]) {
		[self.delegate adControllerDidLoadAd:self];
	}
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
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
		NSString* adClickURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&r=%@",
													   self.clickURL,
													   redirectUrl]];
		
		// go get it
		NSLog(@"%@", adClickURL);
		if ([self.delegate respondsToSelector:@selector(adControllerAdWillOpen:)]) {
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
	if ([self.delegate respondsToSelector:@selector(adControllerAdWillOpen:)]) {
		[self.delegate adControllerAdWillOpen:self];
	}
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

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
