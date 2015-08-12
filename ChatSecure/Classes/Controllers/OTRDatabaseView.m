//
//  OTRDatabaseView.m
//  Off the Record
//
//  Created by David Chiles on 3/31/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRDatabaseView.h"
#import "YapDatabaseView.h"
#import "YapDatabase.h"
#import "OTRDatabaseManager.h"

#import "OTRBuddy.h"
#import "OTRAccount.h"
#import "OTRMessage.h"
#import "OTRXMPPBuddy.h"
#import "OTRGroup.h"
#import "OTRBuddyGroup.h"
#import "OTRBroadcastGroup.h"
#import "OTREvent.h"
#import "OTRRoom.h"
#import "OTRXMPPRoom.h"
#import "OTRXMPPChatter.h"

#import "OTRXMPPPresenceSubscriptionRequest.h"
#import "YapDatabaseFullTextSearch.h"
#import "YapDatabaseFilteredView.h"

#import "OTRDateUtil.h"

NSString *OTRConversationGroup = @"Conversation";
NSString *OTRConversationDatabaseViewExtensionName = @"OTRConversationDatabaseViewExtensionName";
NSString *OTRChatDatabaseViewExtensionName = @"OTRChatDatabaseViewExtensionName";
NSString *OTREventDatabaseViewExtensionName = @"OTREventDatabaseViewExtensionName";
NSString *OTRBuddyNameSearchDatabaseViewExtensionName = @"OTRBuddyBuddyNameSearchDatabaseViewExtensionName";
NSString *OTRAllBuddiesDatabaseViewExtensionName = @"OTRAllBuddiesDatabaseViewExtensionName";
NSString *OTRAllBuddiesNoStatusDatabaseViewExtensionName = @"OTRAllBuddiesNoStatusDatabaseViewExtensionName";
NSString *OTRAllSubscriptionRequestsViewExtensionName = @"AllSubscriptionRequestsViewExtensionName";
NSString *OTRAllPushAccountInfoViewExtensionName = @"OTRAllPushAccountInfoViewExtensionName";
NSString *OTRUnreadMessagesViewExtensionName = @"OTRUnreadMessagesViewExtensionName";
NSString *OTRContactByGroupDatabaseViewExtensionName = @"OTRContactByGroupDatabaseViewExtensionName";
NSString *OTRContactDatabaseViewExtensionName = @"OTRContactDatabaseViewExtensionName";
NSString *OTRAllBroadcastListDatabaseViewExtensionName = @"OTRAllBroadcastListDatabaseViewExtensionName";
NSString *OTRRoomDatabaseViewExtensionName = @"OTRRoomDatabaseViewExtensionName";

NSString *OTRChatNameSearchDatabaseViewExtensionName = @"OTRChatNameSearchDatabaseViewExtensionName";

NSString *OTRAllAccountGroup = @"All Accounts";
NSString *OTRAllAccountDatabaseViewExtensionName = @"OTRAllAccountDatabaseViewExtensionName";
NSString *OTRChatMessageGroup = @"Messages";
NSString *OTRAllPresenceSubscriptionRequestGroup = @"OTRAllPresenceSubscriptionRequestGroup";
NSString *OTRUnreadMessageGroup = @"Unread Messages";
NSString *OTRAllBuddiesGroupList = @"All Buddies to Compose";
NSString *OTRAllBuddiesNoStatusGroupList = @"All Buddies to Compose";
NSMutableArray *OTRContactByGroupList;
NSString *OTRBuddyNoGroupList = @"All Buddies with no group";
NSString *OTRAllBroadcastGroupList = @"All Broadcast Groups";
NSString *OTRRoomGroupList = @"All Rooms";


NSString *OTRPushTokenGroup = @"Tokens";
NSString *OTRPushDeviceGroup = @"Devices";
NSString *OTRPushAccountGroup = @"Account";

@implementation OTRDatabaseView



+ (BOOL)registerRoomDatabaseView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRRoomDatabaseViewExtensionName]) {
        return YES;
    }
    
    YapDatabaseViewBlockType groupingBlockType;
    YapDatabaseViewGroupingWithObjectBlock groupingBlock;
    
    YapDatabaseViewBlockType sortingBlockType;
    YapDatabaseViewSortingWithObjectBlock sortingBlock;
    
    groupingBlockType = YapDatabaseViewBlockTypeWithObject;
    
    groupingBlock = ^NSString *(NSString *collection, NSString *key, id object){
        
        
        if ([collection isEqualToString:[OTRChatter collection]])
        {
            OTRChatter *chatter = (OTRChatter *)object;
            __block BOOL isroomCreated = NO;
            if([chatter isKindOfClass:[OTRRoom class]])
            {
                if(((OTRXMPPRoom *)chatter).isRoomCreated) {
                    isroomCreated = TRUE;
                }else{
                    isroomCreated = FALSE;
                }
            }
            if (isroomCreated) {
                
                return OTRRoomGroupList;
                
            }
            
        }
        return nil;
    };
    
    sortingBlockType = YapDatabaseViewBlockTypeWithObject;
    
    sortingBlock =  ^(NSString *room, NSString *collection1, NSString *key1, id obj1, NSString *collection2, NSString *key2, id obj2) {
        if ([room isEqualToString:OTRRoomGroupList]) {
            OTRRoom *room1 = (OTRRoom *)obj1;
            OTRRoom *room2 = (OTRRoom *)obj2;
            
            
            NSString *room1String = room1.username;
            NSString *room2String = room2.username;
            
            if ([room1.username length]) {
                room1String = room1.username;
            }
            
            if ([room2.username length]) {
                room2String = room2.username;
            }
            
            return [room1String compare:room2String options:NSCaseInsensitiveSearch];
            
            
        }
        return NSOrderedSame;
        
    };
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRRoom collection]]];
    
    YapDatabaseView *view = [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock groupingBlockType:groupingBlockType sortingBlock:sortingBlock sortingBlockType:sortingBlockType versionTag:@"" options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:view withName:OTRRoomDatabaseViewExtensionName];
    
}


+(BOOL)registerAllBroadcastListDatabaseView
{
    YapDatabaseView *broadcastListView = [[OTRDatabaseManager sharedInstance].database registeredExtension:OTRAllBroadcastListDatabaseViewExtensionName];
    if (broadcastListView) {
        return YES;
    }
    
    
    YapDatabaseViewBlockType groupingBlockType;
    YapDatabaseViewGroupingWithObjectBlock groupingBlock;
    
    YapDatabaseViewBlockType sortingBlockType;
    YapDatabaseViewSortingWithObjectBlock sortingBlock;
    
    groupingBlockType = YapDatabaseViewBlockTypeWithObject;
    groupingBlock = ^NSString *(NSString *collection, NSString *key, id object){
        
        if ([collection isEqualToString:[OTRChatter collection]])
        {
            OTRChatter *chatter = (OTRChatter *)object;
            if([chatter isKindOfClass:[OTRBroadcastGroup class]])
            {
                return OTRAllBroadcastGroupList;
            }
            
            return nil;
        }
        
        return nil;
    };
    
    sortingBlockType = YapDatabaseViewBlockTypeWithObject;
    sortingBlock = ^(NSString *group, NSString *collection1, NSString *key1, id obj1,
                     NSString *collection2, NSString *key2, id obj2){
        if ([group isEqualToString:OTRAllBroadcastGroupList]) {
            if ([obj1 isKindOfClass:[OTRBroadcastGroup class]] && [obj1 isKindOfClass:[OTRBroadcastGroup class]]) {
                OTRBroadcastGroup *broadcastGroup1 = (OTRBroadcastGroup *)obj1;
                OTRBroadcastGroup *broadcastGroup2 = (OTRBroadcastGroup *)obj2;
                
                return [broadcastGroup1.displayName compare:broadcastGroup2.displayName options:NSCaseInsensitiveSearch];
            }
        }
        return NSOrderedSame;
    };
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRBroadcastGroup collection]]];
    
    YapDatabaseView *databaseView =
    [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock
                                 groupingBlockType:groupingBlockType
                                      sortingBlock:sortingBlock
                                  sortingBlockType:sortingBlockType
                                        versionTag:@""
                                           options:options];
    return [[OTRDatabaseManager sharedInstance].database registerExtension:databaseView withName:OTRAllBroadcastListDatabaseViewExtensionName];
}


+ (BOOL)registerContactDatabaseView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRContactDatabaseViewExtensionName]) {
        return YES;
    }
    
    YapDatabaseViewBlockType groupingBlockType;
    YapDatabaseViewGroupingWithObjectBlock groupingBlock;
    
    YapDatabaseViewBlockType sortingBlockType;
    YapDatabaseViewSortingWithObjectBlock sortingBlock;
    
    groupingBlockType = YapDatabaseViewBlockTypeWithObject;
    
    groupingBlock = ^NSString *(NSString *collection, NSString *key, id object){
        
        if ([object isKindOfClass:[OTRBuddy class]])
        {
            OTRBuddy *buddy = (OTRBuddy *)object;
            __block BOOL isPendingApproval = NO;
            if ([buddy isKindOfClass:[OTRXMPPBuddy class]]) {
                if(((OTRXMPPBuddy *)buddy).isPendingApproval) {
                    isPendingApproval = TRUE;
                }else{
                    isPendingApproval = FALSE;
                }
            }
            if (!isPendingApproval) {
                __block NSMutableArray *buddyGroups = [[NSMutableArray alloc] init];
                [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction)  {
                    
                    buddyGroups = [OTRBuddyGroup fetchGroupBuddiesFromBuddy:buddy transaction:transaction];
                    
                }];
                
                if(![buddyGroups count] > 0)
                {
                    return OTRBuddyNoGroupList;
                }
            }
            
        }
        return nil;
    };
    
    sortingBlockType = YapDatabaseViewBlockTypeWithObject;
    
    sortingBlock =  ^(NSString *group, NSString *collection1, NSString *key1, id obj1, NSString *collection2, NSString *key2, id obj2) {
        if ([group isEqualToString:OTRBuddyNoGroupList]) {
            OTRBuddy *buddy1 = (OTRBuddy *)obj1;
            OTRBuddy *buddy2 = (OTRBuddy *)obj2;
            
            if (buddy1.status == buddy2.status) {
                NSString *buddy1String = buddy1.username;
                NSString *buddy2String = buddy2.username;
                
                if ([buddy1.displayName length]) {
                    buddy1String = buddy1.displayName;
                }
                
                if ([buddy2.displayName length]) {
                    buddy2String = buddy2.displayName;
                }
                
                return [buddy1String compare:buddy2String options:NSCaseInsensitiveSearch];
            }
            else if (buddy1.status < buddy2.status) {
                return NSOrderedAscending;
            }
            else{
                return NSOrderedDescending;
            }
        }
        return NSOrderedSame;
        
    };
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRBuddy collection]]];
    
    YapDatabaseView *view = [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock groupingBlockType:groupingBlockType sortingBlock:sortingBlock sortingBlockType:sortingBlockType versionTag:@"" options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:view withName:OTRContactDatabaseViewExtensionName];
    
}





+ (BOOL)registerContactByGroupDatabaseView
{
    
    OTRContactByGroupList = [[NSMutableArray alloc] init];
    
    YapDatabaseView *contactByGroupView = [[OTRDatabaseManager sharedInstance].database registeredExtension:OTRContactByGroupDatabaseViewExtensionName];
    if (contactByGroupView) {
        return YES;
    }
    
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[OTRBuddyGroup class]])
        {
            OTRBuddyGroup *buddyGroup = (OTRBuddyGroup *)object;
            
            __block OTRGroup *localGroup = nil;
            [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                localGroup = [[OTRGroup fetchObjectWithUniqueID:buddyGroup.groupUniqueId transaction:transaction] copy];
            }];
            
            
            if(![OTRContactByGroupList containsObject:[@"OTR" stringByAppendingString:localGroup.displayName]])
            {
                [OTRContactByGroupList addObject:[@"OTR" stringByAppendingString:localGroup.displayName]];
                return [@"OTR" stringByAppendingString:localGroup.displayName];
            }
            else{
                return [@"OTR" stringByAppendingString:localGroup.displayName];
            }
            
        }
        
        return nil; // exclude from view
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        
        if ([object1 isKindOfClass:[OTRBuddyGroup class]] && [object2 isKindOfClass:[OTRBuddyGroup class]]) {
            
            
            OTRBuddyGroup* buddyGroup1 = (OTRBuddyGroup *)object1;
            OTRBuddyGroup *buddyGroup2 = (OTRBuddyGroup *)object2;
            
            __block OTRBuddy *buddy1 = nil;
            __block OTRBuddy *buddy2 = nil;
            
            [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                buddy1 = [[OTRBuddy fetchObjectWithUniqueID:buddyGroup1.buddyUniqueId transaction:transaction] copy];
                buddy2 = [[OTRBuddy fetchObjectWithUniqueID:buddyGroup2.buddyUniqueId transaction:transaction] copy];
            }];
            
            if (buddy1.status == buddy2.status) {
                NSString *buddy1String = buddy1.username;
                NSString *buddy2String = buddy2.username;
                
                if ([buddy1.displayName length]) {
                    buddy1String = buddy1.displayName;
                }
                
                if ([buddy2.displayName length]) {
                    buddy2String = buddy2.displayName;
                }
                
                return [buddy1String compare:buddy2String options:NSCaseInsensitiveSearch];
            }
            else if (buddy1.status < buddy2.status) {
                return NSOrderedAscending;
            }
            else{
                return NSOrderedDescending;
            }
            
            return NSOrderedSame;
            
        }
        
        return NSOrderedSame;
    }];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRBuddyGroup collection]]];
    
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                                      sorting:viewSorting
                                                                   versionTag:@"1"
                                                                      options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:databaseView withName:OTRContactByGroupDatabaseViewExtensionName];
}


+ (BOOL)registerConversationDatabaseView
{
    YapDatabaseView *conversationView = [[OTRDatabaseManager sharedInstance].database registeredExtension:OTRConversationDatabaseViewExtensionName];
    if (conversationView) {
        return YES;
    }
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if (![object isKindOfClass:[OTRBroadcastGroup class]])
        {
            OTRChatter *buddy = (OTRChatter *)object;
            if (buddy.lastMessageDate) {
                return OTRConversationGroup;
            }
        }
        return nil; // exclude from view
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        if ([group isEqualToString:OTRConversationGroup]) {
            if ([object1 isKindOfClass:[OTRChatter class]] && [object2 isKindOfClass:[OTRChatter class]]) {
                OTRChatter *buddy1 = (OTRChatter *)object1;
                OTRChatter *buddy2 = (OTRChatter *)object2;
                
                return [buddy2.lastMessageDate compare:buddy1.lastMessageDate];
            }
        }
        return NSOrderedSame;
    }];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRChatter collection]]];
    
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                                      sorting:viewSorting
                                                                   versionTag:@"1"
                                                                      options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:databaseView withName:OTRConversationDatabaseViewExtensionName];
}




+ (BOOL)registerAllAccountsDatabaseView
{
    YapDatabaseView *accountView = [[OTRDatabaseManager sharedInstance].database registeredExtension:OTRAllAccountDatabaseViewExtensionName];
    if (accountView) {
        return YES;
    }
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withKeyBlock:^NSString *(NSString *collection, NSString *key) {
        if ([collection isEqualToString:[OTRAccount collection]])
        {
            return OTRAllAccountGroup;
        }
        
        return nil;
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        if ([group isEqualToString:OTRAllAccountGroup]) {
            if ([object1 isKindOfClass:[OTRAccount class]] && [object2 isKindOfClass:[OTRAccount class]]) {
                OTRAccount *account1 = (OTRAccount *)object1;
                OTRAccount *account2 = (OTRAccount *)object2;
                
                return [account1.displayName compare:account2.displayName options:NSCaseInsensitiveSearch];
            }
        }
        return NSOrderedSame;
    }];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRAccount collection]]];
    
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                                      sorting:viewSorting
                                                                   versionTag:@"1"
                                                                      options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:databaseView withName:OTRAllAccountDatabaseViewExtensionName];
}

+ (BOOL)registerChatDatabaseView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRChatDatabaseViewExtensionName]) {
        return YES;
    }
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[OTRMessage class]])
        {
            return ((OTRMessage *)object).chatterUniqueId;
        }
        return nil;
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        if ([object1 isKindOfClass:[OTRMessage class]] && [object2 isKindOfClass:[OTRMessage class]]) {
            OTRMessage *message1 = (OTRMessage *)object1;
            OTRMessage *message2 = (OTRMessage *)object2;
            
            return [message1.date compare:message2.date];
        }
        return NSOrderedSame;
    }];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRMessage collection]]];
    
    
    
    YapDatabaseView *view = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                              sorting:viewSorting
                                                           versionTag:@"1"
                                                              options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:view withName:OTRChatDatabaseViewExtensionName];
}



+ (BOOL)registerEventDatabaseView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTREventDatabaseViewExtensionName]) {
        return YES;
    }
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[OTREvent class]])
        {
            if(((OTREvent *)object).day)
                return [OTRDateUtil curentDateStringFromDate:((OTREvent *)object).day withFormat:DATE_FORMAT];
            
        }
        return nil;
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        if ([object1 isKindOfClass:[OTRMessage class]] && [object2 isKindOfClass:[OTRMessage class]]) {
            OTRMessage *message1 = (OTRMessage *)object1;
            OTRMessage *message2 = (OTRMessage *)object2;
            
            return [message1.date compare:message2.date];
        }
        return NSOrderedSame;
    }];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTREvent collection]]];
    
    
    
    YapDatabaseView *view = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                              sorting:viewSorting
                                                           versionTag:@"1"
                                                              options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:view withName:OTREventDatabaseViewExtensionName];
}


+ (BOOL)registerBuddyNameSearchDatabaseView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRBuddyNameSearchDatabaseViewExtensionName]) {
        return YES;
    }
    
    NSArray *propertiesToIndex = @[OTRChatterAttributes.username, OTRChatterAttributes.displayName, OTRGroupAttributes.displayName];
    
    YapDatabaseFullTextSearchHandler *searchHandler = [YapDatabaseFullTextSearchHandler withObjectBlock:^(NSMutableDictionary *dict, NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[OTRBuddy class]])
        {
            OTRBuddy *buddy = (OTRBuddy *)object;
            
            __block BOOL isPendingApproval = NO;
            if ([buddy isKindOfClass:[OTRXMPPBuddy class]]) {
                if(((OTRXMPPBuddy *)buddy).isPendingApproval) {
                    isPendingApproval = TRUE;
                }else{
                    isPendingApproval = FALSE;
                }
            }
            if (!isPendingApproval) {
                if([buddy.username length]) {
                    [dict setObject:buddy.username forKey:OTRChatterAttributes.username];
                }
                
                if ([buddy.displayName length]) {
                    [dict setObject:buddy.displayName forKey:OTRChatterAttributes.displayName];
                }
                
            }
        }
        
        if ([object isKindOfClass:[OTRGroup class]])
        {
            OTRGroup *group = (OTRGroup *)object;
            [dict setObject:group.displayName forKey:OTRGroupAttributes.displayName];
            
        }
        
    }];
    
    YapDatabaseFullTextSearch *fullTextSearch = [[YapDatabaseFullTextSearch alloc] initWithColumnNames:propertiesToIndex handler:searchHandler];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:fullTextSearch withName:OTRBuddyNameSearchDatabaseViewExtensionName];
}


//Search

+ (BOOL)registerChatNameSearchDatabaseView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRChatNameSearchDatabaseViewExtensionName]) {
        return YES;
    }
    
    
    NSArray *propertiesToIndex = @[OTRChatterAttributes.username, OTRChatterAttributes.displayName, OTRMessageAttributes.text, OTRMessageAttributes.date];
    
    YapDatabaseFullTextSearchHandler *searchHandler = [YapDatabaseFullTextSearchHandler withObjectBlock:^(NSMutableDictionary *dict, NSString *collection, NSString *key, id object) {
        
        if ([object isKindOfClass:[OTRChatter class]])
        {
            if(![object isKindOfClass:[OTRBroadcastGroup class]])
            {
                OTRChatter *buddy = (OTRChatter *)object;
                
                if (buddy.lastMessageDate) {
                    
                    if([buddy.username length]) {
                        [dict setObject:buddy.username forKey:OTRChatterAttributes.username];
                    }
                    
                    if ([buddy.displayName length]) {
                        [dict setObject:buddy.displayName forKey:OTRChatterAttributes.displayName];
                    }
                    
                }
            }
            
        }
        
        if ([object isKindOfClass:[OTRMessage class]])
        {
            OTRMessage *message = (OTRMessage *)object;
            
            
            __block OTRChatter *buddy;
            [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                buddy = [message chatterWithTransaction:transaction];
            }];
            
            if(![buddy isKindOfClass:[OTRBroadcastGroup class]])
            {
                
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyy/MM/dd HH:mm:ss"]; //this is the sqlite's format
                NSString *formattedDateStringTime = [formatter stringFromDate:message.date];
                
                if(message.text)
                    [dict setObject:message.text forKey:OTRMessageAttributes.text];
                
                [dict setObject:formattedDateStringTime forKey:OTRMessageAttributes.date];
            }
            
            
        }
    }];
    
    YapDatabaseFullTextSearch *fullTextSearch = [[YapDatabaseFullTextSearch alloc] initWithColumnNames:propertiesToIndex handler:searchHandler];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:fullTextSearch withName:OTRChatNameSearchDatabaseViewExtensionName];
}




+ (BOOL)registerAllBuddiesDatabaseView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRAllBuddiesDatabaseViewExtensionName]) {
        return YES;
    }
    
    YapDatabaseViewBlockType groupingBlockType;
    YapDatabaseViewGroupingWithObjectBlock groupingBlock;
    
    YapDatabaseViewBlockType sortingBlockType;
    YapDatabaseViewSortingWithObjectBlock sortingBlock;
    
    groupingBlockType = YapDatabaseViewBlockTypeWithObject;
    
    groupingBlock = ^NSString *(NSString *collection, NSString *key, id object){
        
        if ([object isKindOfClass:[OTRBuddy class]])
        {
            OTRBuddy *buddy = (OTRBuddy *)object;
            __block BOOL isPendingApproval = NO;
            if ([buddy isKindOfClass:[OTRXMPPBuddy class]]) {
                if(((OTRXMPPBuddy *)buddy).isPendingApproval) {
                    isPendingApproval = TRUE;
                }else{
                    isPendingApproval = FALSE;
                }
            }
            if (!isPendingApproval) {
                return OTRAllBuddiesGroupList;
            }
            
        }
        return nil;
    };
    
    sortingBlockType = YapDatabaseViewBlockTypeWithObject;
    
    sortingBlock =  ^(NSString *group, NSString *collection1, NSString *key1, id obj1, NSString *collection2, NSString *key2, id obj2) {
        if ([group isEqualToString:OTRAllBuddiesGroupList]) {
            OTRBuddy *buddy1 = (OTRBuddy *)obj1;
            OTRBuddy *buddy2 = (OTRBuddy *)obj2;
            
            if (buddy1.status == buddy2.status) {
                NSString *buddy1String = buddy1.username;
                NSString *buddy2String = buddy2.username;
                
                if ([buddy1.displayName length]) {
                    buddy1String = buddy1.displayName;
                }
                
                if ([buddy2.displayName length]) {
                    buddy2String = buddy2.displayName;
                }
                
                return [buddy1String compare:buddy2String options:NSCaseInsensitiveSearch];
            }
            else if (buddy1.status < buddy2.status) {
                return NSOrderedAscending;
            }
            else{
                return NSOrderedDescending;
            }
        }
        return NSOrderedSame;
        
    };
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRBuddy collection]]];
    
    YapDatabaseView *view = [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock groupingBlockType:groupingBlockType sortingBlock:sortingBlock sortingBlockType:sortingBlockType versionTag:@"" options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:view withName:OTRAllBuddiesDatabaseViewExtensionName];
}



+ (BOOL)registerAllBuddiesNoStatusDatabaseView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRAllBuddiesNoStatusDatabaseViewExtensionName]) {
        return YES;
    }
    
    YapDatabaseViewBlockType groupingBlockType;
    YapDatabaseViewGroupingWithObjectBlock groupingBlock;
    
    YapDatabaseViewBlockType sortingBlockType;
    YapDatabaseViewSortingWithObjectBlock sortingBlock;
    
    groupingBlockType = YapDatabaseViewBlockTypeWithObject;
    
    groupingBlock = ^NSString *(NSString *collection, NSString *key, id object){
        
        if ([object isKindOfClass:[OTRBuddy class]])
        {
            OTRBuddy *buddy = (OTRBuddy *)object;
            __block BOOL isPendingApproval = NO;
            if ([buddy isKindOfClass:[OTRXMPPBuddy class]]) {
                if(((OTRXMPPBuddy *)buddy).isPendingApproval) {
                    isPendingApproval = TRUE;
                }else{
                    isPendingApproval = FALSE;
                }
            }
            if (!isPendingApproval) {
                return OTRAllBuddiesNoStatusGroupList;
            }
            
        }
        return nil;
    };
    
    sortingBlockType = YapDatabaseViewBlockTypeWithObject;
    
    sortingBlock =  ^(NSString *group, NSString *collection1, NSString *key1, id obj1, NSString *collection2, NSString *key2, id obj2) {
        if ([group isEqualToString:OTRAllBuddiesGroupList]) {
            OTRBuddy *buddy1 = (OTRBuddy *)obj1;
            OTRBuddy *buddy2 = (OTRBuddy *)obj2;
            
            
            NSString *buddy1String = buddy1.username;
            NSString *buddy2String = buddy2.username;
            
            if ([buddy1.displayName length]) {
                buddy1String = buddy1.displayName;
            }
            
            if ([buddy2.displayName length]) {
                buddy2String = buddy2.displayName;
            }
            
            return [buddy1String compare:buddy2String options:NSCaseInsensitiveSearch];
       
        }
        return NSOrderedSame;
        
    };
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRBuddy collection]]];
    
    YapDatabaseView *view = [[YapDatabaseView alloc] initWithGroupingBlock:groupingBlock groupingBlockType:groupingBlockType sortingBlock:sortingBlock sortingBlockType:sortingBlockType versionTag:@"" options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:view withName:OTRAllBuddiesNoStatusDatabaseViewExtensionName];
}




+ (BOOL)registerAllSubscriptionRequestsView
{
    if ([[OTRDatabaseManager sharedInstance].database registeredExtension:OTRAllSubscriptionRequestsViewExtensionName]) {
        return YES;
    }
    
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withKeyBlock:^NSString *(NSString *collection, NSString *key) {
        if ([collection isEqualToString:[OTRXMPPPresenceSubscriptionRequest collection]])
        {
            return OTRAllPresenceSubscriptionRequestGroup;
        }
        
        return nil;
    }];
    
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        
        OTRXMPPPresenceSubscriptionRequest *request1 = (OTRXMPPPresenceSubscriptionRequest *)object1;
        OTRXMPPPresenceSubscriptionRequest *request2 = (OTRXMPPPresenceSubscriptionRequest *)object2;
        
        if (request1 && request2) {
            return [request1.date compare:request2.date];
        }
        
        return NSOrderedSame;
    }];
    
    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[OTRXMPPPresenceSubscriptionRequest collection]]];
    
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                                      sorting:viewSorting
                                                                   versionTag:@"1"
                                                                      options:options];
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:databaseView withName:OTRAllSubscriptionRequestsViewExtensionName];
}

+ (BOOL)registerUnreadMessagesView
{
    
    YapDatabaseViewFiltering *viewFiltering = [YapDatabaseViewFiltering withObjectBlock:^BOOL(NSString *group, NSString *collection, NSString *key, id object) {
        
        if ([object isKindOfClass:[OTRMessage class]]) {
            return !((OTRMessage *)object).isRead;
        }
        return NO;
    }];
    
    YapDatabaseFilteredView *filteredView = [[YapDatabaseFilteredView alloc] initWithParentViewName:OTRChatDatabaseViewExtensionName
                                                                                          filtering:viewFiltering];
    
    
    return [[OTRDatabaseManager sharedInstance].database registerExtension:filteredView withName:OTRUnreadMessagesViewExtensionName];
}

@end
