//
//  OTRGroups.m
//  ChatSecure
//
//  Created by IN2 on 22/10/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBroadcastGroup.h"
#import "OTRChatter.h"

#import "Strings.h"

const struct OTRBroadcastGroupAttributes OTRBroadcastGroupAttributes = {
    .buddies = @"buddies"
};


@implementation OTRBroadcastGroup


- (id)initWithBuddyArray:(NSMutableArray *)buddies;
{
    if (self = [super init])
    {
        self.buddies = [[NSMutableArray alloc]initWithArray:buddies];
        self.displayName = LIST_OF_DIFUSSION_STRING;
    }
    
    return self;
}



#pragma - mark Class Methods

+ (NSString *)collection
{
    return [OTRChatter collection];
}

@end
