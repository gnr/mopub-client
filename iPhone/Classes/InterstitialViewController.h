//
//  InterstitialViewController.h
//  SimpleAds
//
//  Created by James Payne on 2/3/11.
//  Copyright 2011 MoPub Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdController.h"
#import "InterstitialAdController.h"
#import "SecondViewController.h"

#define PUB_ID_INTERSTITIAL @"agltb3B1Yi1pbmNyDAsSBFNpdGUYsckMDA"
#define PUB_ID_NAV_INTERSTITIAL @"agltb3B1Yi1pbmNyDAsSBFNpdGUYsbcSDA"

@class InterstitialAdController;

@interface InterstitialViewController : UIViewController <UITextFieldDelegate, InterstitialAdControllerDelegate> {
	BOOL getAndShow;
	IBOutlet UIButton* showInterstitialButton;

	InterstitialAdController *interstitialAdController;
	InterstitialAdController *navigationInterstitialAdController;
}
@property(nonatomic,retain) IBOutlet UIButton* showInterstitialButton;
@property(nonatomic,retain) AdController* adController;
@property(nonatomic,retain) AdController* mrectController;
@property(nonatomic,retain) InterstitialAdController* interstitialAdController;
@property(nonatomic,retain) InterstitialAdController* navigationInterstitialAdController;

-(IBAction) showModalInterstitial;
-(IBAction) getModalInterstitial;
-(IBAction) getAndShowModalInterstitial;
-(IBAction) getNavigationInterstitial;
-(IBAction) showNavigationInterstitial;

@end
