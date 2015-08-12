//
//  OTRAppDelegate.h
//  Off the Record
//
//  Created by Chris Ballinger on 8/11/11.
//  Copyright (c) 2011 Chris Ballinger. All rights reserved.
//
//  This file is part of ChatSecure.
//
//  ChatSecure is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ChatSecure is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ChatSecure.  If not, see <http://www.gnu.org/licenses/>.

#import <UIKit/UIKit.h>
#import "HockeySDK.h"


@class OTRMessagesHoldTalkViewController;
@class OTRLoginViewController;
@class OTRContactsViewController;
@class OTRConversationViewController;
@class OTRBroadcastListViewController;
@class OTRMessagesGroupViewController;
@class OTRMessagesRoomViewController;
@class OTRMessagesBuddyViewController;
@class OTRTabBarController;
@class OTRCalendarViewController;
@class OTRSettingsViewController;


@interface OTRAppDelegate : UIResponder <UIApplicationDelegate, BITHockeyManagerDelegate>

@property (nonatomic, strong) UIWindow *window;


@property (nonatomic, strong) OTRMessagesHoldTalkViewController *messagesViewController;
@property (nonatomic, strong) OTRSettingsViewController *settingsViewController;
@property (nonatomic, strong) OTRMessagesGroupViewController *groupMessagesViewController;
@property (nonatomic, strong) OTRMessagesBuddyViewController *messagesBuddyViewController;
@property (nonatomic, strong) OTRMessagesRoomViewController *roomMessagesViewController;

@property (nonatomic, strong) OTRBroadcastListViewController *broadcastListViewController;
@property (nonatomic, strong) OTRConversationViewController *conversationViewController;
@property (nonatomic, strong) OTRCalendarViewController *eventViewController;
@property (nonatomic, strong) OTRLoginViewController *loginViewController;
@property (nonatomic, strong) OTRContactsViewController *contactsViewController;
@property (nonatomic, strong) OTRTabBarController *tabBarController;

@property (nonatomic, strong) NSTimer *backgroundTimer;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (nonatomic) BOOL didShowDisconnectionWarning;

- (void) showConversationViewController;

+ (OTRAppDelegate *)appDelegate;


@end
