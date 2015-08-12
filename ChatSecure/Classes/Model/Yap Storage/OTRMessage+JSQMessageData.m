//
//  OTRMessage+JSQMessageData.m
//  Off the Record
//
//  Created by David Chiles on 5/12/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRMessage+JSQMessageData.h"
#import "OTRDatabaseManager.h"
#import "OTRChatter.h"
#import "OTRAccount.h"
#import "OTRBroadcastGroup.h"
#import "OTRMediaItem.h"
#import "YapDatabaseRelationshipTransaction.h"

@implementation OTRMessage (JSQMessageData)

- (NSString *)senderId
{
    __block NSString *sender = @"";
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        OTRChatter *chatter = [self chatterWithTransaction:transaction];
        if (self.isIncoming) {
            sender = chatter.uniqueId;
        }
        else {
            OTRAccount *account = [chatter accountWithTransaction:transaction];
            sender = account.uniqueId;
        }
    }];
    return sender;
}

- (NSString *)senderDisplayName {
    __block NSString *sender = @"";
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        OTRChatter *chatter = [self chatterWithTransaction:transaction];
        if (self.isIncoming) {
            if ([chatter.displayName length]) {
                sender = chatter.displayName;
            }
            else {
                sender = chatter.username;
            }
        }
        else {
            OTRAccount *account = [chatter accountWithTransaction:transaction];
            if ([account.displayName length]) {
                sender = account.displayName;
            }
            else {
                sender = account.username;
            }
        }
    }];
    return sender;
}

- (NSUInteger)messageHash
{
    return [self hash];
}

- (BOOL)isMediaMessage
{
    if ([self.mediaItemUniqueId length]) {
        return YES;
    }
    return NO;
}

- (id<JSQMessageMediaData>)media
{
    __block id <JSQMessageMediaData>media = nil;
    
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        media = [OTRMediaItem fetchObjectWithUniqueID:self.mediaItemUniqueId transaction:transaction];
    }];

    return media;
}


@end
