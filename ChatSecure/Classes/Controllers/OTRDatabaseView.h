//
//  OTRDatabaseView.h
//  Off the Record
//
//  Created by David Chiles on 3/31/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YapDatabaseViewMappings.h"
#import "YapDatabaseView.h"

//Extension Strings
extern NSString *OTRConversationDatabaseViewExtensionName;
extern NSString *OTRChatDatabaseViewExtensionName;
extern NSString *OTREventDatabaseViewExtensionName;
extern NSString *OTRAllAccountDatabaseViewExtensionName;
extern NSString *OTRBuddyNameSearchDatabaseViewExtensionName;
extern NSString *OTRAllBuddiesDatabaseViewExtensionName;
extern NSString *OTRAllBuddiesNoStatusDatabaseViewExtensionName;
extern NSString *OTRAllSubscriptionRequestsViewExtensionName;
extern NSString *OTRAllPushAccountInfoViewExtensionName;
extern NSString *OTRUnreadMessagesViewExtensionName;
extern NSString *OTRContactByGroupDatabaseViewExtensionName;
extern NSString *OTRContactDatabaseViewExtensionName;
extern NSString *OTRAllBroadcastListDatabaseViewExtensionName;
extern NSString *OTRRoomDatabaseViewExtensionName;

extern NSString *OTRChatNameSearchDatabaseViewExtensionName;

// Group Strins
extern NSString *OTRAllAccountGroup;
extern NSString *OTRConversationGroup;
extern NSString *OTRChatMessageGroup;
extern NSString *OTRBuddyListGroup;
extern NSString *OTRUnreadMessageGroup;
extern NSString *OTRAllPresenceSubscriptionRequestGroup;
extern NSString *OTRAllBuddiesGroupList;
extern NSString *OTRAllBuddiesNoStatusGroupList;
extern NSMutableArray *OTRContactByGroupList;
extern NSString *OTRBuddyNoGroupList;
extern NSString *OTRAllBroadcastGroupList;
extern NSString *OTRRoomGroupList;

extern NSString *OTRPushAccountGroup;
extern NSString *OTRPushDeviceGroup;
extern NSString *OTRPushTokenGroup;

@interface OTRDatabaseView : NSObject

+ (BOOL)registerAllBroadcastListDatabaseView;

+ (BOOL)registerContactDatabaseView;

+ (BOOL)registerContactByGroupDatabaseView;

+ (BOOL)registerConversationDatabaseView;

+ (BOOL)registerAllAccountsDatabaseView;

+ (BOOL)registerChatDatabaseView;

+ (BOOL)registerEventDatabaseView;

+ (BOOL)registerBuddyNameSearchDatabaseView;

+ (BOOL)registerChatNameSearchDatabaseView;

+ (BOOL)registerAllBuddiesDatabaseView;

+ (BOOL)registerAllBuddiesNoStatusDatabaseView;

+ (BOOL)registerAllSubscriptionRequestsView;

+ (BOOL)registerUnreadMessagesView;

@end
