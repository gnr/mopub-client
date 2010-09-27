//
//  AdClickController.h
//  SimpleAds
//

#import <UIKit/UIKit.h>
#import "AdController.h"

@interface AdClickController : UIViewController <UIWebViewDelegate, UIActionSheetDelegate> {
	id<AdControllerDelegate> delegate;
	
	IBOutlet UIWebView* webView;
	IBOutlet UIBarButtonItem* backButton;
	IBOutlet UIBarButtonItem* forwardButton;
	IBOutlet UIBarButtonItem* refreshButton;
	IBOutlet UIBarButtonItem* safariButton;
	IBOutlet UIBarButtonItem* doneButton;
	
	IBOutlet UIActivityIndicatorView* loading;
	IBOutlet UIActivityIndicatorView* initialLoad;
	
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
