//
//  OTRXMPPChatter.m
//  ChatSecure
//
//  Created by Diana Perez on 6/26/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRXMPPChatter.h"
#import "XMPPvCardTemp.h"
#import "NSData+XMPP.h"

#import "Strings.h"

const struct OTRXMPPChatterAttributes OTRXMPPChatterAttributes = {
    .vCardTemp = @"vCardTemp",
    .photoHash = @"photoHash",
    .waitingForvCardTempFetch = @"waitingForvCardTempFetch",
    .lastUpdatedvCardTemp = @"lastUpdatedvCardTemp",
    
    
};

@implementation OTRXMPPChatter

- (id)init
{
    if (self = [super init]) {
        self.waitingForvCardTempFetch = YES;
        self.statusMessage = OFFLINE_STRING;
    }
    return self;
}


#pragma - mark setters & getters

- (void)setVCardTemp:(XMPPvCardTemp *)vCardTemp
{
    _vCardTemp = vCardTemp;
    if ([self.vCardTemp.photo length]) {
        self.avatarData = self.vCardTemp.photo;
    }
}

- (void)setAvatarData:(NSData *)avatarData
{
    [super setAvatarData:avatarData];
    if ([self.avatarData length]) {
        self.photoHash = [[self.avatarData xmpp_sha1Digest] xmpp_hexStringValue];
    }
    else {
        self.photoHash = nil;
    }
}



#pragma - mark Class Methods

+ (NSString *)collection
{
    return [OTRChatter collection];
}

@end