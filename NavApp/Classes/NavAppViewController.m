//
//  NavAppViewController.m
//  NavApp
//
//  Created by Nafis Jamal on 4/20/11.
//  Copyright 2011 MoPub. All rights reserved.
//

#import "NavAppViewController.h"
#import "MPAdView.h"

@implementation NavAppViewController



- (IBAction)push:(id)sender{
	NavAppViewController *vc = [[NavAppViewController alloc] initWithNibName:@"NavAppViewController" bundle:nil];
	[self.navigationController pushViewController:vc animated:YES];
	[vc release];
 }
	 

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

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	mpAdView = [[MPAdView alloc] initWithAdUnitId:@"agltb3B1Yi1pbmNyDAsSBFNpdGUYkaoMDA" size:MOPUB_BANNER_SIZE];
	mpAdView.delegate = self;
	[mpAdView loadAd];
	[adView addSubview:mpAdView];
	[mpAdView release];
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
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	mpAdView.delegate = nil;
	[mpAdView release];
	NSLog(@"deallocing vc");
    [super dealloc];
}

@end
