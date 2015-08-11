//
//  OTREvents.m
//  ChatSecure
//
//  Created by IN2 on 22/10/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTREvent.h"
#import "OTRAccount.h"
#import "YapDatabaseRelationshipTransaction.h"
#import "OTRDatabaseManager.h"
#import "OTRBuddy.h"

#import "Strings.h"

const struct OTREventAttributes OTREventAttributes = {
    .title = @"title",
    .location = @"location",
    .startsDate = @"startsDate",
    .endsDate = @"endsDate",
    .invitees = @"invitees",
    .notes = @"notes",
    .day = @"day",
    .allDay = @"allDay",
    .repeat = @"repeat",
    .calendar = @"calendar",
    .alert = @"alert",
    .secondAlert = @"secondAlert",
    .showAs = @"showAs",
    .url = @"url",
    .eventId = @"eventId",
    .filePath = @"filePath"
};

const struct OTREventRelationships OTREventRelationships = {
    .accountUniqueId = @"accountUniqueId"
};

const struct OTREventEdges OTREventEdges = {
    .account = @"account"
};

@implementation OTREvent


- (id)initWithTitle:(NSString *)title
{
    if (self = [super init])
    {
        self.title = title;
        self.allDay = FALSE;
        self.repeat = OTRRepeatNone;
        self.alert = OTRAlertNone;
        self.secondAlert = OTRAlertNone;
        self.showAs = OTRShowAsNone;
    }
    
    return self;
}



#pragma - mark YapDatabaseRelationshipNode

- (NSArray *)yapDatabaseRelationshipEdges
{
    NSArray *edges = nil;
    if (self.accountUniqueId) {
        YapDatabaseRelationshipEdge *accountEdge = [YapDatabaseRelationshipEdge edgeWithName:OTREventEdges.account
                                                                              destinationKey:self.accountUniqueId
                                                                                  collection:[OTRAccount collection]
                                                                             nodeDeleteRules:YDB_DeleteDestinationIfSourceDeleted];
        edges = @[accountEdge];
    }
    
    
    return edges;
}

#pragma - mark Class Methods



@end
