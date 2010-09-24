//
//  InterstitialAdController.h
//  SimpleAds
//
//  Created by Nafis Jamal on 9/21/10.
//  Copyright 2010 Stanford. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AdController.h"

@interface InterstitialAdController : AdController {
}

- (id)initWithPublisherId:(NSString *)p parentViewController:(UIViewController*)pvc;


@end

@protocol InterstitialAdControllerDelegate

@optional

-(void)interstitialDidClose:(InterstitialAdController *)interstitialAdController;

@end
