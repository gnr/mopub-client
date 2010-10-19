//
//  InterstitialAdController.h
//  Copyright (c) 2010 MoPub Inc.
//
//  Created by Nafis Jamal on 9/21/10.
//

#import <Foundation/Foundation.h>
#import "AdController.h"

enum {
	AdCloseButtonTypeDefault,
	AdCloseButtonTypeNone,
	AdCloseButtonTypeNext,
};
typedef NSUInteger AdCloseButtonType;




@protocol InterstitialAdControllerDelegate;



@interface InterstitialAdController : UIViewController <AdControllerDelegate> {
	BOOL wasStatusBarHidden;
	BOOL wasNavigationBarHidden;
	
	UIButton *closeButton;
	AdCloseButtonType closeButtonType;
	BOOL _inNavigationController;
	
	AdController* _adController;
	NSString *adUnitId;
	UIViewController *parent;
	UIColor *backgroundColor;
	
	id<InterstitialAdControllerDelegate> delegate;
	
	CGSize adSize;
}

@property (nonatomic,retain) UIButton *closeButton;
@property (nonatomic,retain) UIViewController *parent;
@property (nonatomic, assign) id<InterstitialAdControllerDelegate> delegate;
@property (nonatomic, copy) NSString *keywords;
@property (nonatomic, readonly) BOOL loaded;
@property (nonatomic, copy) NSString *adUnitId;
@property (nonatomic, retain) AdController *adController;
@property (nonatomic, retain) UIColor *backgroundColor;

+ (InterstitialAdController *)sharedInterstitialAdControllerForAdUnitId:(NSString *)a;
+ (void)removeSharedInterstitialAdController:(InterstitialAdController *)interstitialAdController;
+ (NSMutableArray *)sharedInterstitialAdControllers;

// if you are initing from the application delegate then you can say parentViewController = nil
- (id)initWithAdUnitId:(NSString *)p parentViewController:(UIViewController*)pvc;
- (void)makeCloseButton;
- (void)adControllerDidReceiveResponseParams:(NSDictionary *)params;
- (void)loadAd;

@end

@protocol InterstitialAdControllerDelegate <AdControllerDelegate>


// Sent when the interstitial would like to be removed from the screen, its up to the delegate to
// remove it
- (void)interstitialDidClose:(InterstitialAdController *)interstitialAdController;

@optional

// Sent with the interstitial content has been loaded
- (void)interstitialDidLoad:(InterstitialAdController *)interstitialAdController;


// Sent with the interstitial is about to appear, it is a good place to save state in case
// the user leaves the application from the interstitial
- (void)interstitialWillAppear:(InterstitialAdController *)interstitialAdController;

// Sent when the interstitial is on screen
- (void)interstitialDidAppear:(InterstitialAdController *)interstitialAdController;




@end
