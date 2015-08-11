//
//  OTRSubEvent.m
//  ChatSecure
//
//  Created by Diana Perez on 6/16/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRSubEvent.h"
#import "OTREvent.h"

const struct OTRSubEventRelationships OTRSubEventRelationships = {
    .eventUniqueId = @"eventUniqueId"
};

const struct OTRSubEventEdges OTRSubEventEdges = {
    .event = @"account"
};

@implementation OTRSubEvent

#pragma - mark YapDatabaseRelationshipNode

- (NSArray *)yapDatabaseRelationshipEdges
{
    NSArray *edges = nil;
    if (self.eventUniqueId) {
        YapDatabaseRelationshipEdge *eventEdge = [YapDatabaseRelationshipEdge edgeWithName:OTRSubEventEdges.event
                                                                              destinationKey:self.eventUniqueId
                                                                                  collection:[OTREvent collection]
                                                                             nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
        edges = @[eventEdge];
    }
    
    
    return edges;
}

+ (NSString *)collection
{
    return [OTREvent collection];
}

@end
