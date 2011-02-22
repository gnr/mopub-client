//
//  MPLogging.m
//  MoPub
//
//  Created by Andrew He on 2/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MPLogging.h"

void MPLog(NSString *format,...)
{
    if (MPLOG_LEVEL)
    {
        va_list args;
        va_start(args,format);
        NSLogv(format, args);
        va_end(args);
    }
}
