//
//  OTRSubEvent.h
//  ChatSecure
//
//  Created by Diana Perez on 6/16/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTREvent.h"

extern const struct OTRSubEventRelationships {
    __unsafe_unretained NSString *eventUniqueId;
} OTRSubEventRelationships;

extern const struct OTRSubEventEdges {
    __unsafe_unretained NSString *event;
} OTRSubEventEdges;

@interface OTRSubEvent : OTREvent <YapDatabaseRelationshipNode>

@property (nonatomic, strong) NSString *eventUniqueId;

+ (NSString *)collection;

@end
