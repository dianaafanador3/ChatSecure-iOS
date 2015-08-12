//
//  OTRXMPPBuddy.m
//  ChatSecure
//
//  Created by Diana Perez on 6/25/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPBuddy.h"
#import "XMPPvCardTemp.h"
#import "NSData+XMPP.h"

const struct OTRXMPPBuddyAttributes OTRXMPPBuddyAttributes = {
    .pendingApproval = @"pendingApproval",
   
};

@implementation OTRXMPPBuddy

- (id)init
{
    if (self = [super init]) {
        self.pendingApproval = YES;

    }
    return self;
}


#pragma - mark Class Methods

+ (NSString *)collection
{
    return [OTRBuddy collection];
}

@end
