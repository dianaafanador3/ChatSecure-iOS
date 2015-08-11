//
//  OTRComposeViewController.h
//  Off the Record
//
//  Created by David Chiles on 3/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRBroadcastGroup;

@interface OTRBroadcastListViewController : UIViewController

- (void)enterConversationWithBuddies:(OTRBroadcastGroup *)buddies;

@end
