//
//  InterstitialViewController.h
//  SimpleAds
//
//  Created by James Payne on 2/3/11.
//  Copyright 2011 MoPub Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPAdView.h"
#import "MPInterstitialAdController.h"

#define PUB_ID_INTERSTITIAL @"agltb3B1Yi1pbmNyDAsSBFNpdGUYsckMDA"
#define PUB_ID_NAV_INTERSTITIAL @"agltb3B1Yi1pbmNyDAsSBFNpdGUYsbcSDA"

@class MPInterstitialAdController;

@interface InterstitialViewController : UIViewController <UITextFieldDelegate, MPInterstitialAdControllerDelegate> {
	BOOL getAndShow;
	IBOutlet UIButton* showInterstitialButton;

	MPInterstitialAdController *interstitialAdController;
}
@property(nonatomic,retain) IBOutlet UIButton* showInterstitialButton;
@property(nonatomic,retain) MPInterstitialAdController* interstitialAdController;

-(IBAction) showModalInterstitial;
-(IBAction) getModalInterstitial;
-(IBAction) getAndShowModalInterstitial;

@end
