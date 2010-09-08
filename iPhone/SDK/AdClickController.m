//
//  AdClickController.m
//  SimpleAds
//
//  Created by Jim Payne on 1/31/10.
//

#import "AdClickController.h"


@implementation AdClickController

@synthesize delegate;
@synthesize webView;
@synthesize backButton, forwardButton, refreshButton, safariButton, doneButton;
@synthesize loading;
@synthesize initialLoad;
@synthesize url;

static NSArray *SAFARI_SCHEMES, *SAFARI_HOSTS;

+ (void)initialize {
	SAFARI_SCHEMES = [[NSArray arrayWithObjects:
					  @"tel",
					  @"sms",
					  nil] retain];
	SAFARI_HOSTS = [[NSArray arrayWithObjects:
					@"phobos.apple.com",
					@"maps.google.com",
					nil] retain];
}

- (id)initWithURL:(NSURL *)u delegate:(id<AdControllerDelegate>) d {
	[self initWithNibName:@"AdClickController" bundle:nil];
	self.delegate = d;
	self.url = u;
	return self;
}

- (IBAction) openInSafari {
	UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil
															 delegate:self 
													cancelButtonTitle:@"Cancel" 
											   destructiveButtonTitle:nil 
													otherButtonTitles:@"Open in Safari", nil];
	[actionSheet showInView:self.view];
	[actionSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		// open in safari please
		NSURL* u = [self.webView.request URL];
		[[UIApplication sharedApplication] openURL:u];
	}
}

- (IBAction) refresh {
	[self.webView reload];
}

- (IBAction) done {
	[self dismissModalViewControllerAnimated:TRUE];
}

- (IBAction) back {
	[self.webView goBack];
	self.backButton.enabled = self.webView.canGoBack;
	self.forwardButton.enabled = self.webView.canGoForward;
}

- (IBAction) forward {
	[self.webView goForward];
	self.backButton.enabled = self.webView.canGoBack;
	self.forwardButton.enabled = self.webView.canGoForward;
}

- (BOOL)webView:(UIWebView *)w shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	NSLog(@"%@", request.URL);
	if ([SAFARI_HOSTS containsObject:request.URL.host] || 
		[SAFARI_SCHEMES containsObject:request.URL.scheme]) {
		[self dismissModalViewControllerAnimated:NO];
		[[UIApplication sharedApplication] openURL:request.URL];
		return NO;
	} else {
		return YES;
	}
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
	[self.initialLoad stopAnimating];
	[self.loading startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	[self.loading stopAnimating];
	
	self.refreshButton.enabled = YES;
	self.safariButton.enabled = YES;	
	self.backButton.enabled = self.webView.canGoBack;
	self.forwardButton.enabled = self.webView.canGoForward;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Could not load page" message:[error localizedDescription] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	// load the url
	[self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
	
	// set back button image
	CGImageRef theCGImage = [self createBackArrowImageRef];
	UIImage *backImage = [[UIImage alloc] initWithCGImage:theCGImage];
	CGImageRelease(theCGImage);
	self.backButton.image = backImage;
	
	// set fwd button image
	CGImageRef theCGImage2 = [self createForwardArrowImageRef];
	UIImage *fwdImage = [[UIImage alloc] initWithCGImage:theCGImage2];
	CGImageRelease(theCGImage2);
	self.forwardButton.image = fwdImage;	
	
	// disable button items
	self.backButton.enabled = NO;
	self.forwardButton.enabled = NO;
	self.refreshButton.enabled = NO;
	self.safariButton.enabled = NO;
}

- (CGContextRef)createContext
{
	// create the bitmap context
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(nil,27,27,8,0,
												 colorSpace,kCGImageAlphaPremultipliedLast);
	CFRelease(colorSpace);
	return context;
}

- (CGImageRef)createBackArrowImageRef
{
	CGContextRef context = [self createContext];
	
	// set the fill color
	CGColorRef fillColor = [[UIColor blackColor] CGColor];
	CGContextSetFillColor(context, CGColorGetComponents(fillColor));
	
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, 8.0f, 13.0f);
	CGContextAddLineToPoint(context, 24.0f, 4.0f);
	CGContextAddLineToPoint(context, 24.0f, 22.0f);
	CGContextClosePath(context);
	CGContextFillPath(context);
	
	// convert the context into a CGImageRef
	CGImageRef image = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	
	return image;
}

- (CGImageRef)createForwardArrowImageRef
{
	CGContextRef context = [self createContext];
	
	// set the fill color
	CGColorRef fillColor = [[UIColor blackColor] CGColor];
	CGContextSetFillColor(context, CGColorGetComponents(fillColor));
	
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, 24.0f, 13.0f);
	CGContextAddLineToPoint(context, 8.0f, 4.0f);
	CGContextAddLineToPoint(context, 8.0f, 22.0f);
	CGContextClosePath(context);
	CGContextFillPath(context);
	
	// convert the context into a CGImageRef
	CGImageRef image = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	
	return image;
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
	self.webView.delegate = nil;
}


@end
