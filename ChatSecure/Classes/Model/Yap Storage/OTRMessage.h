//
//  OTRMessage.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseObject.h"

@class OTRChatter, YapDatabaseReadTransaction, OTRBroadcastGroup, OTRRoom, OTRMediaItem;

extern const struct OTRMessageAttributes {
    __unsafe_unretained NSString *date;
    __unsafe_unretained NSString *text;
    __unsafe_unretained NSString *media;
    __unsafe_unretained NSString *mediaType;
    __unsafe_unretained NSString *delivered;
    __unsafe_unretained NSString *read;
    __unsafe_unretained NSString *incoming;
    __unsafe_unretained NSString *messageId;
    __unsafe_unretained NSString *transportedSecurely;
    __unsafe_unretained NSString *broadcastMessage;
    __unsafe_unretained NSString *roomMessage;
    __unsafe_unretained NSString *mediaMessage;
    __unsafe_unretained NSString *mediaItem;
    
} OTRMessageAttributes;

extern const struct OTRMessageRelationships {
    __unsafe_unretained NSString *chatterUniqueId;
} OTRMessageRelationships;

extern const struct OTRMessageEdges {
    __unsafe_unretained NSString *chatter;
    __unsafe_unretained NSString *media;
} OTRMessageEdges;

@interface OTRMessage : OTRYapDatabaseObject <YapDatabaseRelationshipNode>

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *messageId;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, getter = isDelivered) BOOL delivered;
@property (nonatomic, getter = isRead) BOOL read;
@property (nonatomic, getter = isIncoming) BOOL incoming;
@property (nonatomic, getter = isTransportedSecurely) BOOL transportedSecurely;
@property (nonatomic, getter = isBroadcastMessage) BOOL broadcastMessage;
@property (nonatomic, getter = isRoomMessage) BOOL roomMessage;
@property (nonatomic, getter = isMediaMessage) BOOL mediaMessage;


@property (nonatomic, strong) NSString *mediaItemUniqueId;
@property (nonatomic, strong) NSString *chatterUniqueId;

- (OTRChatter *)chatterWithTransaction:(YapDatabaseReadTransaction *)readTransaction;


+ (NSInteger)numberOfUnreadMessagesWithTransaction:(YapDatabaseReadTransaction*)transaction;
+ (void)deleteAllMessagesWithTransaction:(YapDatabaseReadWriteTransaction*)transaction;
+ (void)deleteAllMessagesForChatterId:(NSString *)uniqueBuddyId transaction:(YapDatabaseReadWriteTransaction*)transaction;
+ (void)deleteAllMessagesForAccountId:(NSString *)uniqueAccountId transaction:(YapDatabaseReadWriteTransaction*)transaction;
+ (void)receivedDeliveryReceiptForMessageId:(NSString *)messageId transaction:(YapDatabaseReadWriteTransaction*)transaction;

+ (void)showLocalNotificationForMessage:(OTRMessage *)message;

+ (void)enumerateMessagesWithMessageId:(NSString *)messageId transaction:(YapDatabaseReadTransaction *)transaction usingBlock:(void (^)(OTRMessage *message,BOOL *stop))block;

@end
