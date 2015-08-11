//
//  OTRXMPPRoom.h
//  ChatSecure
//
//  Created by Diana Perez on 1/13/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRRoom.h"


extern const struct OTRXMPPRoomAttributes {
    __unsafe_unretained NSString *roomCreated;
    
} OTRXMPPRoomAttributes;

@interface OTRXMPPRoom : OTRRoom

@property (nonatomic, getter = isRoomCreated) BOOL roomCreated;


@end