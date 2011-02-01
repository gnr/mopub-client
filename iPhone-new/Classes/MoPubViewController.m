//
//  MoPubViewController.m
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import "MoPubViewController.h"

@implementation MoPubViewController



/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView 
{
	self.view = [[[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]] autorelease];
	MPAdView *adView = [[MPAdView alloc] initWithFrame:CGRectMake(0, 200, 320, 50)];
	adView.delegate = self;
	[self.view addSubview:adView];
	
	UIButton *refresh = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	refresh.frame = CGRectMake(110, 280, 100, 40);
	refresh.titleLabel.text	= @"Refresh that shit";
	[refresh addTarget:adView action:@selector(refreshAd) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:refresh];
	
	[adView loadAd];
	[adView release];
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (UIViewController *)viewControllerForPresentingModalView
{
	return self;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end
