//
//  MoPubClassWrapper.h=m
//  Copyright (c) 2010 MoPub Inc.
//
//  Created by Nafis Jamal on 9/21/10.
//

#import "MoPubClassWrapper.h"

@implementation MoPubClassWrapper

@synthesize theClass;

- (id)initWithClass:(Class)c {
  self = [super init];
  if (self != nil) {
    theClass = c;
  }
  return self;
}

@end
