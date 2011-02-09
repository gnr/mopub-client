//
//  MPStore.m
//  MoPub
//
//  Created by Andrew He on 2/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MPStore.h"

@implementation MPStore

+ (MPStore *)sharedStore
{
	static MPStore *sharedStoreKitObserver = nil;
	@synchronized(self)
	{
		if (sharedStore == nil)
		{
			sharedStore = [[MPStore alloc] init];
			[[SKPaymentQueue defaultQueue] addTransactionObserver:sharedStore];
		}
		return sharedStore;
	}
}

- (void)dealloc
{
	_delegate = nil;
	[super dealloc];
}

#pragma mark -

- (void)initiatePurchaseForProductIdentifier:(NSString *)identifier quantity:(NSInteger)quantity
{
	[self requestProductDataForProductIdentifier:identifier];
}

- (void)requestProductDataForProductIdentifier:(NSString *)identifer
{
	SKProductsRequest *request = [[[SKProductsRequest alloc] initWithProductIdentifiers:
								  [NSSet setWithObject:identifier]] autorelease];
	request.delegate = self;
	[request start];
}

- (void)startPaymentForProductIdentifier:(NSString *)identifer
{
	SKMutablePayment *payment = [SKMutablePayment paymentWithProductIdentifier:identifer];
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma mark -
#pragma mark SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    // TODO: populate UI
	SKProduct *product = [response.products objectAtIndex:0];
	[self startPaymentForProductIdentifier:product.productIdentifier];		  
}

#pragma mark -
#pragma mark SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
			case SKPaymentTransactionStatePurchasing:
				// TODO: show some sort of message for purchasing?
				break;
            case SKPaymentTransactionStatePurchased:
				if ([self.delegate respondsToSelector:@selector(storeTransactionDidComplete:)])
					[self.delegate storeTransactionDidComplete:transaction];
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				[self recordTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
				if ([self.delegate respondsToSelector:@selector(storeTransactionDidFail:)])
					[self.delegate storeTransactionDidFail:transaction];
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                if ([self.delegate respondsToSelector:@selector(storeTransactionDidRestore:)])
					[self.delegate storeTransactionDidRestore:transaction];
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				[self recordTransaction:transaction];
            default:
                break;
        }
    }
}

- (void)recordTransaction:(SKPaymentTransaction *)transaction 
{
	NSLog(@"MOPUB: record transaction in adcontroller: %@",transaction);
	// TODO: POST some JSON somewhere
}

@end
