//
//  OTRRoom.h
//  ChatSecure
//
//  Created by Diana Perez on 1/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTRChatter.h"
#import "OTRBuddy.h"
#import "XMPPFramework.h"

@class OTRAccount;


extern const struct OTRRoomAttributes {
    
} OTRRoomAttributes;

extern const struct OTRRoomRelationships {
    __unsafe_unretained NSString *groupUniqueId;
} OTRRoomRelationships;

extern const struct OTRRoomEdges {
    __unsafe_unretained NSString *group;
} OTRRoomEdges;


@interface OTRRoom : OTRXMPPChatter

@property (nonatomic, strong) NSString *groupUniqueId;

+ (instancetype)fetchRoomWithGroupName:(NSString *)groupName
                   withAccountUniqueId:(NSString *)accountUniqueId
                           transaction:(YapDatabaseReadTransaction *)transaction;

@end
