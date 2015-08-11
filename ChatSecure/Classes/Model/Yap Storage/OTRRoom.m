//
//  OTRRoom.m
//  ChatSecure
//
//  Created by Diana Perez on 1/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRRoom.h"
#import "OTRAccount.h"
#import "OTRMessage.h"
#import "OTRChatter.h"

#import "OTRDatabaseManager.h"

#import "YapDatabaseRelationshipTransaction.h"

const struct OTRRoomAttributes OTRRoomAttributes = {
};

const struct OTRRoomRelationships OTRRoomRelationships = {
    .groupUniqueId = @"groupUniqueId"
};

const struct OTRRoomEdges OTRRoomEdges = {
    .group = @"group"
};

@implementation OTRRoom

- (id)init
{
    if (self = [super init]) {
        
    }
    return self;
}


#pragma - mark Class Methods

+ (instancetype)fetchRoomWithGroupName:(NSString *)groupName
                   withAccountUniqueId:(NSString *)accountUniqueId
                           transaction:(YapDatabaseReadTransaction *)transaction
{
    __block OTRRoom *finalRoom = nil;
    
    
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRChatterEdges.account destinationKey:accountUniqueId collection:[OTRAccount collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRChatter *chatter = [transaction objectForKey:edge.sourceKey inCollection:[OTRChatter collection]];
        if([chatter isKindOfClass:[OTRRoom class]])
        {
            OTRRoom *room = (OTRRoom *)chatter;
            if ([room.username isEqualToString:groupName]) {
                *stop = YES;
                finalRoom = room;
            }
        }
    }];
    
    
    return [finalRoom copy];

    
}


+ (NSString *)collection
{
    return [OTRChatter collection];
}

@end
