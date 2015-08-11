//
//  OTRMessagesRoomViewController.h
//  Off the Record
//
//  Created by David Chiles on 5/12/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//



#import <UIKit/UIKit.h>
#import "OTRMessagesHoldTalkViewController.h"

@class OTRRoom;

@interface OTRMessagesRoomViewController : OTRMessagesHoldTalkViewController

@property (nonatomic, strong) OTRRoom *roomGroup;

@end
