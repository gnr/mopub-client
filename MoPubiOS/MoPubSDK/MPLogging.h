//
//  MPLogging.h
//  MoPub
//
//  Created by Andrew He on 2/10/11.
//  Copyright 2011 MoPub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

// Debug level: 1 = Enable logging, 0 = Disable logging.
#define MPLOG_LEVEL 1

void MPLog(NSString *format,...);