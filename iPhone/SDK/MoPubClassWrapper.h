//
//  MoPubClassWrapper.h
//  Copyright (c) 2010 MoPub Inc.
//
//  Created by Nafis Jamal on 9/21/10.
//


#import <Foundation/Foundation.h>

@interface MoPubClassWrapper : NSObject {
  Class theClass;
}

- (id)initWithClass:(Class)c;

@property (nonatomic, readonly) Class theClass;

@end
