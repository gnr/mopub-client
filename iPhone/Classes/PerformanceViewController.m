//
//  PerformanceViewController.m
//  SimpleAds
//
//  Created by James Payne on 2/4/11.
//  Copyright 2011 MoPub Inc. All rights reserved.
//

#import "PerformanceViewController.h"

@implementation PerformanceViewController

@synthesize console;
@synthesize keyword;
@synthesize adController;
@synthesize adView;

- (void)viewDidLoad {
    [super viewDidLoad];
	[self clearConsole];
}

-(void)adControllerWillLoadAd:(AdController*)_adController {
	[self outputLine:[NSString stringWithFormat:@"Calling MoPub with %@", _adController.url]];
}

- (void)adControllerDidReceiveResponseParams:(NSDictionary *)params{
	[self outputLine:[NSString stringWithFormat:@"Server response received: %@", params]];
}

- (void)adControllerDidLoadAd:(AdController *)_adController{
	[self outputLine:@"Ad was loaded. Success."];
	[self outputLine:[NSString stringWithFormat:@"Payload (%d octets) = %@", [_adController.data length], [[NSString alloc] initWithData:_adController.data encoding:NSUTF8StringEncoding]]];
}

- (void)adControllerFailedLoadAd:(AdController *)_adController{
	[self outputLine:@"Ad did not load."];
	[self outputLine:[NSString stringWithFormat:@"Payload (%d octets) = %@", [_adController.data length], [[NSString alloc] initWithData:_adController.data encoding:NSUTF8StringEncoding]]];
}

- (IBAction) refreshAd {
	[keyword resignFirstResponder];
	
	// start timer here
	[self clearConsole];
	_adRequestStartTime = [NSDate timeIntervalSinceReferenceDate];
	
	// 320x50 size
	self.adController = [[AdController alloc] initWithSize:self.adView.frame.size adUnitId:PUB_ID_320x50 parentViewController:self];
	self.adController.delegate = self;
	self.adController.keywords = self.keyword.text;
	[self.adView addSubview:self.adController.view];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[self refreshAd];
	return YES;
}

- (void) clearConsole {
	self.console.font = [UIFont fontWithName:@"Courier" size:10];
	self.console.text = @"MoPub Ad Loading Console\n=========================";
}

- (void) outputLine:(NSString*)line {
	self.console.text = [self.console.text stringByAppendingFormat:@"\n[%.3f] %@", [NSDate timeIntervalSinceReferenceDate] - _adRequestStartTime, line];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.keyword = nil;
	self.adController = nil;
	self.adView = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
