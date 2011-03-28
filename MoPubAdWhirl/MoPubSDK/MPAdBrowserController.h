//
//  MPAdBrowserController.h
//  MoPub
//
//  Created by Nafis Jamal on 1/19/11.
//  Copyright 2011 MoPub, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MPAdBrowserControllerDelegate;

@interface MPAdBrowserController : UIViewController <UIWebViewDelegate, UIActionSheetDelegate>
{
	id<MPAdBrowserControllerDelegate> _delegate;
	UIWebView *_webView;
	UIBarButtonItem *_backButton;
	UIBarButtonItem *_forwardButton;
	UIBarButtonItem *_refreshButton;
	UIBarButtonItem *_safariButton;
	UIBarButtonItem *_doneButton;
	UIActivityIndicatorView *_spinner;
	UIBarButtonItem *_spinnerItem;
	NSURL *_URL;
}

- (id)initWithURL:(NSURL *)URL delegate:(id<MPAdBrowserControllerDelegate>)delegate;

// Navigation methods.
- (void)back;
- (void)forward;
- (void)refresh;
- (void)safari;
- (void)done;

// Drawing methods.
- (CGContextRef)createContext;
- (UIImage *)backArrowImage;
- (UIImage *)forwardArrowImage;

@property (nonatomic, assign) id<MPAdBrowserControllerDelegate> delegate;
@property (nonatomic, copy) NSURL *URL;

@end

@protocol MPAdBrowserControllerDelegate <NSObject>
@required
- (void)dismissBrowserController:(MPAdBrowserController *)browserController;
@end