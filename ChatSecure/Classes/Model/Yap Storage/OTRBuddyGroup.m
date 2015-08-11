//
//  OTRXMPPBuddy.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyGroup.h"
#import "YapDatabaseRelationshipTransaction.h"
#import "OTRDatabaseManager.h"
#import "OTRBuddy.h"
#import "OTRGroup.h"

const struct OTRBuddyGroupAttributes OTRBuddyGroupAttributes = {
    .online = @"online"
};

const struct OTRBuddyGroupRelationships OTRBuddyGroupRelationships = {
    .groupUniqueId = @"groupUniqueId",
    .buddyUniqueId = @"buddyUnqiueId",
};

const struct OTRBuddyGroupEdges OTRBuddyGroupEdges = {
    .buddy = @"buddy",
    .group = @"group"
};



@implementation OTRBuddyGroup

- (id)init
{
    if (self = [super init]) {
        self.online = NO;
    }
    return self;
}


- (OTRGroup *)fetchGroupWithtransaction:(YapDatabaseReadTransaction *)transaction;
{
    __block OTRGroup *localGroup;
    
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRBuddyGroupEdges.group destinationKey:self.groupUniqueId collection:[OTRBuddyGroup collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        
        localGroup = [OTRGroup fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];;
        
    }];
    
    return [localGroup copy];
}



#pragma - mark YapDatabaseRelationshipNode

- (NSArray *)yapDatabaseRelationshipEdges
{
    
   
    YapDatabaseRelationshipEdge *groupEdge = [YapDatabaseRelationshipEdge edgeWithName:OTRBuddyGroupEdges.group
                                                                          destinationKey:self.groupUniqueId
                                                                              collection:[OTRGroup collection]
                                                                         nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted | YDB_DeleteDestinationIfAllSourcesDeleted];
    




    YapDatabaseRelationshipEdge *buddyEdge = [YapDatabaseRelationshipEdge edgeWithName:OTRBuddyGroupEdges.buddy
                                                                        destinationKey:self.buddyUniqueId
                                                                            collection:[OTRBuddy collection]
                                                                       nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];



    
    
    return @[groupEdge, buddyEdge];
}


#pragma - mark Class Methods

+ (instancetype)fetchBuddyGroupWithBuddyUniqueId:(NSString *)buddyUniqueId withGroupUniqueId:(NSString *)groupUniqueId transaction:(YapDatabaseReadTransaction *)transaction
{
    __block OTRBuddyGroup *finalBuddyGroup = nil;
    
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRBuddyGroupEdges.group destinationKey:groupUniqueId collection:[OTRGroup collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRBuddyGroup * buddy = [transaction objectForKey:edge.sourceKey inCollection:[OTRBuddyGroup collection]];
        if([buddy.buddyUniqueId isEqualToString:buddyUniqueId]) {
            *stop = YES;
            finalBuddyGroup = buddy;
        }
        
    }];
    
    return [finalBuddyGroup copy];
}

+ (NSMutableArray *)fetchGroupBuddiesFromBuddy:(OTRBuddy *)buddy transaction:(YapDatabaseReadTransaction *)transaction
{
    __block NSMutableArray *finalBuddies = [[NSMutableArray alloc] init];
    
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRBuddyGroupEdges.buddy destinationKey:buddy.uniqueId collection:[OTRBuddy collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRBuddyGroup * buddy = [transaction objectForKey:edge.sourceKey inCollection:[OTRBuddyGroup collection]];
        
        if(buddy)
        {
            [finalBuddies addObject:buddy];
        }
    }];
    
    return [finalBuddies copy];
}

+ (NSMutableArray *)fetchGroupBuddiesFromGroup:(OTRGroup *)group transaction:(YapDatabaseReadTransaction *)transaction
{
    __block NSMutableArray *finalBuddies = [[NSMutableArray alloc] init];
    
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRBuddyGroupEdges.group destinationKey:group.uniqueId collection:[OTRGroup collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRBuddyGroup * buddy = [transaction objectForKey:edge.sourceKey inCollection:[OTRBuddyGroup collection]];
        
        if(buddy)
        {
            [finalBuddies addObject:buddy];
        }
    }];
    
    return [finalBuddies copy];
}

+ (instancetype)fetchGroupBuddyFromGroup:(OTRGroup *)group andBuddyName:(NSString *)buddyName transaction:(YapDatabaseReadTransaction *)transaction
{
    __block OTRBuddyGroup *finalBuddyGroup = nil;
    
    [[transaction ext:OTRYapDatabaseRelationshipName] enumerateEdgesWithName:OTRBuddyGroupEdges.group destinationKey:group.uniqueId collection:[OTRGroup collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        OTRBuddyGroup * buddyGroup = [transaction objectForKey:edge.sourceKey inCollection:[OTRBuddyGroup collection]];
        
        OTRBuddy *buddy = [OTRBuddy fetchObjectWithUniqueID:buddyGroup.buddyUniqueId transaction:transaction];
        
        if ([buddy.username isEqualToString:buddyName]) {
            *stop = YES;
            finalBuddyGroup = buddyGroup;
        }
    }];
    
    return [finalBuddyGroup copy];
}




@end
