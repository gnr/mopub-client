//
//  MPStore.h
//  MoPub
//
//  Created by Andrew He on 2/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@protocol MPStoreObserver <NSObject>
@optional
- (void)storeTransactionDidComplete:(SKPaymentTransaction *)transaction;
- (void)storeTransactionDidFail:(SKPaymentTransaction *)transaction;
- (void)storeTransactionDidRestore:(SKPaymentTransaction *)transaction;
@end

@interface MPStore : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
	id<MPStoreObserver> _delegate;
}

+ (MPStore *)sharedStore;
- (void)initiatePurchaseForProductIdentifier:(NSString *)identifier quantity:(NSInteger)quantity;
- (void)requestProductDataForProductIdentifier:(NSString *)identifier;
- (void)startPaymentForProductIdentifier:(NSString *)identifier;
- (void)recordTransaction:(SKPaymentTransaction *)transaction;

@property (nonatomic, assign) id<MPStoreObserver> delegate;

@end

