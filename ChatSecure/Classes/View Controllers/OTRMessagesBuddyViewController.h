//
//  OTRMessagesBuddyViewController.h
//  ChatSecure
//
//  Created by Diana Perez on 3/30/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTRMessagesHoldTalkViewController.h"

@class OTRBuddy;

@interface OTRMessagesBuddyViewController : OTRMessagesHoldTalkViewController

@property (nonatomic, strong) OTRBuddy *buddy;

@end
