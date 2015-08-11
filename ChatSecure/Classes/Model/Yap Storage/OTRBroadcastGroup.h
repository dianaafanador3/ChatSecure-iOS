//
//  OTRGroups.h
//  ChatSecure
//
//  Created by IN2 on 22/10/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRChatter.h"

@class OTRAccount, OTRMessage;

extern const struct OTRBroadcastGroupAttributes {
    __unsafe_unretained NSString *buddies;
} OTRBroadcastGroupAttributes;


@interface OTRBroadcastGroup : OTRChatter 

@property (nonatomic, strong) NSMutableArray *buddies;

- (id)initWithBuddyArray:(NSMutableArray *)buddies;



@end