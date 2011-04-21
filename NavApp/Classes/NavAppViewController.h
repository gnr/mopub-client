//
//  NavAppViewController.h
//  NavApp
//
//  Created by Nafis Jamal on 4/20/11.
//  Copyright 2011 MoPub. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPAdView.h"


@interface NavAppViewController : UIViewController <MPAdViewDelegate> {

	IBOutlet UIView *adView;
	MPAdView *mpAdView;
}

- (IBAction)push:(id)sender;	 

@end

