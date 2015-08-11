//
//  OTRBuddy.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRChatter.h"
#import "OTRAccount.h"
#import "OTRMessage.h"
#import "OTRDatabaseManager.h"
#import "YapDatabaseRelationshipTransaction.h"
#import "OTRKit.h"

#import "OTRImages.h"
#import "OTRColors.h"

const struct OTRChatterAttributes OTRChatterAttributes = {
    
    .username = @"username",
    .displayName = @"displayName",
    .lastMessageDate = @"lastMessageDate",
    .encryptionStatus = @"encryptionStatus",
    .avatarData = @"avatarData",
    .composingMessageString = @"composingMessageString",
    .status = @"status",
    .statusMessage = @"statusMessage",
    .chatState = @"chatState",
    .lastSentChatState = @"lastSentChatState",
    .dateLastChatState = @"dateLastChatState",
};

const struct OTRChatterRelationships OTRChatterRelationships = {
    .accountUniqueId = @"accountUniqueId"
};

const struct OTRChatterEdges OTRChatterEdges = {
    .account = @"account"
};

@implementation OTRChatter

- (id)init
{
    if (self = [super init]) {
        self.status = OTRChatterStatusOffline;
        self.chatState = kOTRChatStateUnknown;
        self.lastSentChatState = kOTRChatStateUnknown;
    }
    return self;
}

- (UIImage *)avatarImage
{
    //on setAvatar clear this buddies image cache
    //invalidate if jid or display name changes
    return [OTRImages avatarImageWithUniqueIdentifier:self.uniqueId avatarData:self.avatarData displayName:self.displayName username:self.username andStatusColor:[OTRColors colorWithStatus:self.status]];
}

- (void)setAvatarData:(NSData *)avatarData
{
    if (![_avatarData isEqualToData: avatarData]) {
        _avatarData = avatarData;
        [OTRImages removeImageWithIdentifier:self.uniqueId];
    }
}

- (void)setDisplayName:(NSString *)displayName
{
    if (![_displayName isEqualToString:displayName]) {
        _displayName = displayName;
        if (!self.avatarData) {
            [OTRImages removeImageWithIdentifier:self.uniqueId];
        }
    }
}


- (BOOL)hasMessagesWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    NSUInteger numberOfMessages = [[transaction ext:OTRYapDatabaseRelationshipName] edgeCountWithName:OTRMessageEdges.chatter destinationKey:self.uniqueId collection:[OTRChatter collection]];
    return (numberOfMessages > 0);
}


- (void)updateLastMessageDateWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    __block NSDate *date = nil;
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRMessageEdges.chatter destinationKey:self.uniqueId collection:[OTRChatter collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRMessage *message = [OTRMessage fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
        if (message) {
            if (!date) {
                date = message.date;
            }
            else {
                date = [date laterDate:message.date];
            }
        }
    }];
    self.lastMessageDate = date;
}

- (NSInteger)numberOfUnreadMessagesWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    __block NSUInteger count = 0;
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRMessageEdges.chatter destinationKey:self.uniqueId collection:[OTRChatter collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRMessage *message = [OTRMessage fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
        if (!message.isRead) {
            count += 1;
        }
    }];
    return count;
}

- (OTRAccount*)accountWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    return [OTRAccount fetchObjectWithUniqueID:self.accountUniqueId transaction:transaction];
}


- (void)setAllMessagesRead:(YapDatabaseReadWriteTransaction *)transaction
{
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRMessageEdges.chatter destinationKey:self.uniqueId collection:[OTRChatter collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRMessage *message = [[OTRMessage fetchObjectWithUniqueID:edge.sourceKey transaction:transaction] copy];
        
        if (!message.isRead) {
            message.read = YES;
            [message saveWithTransaction:transaction];
        }
    }];
}

- (OTRMessage *)lastMessageWithTransaction:(YapDatabaseReadTransaction *)transaction
{
    __block OTRMessage *finalMessage = nil;
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRMessageEdges.chatter destinationKey:self.uniqueId collection:[OTRChatter collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRMessage *message = [OTRMessage fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
        if (!finalMessage ||    [message.date compare:finalMessage.date] == NSOrderedDescending) {
            finalMessage = message;
        }
        
    }];
    return [finalMessage copy];
}



#pragma - mark YapDatabaseRelationshipNode

- (NSArray *)yapDatabaseRelationshipEdges
{
    NSArray *edges = nil;
    if (self.accountUniqueId) {
        YapDatabaseRelationshipEdge *accountEdge = [YapDatabaseRelationshipEdge edgeWithName:OTRChatterEdges.account
                                                                              destinationKey:self.accountUniqueId
                                                                                  collection:[OTRAccount collection]
                                                                             nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
        edges = @[accountEdge];
    }
    
    
    return edges;
}


#pragma - mark Class Methods

+ (instancetype)fetchChatterForUsername:(NSString *)username accountName:(NSString *)accountName transaction:(YapDatabaseReadTransaction *)transaction
{
    OTRAccount *account = [[OTRAccount allAccountsWithUsername:accountName transaction:transaction] firstObject];
    return [self fetchChatterWithUsername:username withAccountUniqueId:account.uniqueId transaction:transaction];
}

+ (instancetype)fetchChatterWithUsername:(NSString *)username withAccountUniqueId:(NSString *)accountUniqueId transaction:(YapDatabaseReadTransaction *)transaction
{
    __block OTRChatter *finalChatter = nil;
    
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRChatterEdges.account destinationKey:accountUniqueId collection:[OTRAccount collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRChatter * chatter = [transaction objectForKey:edge.sourceKey inCollection:[OTRChatter collection]];
        //From android user with only a nickname temporal
        if ([chatter.username isEqualToString:username] || [chatter.displayName isEqualToString:username]) {
            *stop = YES;
            finalChatter = chatter;
        }
    }];
    
    return [finalChatter copy];
}


#pragma - mark Class Methods

+ (void)resetAllChatStatesWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    NSMutableArray *buddiesToChange = [NSMutableArray array];
    [transaction enumerateKeysAndObjectsInCollection:[self collection] usingBlock:^(NSString *key, OTRChatter *chatter, BOOL *stop) {
        if([chatter isKindOfClass:[OTRChatter class]])
        {
            if(chatter.chatState != kOTRChatStateUnknown)
            {
                [buddiesToChange addObject:chatter];
            }
        }
    }];
    
    [buddiesToChange enumerateObjectsUsingBlock:^(OTRChatter *chatter, NSUInteger idx, BOOL *stop) {
        chatter.chatState = kOTRChatStateUnknown;
        [chatter saveWithTransaction:transaction];
    }];
}

+ (void)resetAllBuddyStatusesWithTransaction:(YapDatabaseReadWriteTransaction *)transaction
{
    NSMutableArray *buddiesToChange = [NSMutableArray array];
    [transaction enumerateKeysAndObjectsInCollection:[self collection] usingBlock:^(NSString *key, OTRChatter *chatter, BOOL *stop) {
        if([chatter isKindOfClass:[OTRChatter class]])
        {
            if(chatter.status != OTRChatterStatusOffline)
            {
                [buddiesToChange addObject:chatter];
            }
        }
    }];
    
    [buddiesToChange enumerateObjectsUsingBlock:^(OTRChatter *chatter, NSUInteger idx, BOOL *stop) {
        chatter.status = OTRChatterStatusOffline;
        [chatter saveWithTransaction:transaction];
    }];
}




@end