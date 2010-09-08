//
//  SimpleAdsViewController.h
//  SimpleAds
//
//  Created by Jim Payne on 1/31/10.
//  Copyright Apple Inc 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdController.h"

@interface SimpleAdsViewController : UIViewController <UITextFieldDelegate> {
	UITextField* keyword;
	UIView* adView;
	UIView* mrectView;
	
	AdController* adController;
	AdController* mrectController;
}
@property(nonatomic,retain) IBOutlet UITextField* keyword;
@property(nonatomic,retain) IBOutlet UIView* adView;
@property(nonatomic,retain) IBOutlet UIView* mrectView;
@property(nonatomic,retain) AdController* adController;
@property(nonatomic,retain) AdController* mrectController;
-(IBAction) refreshAd;

@end

