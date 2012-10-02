//
//  MPAdBrowserController.m
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 MoPub, Inc. All rights reserved.
//

#import "MPAdBrowserController.h"
#import "MPLogging.h"

@interface MPAdBrowserController ()

@property (nonatomic, retain) UIActionSheet *actionSheet;

- (void)dismissActionSheet;
- (BOOL)shouldLeaveApplicationForURL:(NSURL *)URL;
- (void)leaveApplicationForURL:(NSURL *)URL;
- (void)dismissBrowserAndOpenURL:(NSURL *)URL;
- (void)dismissFromPresentingViewControllerAnimated:(BOOL)animated;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MPAdBrowserController

@synthesize webView = _webView;
@synthesize backButton = _backButton;
@synthesize forwardButton = _forwardButton;
@synthesize refreshButton = _refreshButton;
@synthesize safariButton = _safariButton;
@synthesize doneButton = _doneButton;
@synthesize spinnerItem = _spinnerItem;
@synthesize actionSheet = _actionSheet;
@synthesize delegate = _delegate;
@synthesize URL = _URL;

static NSArray *BROWSER_SCHEMES, *SPECIAL_HOSTS;

+ (void)initialize
{
	// Schemes that should be handled by the in-app browser.
	BROWSER_SCHEMES = [[NSArray arrayWithObjects:
						@"http",
						@"https",
						nil] retain];
	
	// Hosts that should be handled by the OS.
	SPECIAL_HOSTS = [[NSArray arrayWithObjects:
					  @"phobos.apple.com",
                      @"maps.apple.com",
					  @"maps.google.com",
                      @"itunes.apple.com",
					  nil] retain];
}

#pragma mark -
#pragma mark Lifecycle

- (id)initWithURL:(NSURL *)URL delegate:(id<MPAdBrowserControllerDelegate>)delegate
{
	if (self = [super initWithNibName:@"MPAdBrowserController" bundle:nil])
	{
		_delegate = delegate;
		_URL = [URL copy];
		MPLogDebug(@"Ad browser (%p) initialized with URL: %@", self, _URL);
		
		_webView = [[UIWebView alloc] initWithFrame:CGRectZero];
		_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | 
		UIViewAutoresizingFlexibleHeight;
		_webView.delegate = self;
		_webView.scalesPageToFit = YES;
		
		_spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectZero];
		[_spinner sizeToFit];
		_spinner.hidesWhenStopped = YES;
	}
	return self;
}

- (void)dealloc
{
	_delegate = nil;
	_webView.delegate = nil;
	[_webView release];
	[_URL release];
	[_backButton release];
	[_forwardButton release];
	[_refreshButton release];
	[_safariButton release];
	[_doneButton release];
	[_spinner release];
	[_spinnerItem release];
	[_actionSheet release];
	[super dealloc];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
    // Set up toolbar buttons
	self.backButton.image = [self backArrowImage];
	self.backButton.title = nil;
	self.forwardButton.image = [self forwardArrowImage];
	self.forwardButton.title = nil;
	self.spinnerItem.customView = _spinner;	
	self.spinnerItem.title = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	// Set button enabled status.
	_backButton.enabled = _webView.canGoBack;
	_forwardButton.enabled = _webView.canGoForward;
	_refreshButton.enabled = NO;
	_safariButton.enabled = NO;
    
    if (animated) {
        _isPerformingPresentationAnimation = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    _isPerformingPresentationAnimation = NO;
}

- (void)startLoading
{
    // XXX: Make sure that the view is loaded and initialized first; otherwise, the webview doesn't
    // seem to render anything, even though it launches the requests.
    [self view];
    
    [self stopLoading];
    
    _webViewLoadCount = 0;
    _hasLeftApplicationForCurrentURL = NO;
    _webView.delegate = self;
	[_webView loadRequest:[NSURLRequest requestWithURL:self.URL]];
}

- (void)stopLoading
{
    [_webView stopLoading];
    _webView.delegate = nil;
}

#pragma mark -
#pragma mark Navigation

- (IBAction)refresh 
{
	[self dismissActionSheet];
	[_webView reload];
}

- (IBAction)done 
{
	[self dismissActionSheet];
    
    // Ensure that the browser controller gets dismissed even if its delegate is set to nil.
    if (self.delegate) {
        [self.delegate dismissBrowserController:self];
    } else {
        [self dismissFromPresentingViewControllerAnimated:YES];
    }
}

- (IBAction)back
{
	[self dismissActionSheet];
	[_webView goBack];
	_backButton.enabled = _webView.canGoBack;
	_forwardButton.enabled = _webView.canGoForward;
}

- (IBAction)forward 
{
	[self dismissActionSheet];
	[_webView goForward];
	_backButton.enabled = _webView.canGoBack;
	_forwardButton.enabled = _webView.canGoForward;
}

- (IBAction)safari
{
	if (_actionSheetIsShowing)
	{
		[self dismissActionSheet];
	}
	else 
	{
		self.actionSheet = [[[UIActionSheet alloc] initWithTitle:nil
													   delegate:self 
											  cancelButtonTitle:@"Cancel" 
										 destructiveButtonTitle:nil 
											  otherButtonTitles:@"Open in Safari", nil] autorelease];
		
        if ([UIActionSheet instancesRespondToSelector:@selector(showFromBarButtonItem:animated:)]) {
            [self.actionSheet showFromBarButtonItem:self.safariButton animated:YES];
        } else {
            [self.actionSheet showInView:self.webView];
        }
	}
}

- (void)dismissActionSheet
{
	[self.actionSheet dismissWithClickedButtonIndex:0 animated:YES];
	
}

#pragma mark -
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex 
{
	if (buttonIndex == 0) 
	{
		// Open in Safari.
		[[UIApplication sharedApplication] openURL:_webView.request.URL];
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	_actionSheetIsShowing = NO;
}

- (void)didPresentActionSheet:(UIActionSheet *)actionSheet
{
	_actionSheetIsShowing = YES;
}

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request 
 navigationType:(UIWebViewNavigationType)navigationType 
{
	MPLogDebug(@"Ad browser (%p) starting to load URL: %@", self, request.URL);
    
    if ([self shouldLeaveApplicationForURL:request.URL]) {
        [self leaveApplicationForURL:request.URL];
        return NO;
    } else {
        return YES;
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	_refreshButton.enabled = YES;
	_safariButton.enabled = YES;
	[_spinner startAnimating];
    
    _webViewLoadCount++;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView 
{
    _webViewLoadCount--;
    if (_webViewLoadCount > 0) return;
    
	_refreshButton.enabled = YES;
	_safariButton.enabled = YES;	
	_backButton.enabled = _webView.canGoBack;
	_forwardButton.enabled = _webView.canGoForward;
	[_spinner stopAnimating];
    
    // XXX: The check prevents the -browserControllerDidFinishLoad: callback from firing after the
    // browser has triggered navigation away from the current application.
    if (_hasLeftApplicationForCurrentURL) return;
    
    if ([self.delegate respondsToSelector:@selector(browserControllerDidFinishLoad:)]) {
        [self.delegate browserControllerDidFinishLoad:self];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error 
{
    _webViewLoadCount--;
    
    _refreshButton.enabled = YES;
	_safariButton.enabled = YES;
	_backButton.enabled = _webView.canGoBack;
	_forwardButton.enabled = _webView.canGoForward;
	[_spinner stopAnimating];
    
    // Ignore NSURLErrorDomain error (-999).
    if (error.code == NSURLErrorCancelled) return;
    
    // Ignore "Frame Load Interrupted" errors after navigating to iTunes or the App Store.
    if (error.code == 102 && [error.domain isEqual:@"WebKitErrorDomain"]) return;
    
	MPLogError(@"Ad browser (%p) experienced an error: %@.", self, [error localizedDescription]);
}

#pragma mark - Internal

#define kModalTransitionDelay 0.4

- (BOOL)shouldLeaveApplicationForURL:(NSURL *)URL
{
    // Allow the OS to handle the following types of URLs:
    // 1) URLs with a non-http(s) scheme satisfying -[UIApplication canOpenURL:].
    if (![BROWSER_SCHEMES containsObject:URL.scheme]) {
        return [[UIApplication sharedApplication] canOpenURL:URL];
    }
    
    // 2) URLs with an http(s) scheme whose host is one of the pre-defined special hosts.
    if ([SPECIAL_HOSTS containsObject:URL.host]) {
        return YES;
    }
    
    // 3) URLs with an http(s) scheme whose host has one of the special hosts as a suffix.
    for (NSString *host in SPECIAL_HOSTS) {
        if ([URL.host hasSuffix:host]) {
            return YES;
        }
    }
    
    // All other URLs should be loaded directly in the in-app browser.
    return NO;
}

- (void)leaveApplicationForURL:(NSURL *)URL
{
    _hasLeftApplicationForCurrentURL = YES;
    
    // XXX: It's possible that our browser may try to leave the application very shortly after
    // receiving a -webViewDidFinishLoad: callback (e.g. if a landing page uses window.location
    // right after the page is downloaded). When this happens, the browser's delegate will be asked
    // to dismiss the browser, possibly during its modal transition animation. To avoid warnings or
    // potential crashes, we use a short delay to allow the animation to finish before proceeding.
    
    if (_isPerformingPresentationAnimation) {
        [self performSelector:@selector(dismissBrowserAndOpenURL:) withObject:URL
                   afterDelay:kModalTransitionDelay];
    } else {
        // The browser may not have been presented to the screen yet (i.e. it may still be loading
        // in the background); if that's the case, don't call any dismissal methods.
        BOOL isOnscreen = !!self.view.window;
        if (isOnscreen) {
            [self dismissBrowserAndOpenURL:URL];
        } else {
            if ([self.delegate respondsToSelector:@selector(browserControllerWillLeaveApplication:)]) {
                [self.delegate browserControllerWillLeaveApplication:self];
            }
            [[UIApplication sharedApplication] openURL:URL];
        }
    }
}

- (void)dismissBrowserAndOpenURL:(NSURL *)URL
{
    if ([self.delegate respondsToSelector:@selector(browserControllerWillLeaveApplication:)]) {
        [self.delegate browserControllerWillLeaveApplication:self];
    }
    
    // Ensure that the browser controller gets dismissed even if its delegate is set to nil.
    if (self.delegate) {
        [self.delegate dismissBrowserController:self animated:NO]; 
    } else {
        [self dismissFromPresentingViewControllerAnimated:NO];
    }
    
    [[UIApplication sharedApplication] openURL:URL];
}

- (void)dismissFromPresentingViewControllerAnimated:(BOOL)animated
{
    UIViewController *presentingViewController;
    
    if ([self respondsToSelector:@selector(presentingViewController)]) {
        // For iOS 5 and above.
        presentingViewController = self.presentingViewController;
    } else {
        // Prior to iOS 5, the parentViewController property holds the presenting view controller.
        presentingViewController = self.parentViewController;
    }
    
#if NS_BLOCKS_AVAILABLE
    if ([presentingViewController respondsToSelector:@selector(dismissViewControllerAnimated:completion:)]) {
        [presentingViewController dismissViewControllerAnimated:animated completion:nil];
        return;
    }
#endif
    [presentingViewController dismissModalViewControllerAnimated:animated];
}

#pragma mark -
#pragma mark Drawing

- (CGContextRef)createContext
{
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(nil,27,27,8,0,
												 colorSpace,kCGImageAlphaPremultipliedLast);
	CFRelease(colorSpace);
	return context;
}

- (UIImage *)backArrowImage
{
	CGContextRef context = [self createContext];
	CGColorRef fillColor = [[UIColor blackColor] CGColor];
	CGContextSetFillColor(context, CGColorGetComponents(fillColor));
	
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, 8.0f, 13.0f);
	CGContextAddLineToPoint(context, 24.0f, 4.0f);
	CGContextAddLineToPoint(context, 24.0f, 22.0f);
	CGContextClosePath(context);
	CGContextFillPath(context);
	
	CGImageRef imageRef = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	
	UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
	CGImageRelease(imageRef);
	return [image autorelease];
}

- (UIImage *)forwardArrowImage
{
	CGContextRef context = [self createContext];
	CGColorRef fillColor = [[UIColor blackColor] CGColor];
	CGContextSetFillColor(context, CGColorGetComponents(fillColor));
	
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, 24.0f, 13.0f);
	CGContextAddLineToPoint(context, 8.0f, 4.0f);
	CGContextAddLineToPoint(context, 8.0f, 22.0f);
	CGContextClosePath(context);
	CGContextFillPath(context);
	
	CGImageRef imageRef = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	
	UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
	CGImageRelease(imageRef);
	return [image autorelease];
}

#pragma mark -

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return YES;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


@end
