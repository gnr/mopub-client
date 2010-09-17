//
//  SimpleAdsViewController.h
//  SimpleAds
//
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

