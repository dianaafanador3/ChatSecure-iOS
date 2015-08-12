//
//  OTRConversationViewController.h
//  Off the Record
//
//  Created by David Chiles on 3/2/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRChatter, OTRMessage;

@interface OTRConversationViewController : UIViewController 

- (void)enterConversationWithBuddy:(OTRChatter *)buddy;
- (void)enterConversationWithBuddy:(OTRChatter *)buddy andMessage:(OTRMessage *)message;

@end
