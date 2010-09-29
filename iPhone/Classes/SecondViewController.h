//
//  SecondViewController.h
//  SimpleAds
//
//  Created by Nafis Jamal on 9/24/10.
//  Copyright 2010 Stanford. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "InterstitialAdController.h"

@interface SecondViewController : UIViewController <InterstitialAdControllerDelegate> {

}

- (IBAction) showInterstitial:(id)sender;

@end
