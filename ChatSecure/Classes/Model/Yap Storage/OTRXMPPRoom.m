//
//  OTRXMPPRoom.m
//  ChatSecure
//
//  Created by Diana Perez on 1/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPRoom.h"
#import "XMPPvCardTemp.h"
#import "NSData+XMPP.h"


const struct OTRXMPPRoomAttributes OTRXMPPRoomAttributes = {
    .roomCreated = @"roomCreated",
};


@implementation OTRXMPPRoom

- (id)init
{
    if (self = [super init]) {
        self.roomCreated = NO;
    }
    return self;
}

#pragma - mark Class Methods

+ (NSString *)collection
{
    return [OTRRoom collection];
}



@end
