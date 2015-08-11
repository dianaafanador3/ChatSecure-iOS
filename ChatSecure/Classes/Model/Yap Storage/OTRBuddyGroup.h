//
//  OTRXMPPBuddy.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseObject.h"
@import UIKit;

@class OTRBuddy, OTRGroup;

extern const struct OTRBuddyGroupAttributes {
    __unsafe_unretained NSString *online;
} OTRBuddyGroupAttributes;
    
extern const struct OTRBuddyGroupRelationships {
    __unsafe_unretained NSString *buddyUniqueId;
    __unsafe_unretained NSString *groupUniqueId;
} OTRBuddyGroupRelationships;

extern const struct OTRBuddyGroupEdges {
    __unsafe_unretained NSString *buddy;
    __unsafe_unretained NSString *group;
} OTRBuddyGroupEdges;


@interface OTRBuddyGroup : OTRYapDatabaseObject <YapDatabaseRelationshipNode>

@property (nonatomic, strong) NSString *groupUniqueId;
@property (nonatomic, strong) NSString *buddyUniqueId;

@property (nonatomic, getter = isOnline) BOOL online;


- (NSMutableArray *)fetchGroupsFromBuddyGroup:(YapDatabaseReadTransaction *)transaction
;

+ (instancetype)fetchBuddyGroupWithBuddyUniqueId:(NSString *)buddyUniqueId
                          withGroupUniqueId:(NSString *)groupUniqueId
                          transaction:(YapDatabaseReadTransaction *)transaction;

+ (NSMutableArray *)fetchGroupBuddiesFromBuddy:(OTRBuddy *)buddy transaction:(YapDatabaseReadTransaction *)transaction;

+ (NSMutableArray *)fetchGroupBuddiesFromGroup:(OTRGroup *)group transaction:(YapDatabaseReadTransaction *)transaction;

+ (instancetype)fetchGroupBuddyFromGroup:(OTRGroup *)group andBuddyName:(NSString *)buddyName transaction:(YapDatabaseReadTransaction *)transaction;


@end
