//
//  OTRXMPPBuddy.h
//  ChatSecure
//
//  Created by Diana Perez on 6/25/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRBuddy.h"


extern const struct OTRXMPPBuddyAttributes {
    __unsafe_unretained NSString *pendingApproval;
    
} OTRXMPPBuddyAttributes;

@interface OTRXMPPBuddy : OTRBuddy

@property (nonatomic, getter = isPendingApproval) BOOL pendingApproval;


@end
