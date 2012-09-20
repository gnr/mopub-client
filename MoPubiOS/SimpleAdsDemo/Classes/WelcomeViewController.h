//
//  WelcomeViewController.h
//  SimpleAds
//
//  Created by James Payne on 2/3/11.
//  Copyright 2011 MoPub Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WelcomeViewController : UIViewController {
    UIImageView *_welcomeImageView;
}

@property (nonatomic, retain) IBOutlet UIImageView *welcomeImageView;

- (IBAction)visitWebsite;

@end
