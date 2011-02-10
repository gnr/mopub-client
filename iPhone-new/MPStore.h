//
//  MPStore.h
//  MoPub
//
//  Created by Andrew He on 2/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface MPStore : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
	BOOL _isProcessing;
	NSInteger _quantity;
}

+ (MPStore *)sharedStore;
- (void)initiatePurchaseForProductIdentifier:(NSString *)identifier quantity:(NSInteger)quantity;
- (void)requestProductDataForProductIdentifier:(NSString *)identifier;
- (void)startPaymentForProductIdentifier:(NSString *)identifier;
- (void)recordTransaction:(SKPaymentTransaction *)transaction;

@end

