//
//  OTRBuddy.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBuddy.h"
#import "OTRChatter.h"
#import "OTRAccount.h"
#import "OTRMessage.h"
#import "OTRDatabaseManager.h"
#import "YapDatabaseRelationshipTransaction.h"
#import "OTRKit.h"
#import "OTRImages.h"
#import "OTRColors.h"

const struct OTRBuddyAttributes OTRBuddyAttributes = {
};

@implementation OTRBuddy

- (id)init
{
    if (self = [super init]) {
        
    }
    return self;
}


+ (NSString *)collection
{
    return [OTRChatter collection];
}



@end