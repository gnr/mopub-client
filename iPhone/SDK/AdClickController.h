//
//  AdClickController.h
//  SimpleAds
//
//  Created by Jim Payne on 1/31/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdController.h"

@interface AdClickController : UIViewController <UIWebViewDelegate, UIActionSheetDelegate> {
	id<AdControllerDelegate> delegate;
	
	UIWebView* webView;
	UIBarButtonItem* backButton;
	UIBarButtonItem* forwardButton;
	UIBarButtonItem* refreshButton;
	UIBarButtonItem* safariButton;
	UIBarButtonItem* doneButton;
	
	UIActivityIndicatorView* loading;
	UIActivityIndicatorView* initialLoad;
	
	NSURL* url;
}
@property(nonatomic, retain) id<AdControllerDelegate> delegate;

@property(nonatomic, retain) IBOutlet UIWebView* webView;
@property(nonatomic, retain) IBOutlet UIBarButtonItem* backButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem* forwardButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem* refreshButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem* safariButton;
@property(nonatomic, retain) IBOutlet UIBarButtonItem* doneButton;

@property(nonatomic, retain) IBOutlet UIActivityIndicatorView* loading;
@property(nonatomic, retain) IBOutlet UIActivityIndicatorView* initialLoad;

@property(nonatomic, retain) NSURL* url;

-(id) initWithURL:(NSURL*)u delegate:(id<AdControllerDelegate>)delegate;
-(IBAction) openInSafari;
-(IBAction) refresh;
-(IBAction) done;

-(IBAction) back;
-(IBAction) forward;

- (CGContextRef)createContext;
- (CGImageRef)createBackArrowImageRef;
- (CGImageRef)createForwardArrowImageRef;

@end
