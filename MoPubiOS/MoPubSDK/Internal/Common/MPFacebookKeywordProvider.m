//
//  MPFacebookAttributionIdProvider.m
//  MoPub
//
//  Copyright (c) 2012 MoPub, Inc. All rights reserved.
//

#import "MPFacebookKeywordProvider.h"
#import <UIKit/UIKit.h>

@interface MPFacebookKeywordProvider ()

+ (NSString *)getFacebookAttributionId;
+ (NSString *)getFacebookAttributionKeyword;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

static NSString *kFacebookAttributionIdPasteboardKey = @"fb_app_attribution";
static NSString *kFacebookAttributionIdPrefix = @"FBATTRID:";

@implementation MPFacebookKeywordProvider

+ (NSString *)getFacebookAttributionId {
    UIPasteboard *pb = [UIPasteboard pasteboardWithName:kFacebookAttributionIdPasteboardKey
                                                 create:NO];
    if (!pb) {
        return nil;
    }
    return pb.string;
}

+ (NSString *)getFacebookAttributionKeyword {
    NSString *facebookAttributionId = [self getFacebookAttributionId];
    if (!facebookAttributionId) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@%@", kFacebookAttributionIdPrefix, facebookAttributionId];
}

#pragma mark - MPKeywordProvider

+ (NSString *)keyword {
    return [[self class] getFacebookAttributionKeyword];
}

@end
