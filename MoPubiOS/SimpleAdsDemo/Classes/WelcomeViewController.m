//
//  WelcomeViewController.m
//  SimpleAds
//
//  Created by James Payne on 2/3/11.
//  Copyright 2011 MoPub Inc. All rights reserved.
//

#import "WelcomeViewController.h"


@implementation WelcomeViewController

@synthesize welcomeImageView = _welcomeImageView;

- (void)viewDidLoad
{
    if ([UIScreen mainScreen].bounds.size.height == 568) {
        UIImage *backgroundImage = [UIImage imageNamed:@"Default-568h@2x.png"];
        self.welcomeImageView.image = backgroundImage;
    } else {
        UIImage *backgroundImage = [UIImage imageNamed:@"Default.png"];
        self.welcomeImageView.image = backgroundImage;
    }
}

- (IBAction)visitWebsite {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.mopub.com"]];
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

- (void)dealloc {
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
