//
//  PerformanceViewController.h
//  SimpleAds
//
//  Created by James Payne on 2/4/11.
//  Copyright 2011 MoPub Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdController.h"

#define PUB_ID_320x50 @"agltb3B1Yi1pbmNyDAsSBFNpdGUYkaoMDA"

@interface PerformanceViewController : UIViewController <AdControllerDelegate, UITextFieldDelegate> {
	IBOutlet UITextView* console;
	
	IBOutlet UITextField* keyword;
	IBOutlet UIView* adView;
	
	AdController* adController;
	
	NSTimeInterval _adRequestStartTime;
}
@property(nonatomic,retain) IBOutlet UITextView* console;

@property(nonatomic,retain) IBOutlet UITextField* keyword;
@property(nonatomic,retain) IBOutlet UIView* adView;
@property(nonatomic,retain) AdController* adController;

-(IBAction) refreshAd;
-(void) clearConsole;
-(void) outputLine:(NSString*)line;

@end
