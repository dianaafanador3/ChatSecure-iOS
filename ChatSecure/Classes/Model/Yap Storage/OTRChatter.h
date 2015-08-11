//
//  OTRChatter.h
//  ChatSecure
//
//  Created by Diana Perez on 5/27/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

//
//  OTRBuddy.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseObject.h"
#import "OTRConstants.h"
@import UIKit;

@class OTRAccount, OTRMessage;

typedef NS_ENUM(NSInteger, OTRChatterStatus) {
    OTRChatterStatusOffline   = 4,
    OTRChatterStatusXa        = 3,
    OTRChatterStatusDnd       = 2,
    OTRChatterStatusAway      = 1,
    OTRChatterStatusAvailable = 0
};

typedef NS_ENUM(int, OTRChatState) {
    kOTRChatStateUnknown   = 0,
    kOTRChatStateActive    = 1,
    kOTRChatStateComposing = 2,
    kOTRChatStatePaused    = 3,
    kOTRChatStateInactive  = 4,
    kOTRChatStateGone      = 5
};

extern const struct OTRChatterAttributes {
    __unsafe_unretained NSString *username;
    __unsafe_unretained NSString *displayName;
    __unsafe_unretained NSString *lastMessageDate;
    __unsafe_unretained NSString *encryptionStatus;
    __unsafe_unretained NSString *composingMessageString;
    __unsafe_unretained NSString *avatarData;
    
    __unsafe_unretained NSString *status;
    __unsafe_unretained NSString *statusMessage;
    __unsafe_unretained NSString *chatState;
    __unsafe_unretained NSString *lastSentChatState;
    __unsafe_unretained NSString *dateLastChatState;
    
} OTRChatterAttributes;

extern const struct OTRChatterRelationships {
    __unsafe_unretained NSString *accountUniqueId;
} OTRChatterRelationships;

extern const struct OTRChatterEdges {
    __unsafe_unretained NSString *account;
} OTRChatterEdges;

@interface OTRChatter : OTRYapDatabaseObject <YapDatabaseRelationshipNode>

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *composingMessageString;
@property (nonatomic, strong) NSDate *lastMessageDate;
@property (nonatomic, strong) NSData *avatarData;

@property (nonatomic) OTRChatterStatus status;
@property (nonatomic, strong) NSString *statusMessage;
@property (nonatomic) OTRChatState chatState;
@property (nonatomic) OTRChatState lastSentChatState;
@property (nonatomic, strong) NSDate *dateLastChatState;

@property (nonatomic, strong) NSString *accountUniqueId;

- (UIImage *)avatarImage;
- (BOOL)hasMessagesWithTransaction:(YapDatabaseReadTransaction *)transaction;
- (NSInteger)numberOfUnreadMessagesWithTransaction:(YapDatabaseReadTransaction *)transaction;
- (OTRMessage *)lastMessageWithTransaction:(YapDatabaseReadTransaction *)transaction;
- (OTRAccount*)accountWithTransaction:(YapDatabaseReadTransaction *)transaction;
- (void)setAllMessagesRead:(YapDatabaseReadWriteTransaction *)transaction;
- (void)updateLastMessageDateWithTransaction:(YapDatabaseReadTransaction *)transaction;


+ (void)resetAllChatStatesWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;
+ (void)resetAllBuddyStatusesWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;

+ (instancetype)fetchChatterForUsername:(NSString *)username
                          accountName:(NSString *)accountName
                          transaction:(YapDatabaseReadTransaction *)transaction;

+ (instancetype)fetchChatterWithUsername:(NSString *)username
                   withAccountUniqueId:(NSString *)accountUniqueId
                           transaction:(YapDatabaseReadTransaction *)transaction;

@end