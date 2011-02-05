//
//  SimpleAdsViewController.m
//  Copyright (c) 2010 MoPub Inc.
//

#import "SimpleAdsViewController.h"
#import "AdController.h"
#import "InterstitialAdController.h"

@implementation SimpleAdsViewController

@synthesize keyword;
@synthesize adController, mrectController;
@synthesize adView, mrectView;

- (void)viewDidLoad {
    [super viewDidLoad];
	
	// 320x50 size
	self.adController = [[AdController alloc] initWithSize:self.adView.frame.size adUnitId:PUB_ID_320x50 parentViewController:self];
	self.adController.delegate = self;
	[self.adView addSubview:self.adController.view];
	
	// MRect size
	self.mrectController = [[AdController alloc] initWithSize:self.mrectView.frame.size adUnitId:PUB_ID_300x250 parentViewController:self];
	self.mrectController.delegate = self;
	[self.mrectView addSubview:self.mrectController.view];	
}

- (void)adControllerDidLoadAd:(AdController *)_adController{
	NSLog(@"AD DID LOAD %@", _adController);
}

- (void)adControllerFailedLoadAd:(AdController *)_adController{
	NSLog(@"AD FAILED LOAD %@", _adController);
}

- (IBAction) refreshAd {
	[keyword resignFirstResponder];
	
	// update ad 
	self.adController.keywords = keyword.text;
	[self.adController refresh];
	
	// update mrect
	self.mrectController.keywords = keyword.text;
	[self.mrectController refresh];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[self refreshAd];
	return YES;
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

- (void)dealloc{
	[adController release];
	[mrectController release];
	[super dealloc];
}

@end
