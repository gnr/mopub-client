//
//  MPAdBrowserController.m
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import "MPAdBrowserController.h"


@implementation MPAdBrowserController
@synthesize delegate = _delegate;
@synthesize URL = _URL;

static NSArray *SAFARI_SCHEMES, *SAFARI_HOSTS;

+ (void)initialize 
{
	SAFARI_SCHEMES = [[NSArray arrayWithObjects:
					   @"http",
					   @"https",
					   nil] retain];
	SAFARI_HOSTS = [[NSArray arrayWithObjects:
					 @"phobos.apple.com",
					 @"maps.google.com",
					 nil] retain];
}

#pragma mark -
#pragma mark Lifecycle

- (id)initWithURL:(NSURL *)URL delegate:(id<MPAdBrowserControllerDelegate>)delegate
{
	if (self = [super init])
	{
		_delegate = delegate;
		_URL = [URL copy];
		NSLog(@"URL: %@", _URL);
		
		_webView = [[UIWebView alloc] initWithFrame:CGRectZero];
		_webView.delegate = self;
		
		_spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectZero];
		[_spinner sizeToFit];
		_spinner.hidesWhenStopped = YES;
	}
	return self;
}

- (void)dealloc
{
	_delegate = nil;
	[_webView release];
	[_URL release];
	[_backButton release];
	[_forwardButton release];
	[_refreshButton release];
	[_safariButton release];
	[_doneButton release];
	[_spinner release];
	[_spinnerItem release];
	[super dealloc];
}

- (void)loadView 
{
	self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	CGFloat height = self.view.frame.size.height;
	CGFloat width = self.view.frame.size.width;
	
	// Set up toolbar.
	UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
	toolbar.barStyle = UIBarStyleBlackTranslucent;
	
	_backButton = [[UIBarButtonItem alloc] initWithImage:[self backArrowImage]
												   style:UIBarButtonItemStylePlain
												  target:self
												  action:@selector(back)];
	_forwardButton = [[UIBarButtonItem alloc] initWithImage:[self forwardArrowImage]
													  style:UIBarButtonItemStylePlain
													 target:self
													 action:@selector(forward)];
	_refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
																   target:self 
																   action:@selector(refresh)];
	_safariButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
																  target:self 
																  action:@selector(safari)];	
	_doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
																target:self 
																action:@selector(done)];
	_spinnerItem = [[UIBarButtonItem alloc] initWithCustomView:_spinner];
	
	UIBarButtonItem *spacer = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																			 target:nil
																			 action:nil] autorelease];
	NSArray *toolbarItems = [NSArray arrayWithObjects:
							 _backButton, spacer,
							 _forwardButton, spacer,
							 _refreshButton, spacer,
							 _safariButton, spacer,
							 _spinnerItem, spacer,
							 _doneButton, nil];
	[toolbar setItems:toolbarItems animated:NO];
	[toolbar sizeToFit];
	toolbar.frame = CGRectMake(0, height - toolbar.frame.size.height,
							   toolbar.frame.size.width, toolbar.frame.size.height);
	[self.view addSubview:toolbar];
	[toolbar release];
	
	// Lay out webview.
	_webView.frame = CGRectMake(0, 0, width, height - toolbar.frame.size.height);
	[self.view addSubview:_webView];
}

- (void)viewWillAppear:(BOOL)animated
{
	self.view;
	
	// Set button enabled status.
	_backButton.enabled = _webView.canGoBack;
	_forwardButton.enabled = _webView.canGoForward;
	_refreshButton.enabled = NO;
	_safariButton.enabled = NO;
	
	// Load up webview content.
	[_webView loadRequest:[NSURLRequest requestWithURL:self.URL]];
}

#pragma mark -
#pragma mark Navigation

- (void)refresh 
{
	[_webView reload];
}

- (void)done 
{
	[self.delegate dismissModalViewForBrowserController:self];
}

- (void)back 
{
	[_webView goBack];
	_backButton.enabled = _webView.canGoBack;
	_forwardButton.enabled = _webView.canGoForward;
}

- (void)forward 
{
	[_webView goForward];
	_backButton.enabled = _webView.canGoBack;
	_forwardButton.enabled = _webView.canGoForward;
}

- (void)safari
{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
															 delegate:self 
													cancelButtonTitle:@"Cancel" 
											   destructiveButtonTitle:nil 
													otherButtonTitles:@"Open in Safari", nil];
	[actionSheet showInView:self.view];
	[actionSheet release];
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

#pragma mark -
#pragma mark UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request 
 navigationType:(UIWebViewNavigationType)navigationType 
{
	NSLog(@"MOPUB: %@", request.URL);
	if ([SAFARI_SCHEMES containsObject:request.URL.scheme])
	{
		if ([SAFARI_HOSTS containsObject:request.URL.host])
		{
			[self dismissModalViewControllerAnimated:NO];
			[[UIApplication sharedApplication] openURL:request.URL];
			return NO;
		}
		else 
		{
			return YES;
		}
	} 
	else 
	{
		if ([[UIApplication sharedApplication] canOpenURL:request.URL])
		{
			[self dismissModalViewControllerAnimated:NO];
			return NO;
		}
	}
	return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView 
{
	_refreshButton.enabled = YES;
	_safariButton.enabled = YES;
	[_spinner startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView 
{
	_refreshButton.enabled = YES;
	_safariButton.enabled = YES;	
	_backButton.enabled = _webView.canGoBack;
	_forwardButton.enabled = _webView.canGoForward;
	[_spinner stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error 
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not load page." 
													message:[error localizedDescription] 
												   delegate:self 
										  cancelButtonTitle:@"OK" 
										  otherButtonTitles:nil];
	[alert show];
	[alert release];
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

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

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
