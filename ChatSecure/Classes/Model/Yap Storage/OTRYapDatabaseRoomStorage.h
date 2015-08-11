//
//  OTRYapDatabaseRoomStorage.h
//  ChatSecure
//
//  Created by Diana Perez on 1/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "XMPPRoom.h"

@interface OTRYapDatabaseRoomStorage : NSObject <XMPPRoomStorage>

@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) NSMutableArray *occupants;
@property (nonatomic, strong) NSMutableArray * occupantsArray;


@end
