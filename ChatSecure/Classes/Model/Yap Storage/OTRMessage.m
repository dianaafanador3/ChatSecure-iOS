//
//  OTRMessage.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRMessage.h"
#import "OTRChatter.h"
#import "OTRRoom.h"
#import "OTRAccount.h"
#import "YapDatabaseTransaction.h"
#import "OTRDatabaseManager.h"
#import "YapDatabaseRelationshipTransaction.h"
#import "NSString+HTML.h"
#import "Strings.h"
#import "OTRConstants.h"
#import "YapDatabaseQuery.h"
#import "YapDatabaseSecondaryIndexTransaction.h"
#import "OTRBroadcastGroup.h"
#import "OTRMediaItem.h"

const struct OTRMessageAttributes OTRMessageAttributes = {
    .date = @"date",
    .text = @"text",
    .media = @"media",
    .mediaType = @"mediaType",
    .delivered = @"delivered",
    .read = @"read",
    .incoming = @"incoming",
    .messageId = @"messageId",
    .transportedSecurely = @"transportedSecurely",
    .broadcastMessage = @"broadcastMessage",
    .mediaMessage = @"mediaMessage",
    .roomMessage = @"roomMessage",
    .mediaItem = @"mediaItem"
};

const struct OTRMessageRelationships OTRMessageRelationships = {
    .chatterUniqueId = @"chatterUniqueId",
};

const struct OTRMessageEdges OTRMessageEdges = {
    .chatter = @"chatter",
    .media = @"media"
};


@implementation OTRMessage

- (id)init
{
    if (self = [super init]) {
        self.date = [NSDate date];
        self.messageId = [[NSUUID UUID] UUIDString];
        self.delivered = NO;
        self.read = NO;
        self.broadcastMessage = NO;
        self.roomMessage = NO;
        self.mediaMessage = NO;
    }
    return self;
}

- (OTRChatter *)chatterWithTransaction:(YapDatabaseReadTransaction *)readTransaction
{
    return [OTRChatter fetchObjectWithUniqueID:self.chatterUniqueId transaction:readTransaction];
}


#pragma - mark YapDatabaseRelationshipNode

- (NSArray *)yapDatabaseRelationshipEdges
{
    NSArray *edges = nil;
    
    if (self.chatterUniqueId) {
        YapDatabaseRelationshipEdge *buddyEdge = [YapDatabaseRelationshipEdge edgeWithName:OTRMessageEdges.chatter
                                                                            destinationKey:self.chatterUniqueId
                                                                                collection:[OTRChatter collection]
                                                                           nodeDeleteRules:YDB_NotifyIfDestinationDeleted];
        
        edges = @[buddyEdge];
    }
    
    
    if (self.mediaItemUniqueId) {
        YapDatabaseRelationshipEdge *mediaEdge = [YapDatabaseRelationshipEdge edgeWithName:OTRMessageEdges.media
                                                                            destinationKey:self.mediaItemUniqueId
                                                                                collection:[OTRMediaItem collection]
                                                                           nodeDeleteRules:YDB_DeleteDestinationIfSourceDeleted | YDB_NotifyIfSourceDeleted];
        
        if ([edges count]) {
            edges = [edges arrayByAddingObject:mediaEdge];
        }
        else {
            edges = @[mediaEdge];
        }
    }
    
    
    return edges;
    
}

#pragma - mark Class Methods

+ (NSInteger)numberOfUnreadMessagesWithTransaction:(YapDatabaseReadTransaction*)transaction
{
    __block int count = 0;
    [transaction enumerateKeysAndObjectsInCollection:[OTRMessage collection] usingBlock:^(NSString *key, OTRMessage *message, BOOL *stop) {
        if ([message isKindOfClass:[OTRMessage class]]) {
            if (!message.isRead) {
                count +=1;
            }
        }
    }];
    return count;
}

+ (void)deleteAllMessagesWithTransaction:(YapDatabaseReadWriteTransaction*)transaction
{
    [transaction removeAllObjectsInCollection:[OTRMessage collection]];
}

+ (void)deleteAllMessagesForChatterId:(NSString *)uniqueBuddyId transaction:(YapDatabaseReadWriteTransaction*)transaction
{
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRMessageEdges.chatter destinationKey:uniqueBuddyId collection:[OTRChatter collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        [transaction removeObjectForKey:edge.sourceKey inCollection:edge.sourceCollection];
        
    }];
    
    //Update Last message date for sorting and grouping
    OTRChatter *chatter = [OTRChatter fetchObjectWithUniqueID:uniqueBuddyId transaction:transaction];
    chatter.lastMessageDate = nil;
    [chatter saveWithTransaction:transaction];
    
}

+ (void)deleteAllMessagesForAccountId:(NSString *)uniqueAccountId transaction:(YapDatabaseReadWriteTransaction*)transaction
{
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRChatterEdges.account destinationKey:uniqueAccountId collection:[OTRAccount collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        [self deleteAllMessagesForChatterId:edge.sourceKey transaction:transaction];
    }];
}

+ (void)receivedDeliveryReceiptForMessageId:(NSString *)messageId transaction:(YapDatabaseReadWriteTransaction*)transaction
{
    __block OTRMessage *deliveredMessage = nil;
    [self enumerateMessagesWithMessageId:messageId transaction:transaction usingBlock:^(OTRMessage *message, BOOL *stop) {
        if (!message.isIncoming) {
            //Media messages are not delivered until the transfer is complete. This is handled in the OTREncryptionManager.
            
            if (![message.mediaItemUniqueId length]) {
                deliveredMessage = message;
                *stop = YES;
            }
        }
    }];
    if (deliveredMessage) {
        deliveredMessage.delivered = YES;
        [deliveredMessage saveWithTransaction:transaction];
    }
    
}

+ (void)showLocalNotificationForMessage:(OTRMessage *)message
{
    if (![[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
    {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString * rawMessage = [message.text stringByConvertingHTMLToPlainText];
            // We are not active, so use a local notification instead
            __block OTRChatter *localChatter = nil;
            __block OTRAccount *localAccount;
            __block NSInteger unreadCount = 0;
            [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                localChatter = [message chatterWithTransaction:transaction];
                localAccount = [localChatter accountWithTransaction:transaction];
                unreadCount = [self numberOfUnreadMessagesWithTransaction:transaction];
            }];
            
            NSString *name = localChatter.username;
            if ([localChatter.displayName length]) {
                name = localChatter.displayName;
            }
            
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            localNotification.alertAction = REPLY_STRING;
            localNotification.soundName = UILocalNotificationDefaultSoundName;
            localNotification.applicationIconBadgeNumber = unreadCount;
            localNotification.alertBody = [NSString stringWithFormat:@"%@: %@",name,rawMessage];
            
            localNotification.userInfo = @{kOTRNotificationBuddyUniqueIdKey:localChatter.uniqueId};
            
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        });
    }
}

+ (void)enumerateMessagesWithMessageId:(NSString *)messageId transaction:(YapDatabaseReadTransaction *)transaction usingBlock:(void (^)(OTRMessage *message,BOOL *stop))block;
{
    if ([messageId length] && block) {
        NSString *queryString = [NSString stringWithFormat:@"Where %@ = ?",OTRYapDatabseMessageIdSecondaryIndex];
        YapDatabaseQuery *query = [YapDatabaseQuery queryWithFormat:queryString,messageId];
        
        [[transaction ext:OTRYapDatabseMessageIdSecondaryIndexExtension] enumerateKeysMatchingQuery:query usingBlock:^(NSString *collection, NSString *key, BOOL *stop) {
            OTRMessage *message = [OTRMessage fetchObjectWithUniqueID:key transaction:transaction];
            if (message) {
                block(message,stop);
            }
        }];
        
    }
}

@end
