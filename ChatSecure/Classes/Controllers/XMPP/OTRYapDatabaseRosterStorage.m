//
//  OTRYapDatabaseRosterStorage.m
//  Off the Record
//
//  Created by David Chiles on 3/31/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseRosterStorage.h"

#import "YapDatabaseConnection.h"
#import "OTRDatabaseManager.h"
#import "YapDatabaseTransaction.h"
#import "OTRLog.h"
#import "Strings.h"
#import "OTRXMPPBuddy.h"
#import "OTRXMPPAccount.h"
#import "OTRBuddyGroup.h"
#import "OTRGroup.h"

@interface OTRYapDatabaseRosterStorage ()

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) NSString *accountUniqueId;

@end

@implementation OTRYapDatabaseRosterStorage

-(id)init
{
    if (self = [super init]) {
        self.databaseConnection = [[OTRDatabaseManager sharedInstance] newConnection];
    }
    return self;
}

#pragma - mark Helper Methods

- (OTRXMPPAccount *)accountForStream:(XMPPStream *)stream
{
    __block OTRXMPPAccount *account = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        account = [OTRXMPPAccount accountForStream:stream transaction:transaction];
    }];
    return account;
}

- (OTRXMPPBuddy *)buddyWithJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    __block OTRXMPPBuddy *buddy = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        buddy = [self buddyWithJID:jid xmppStream:stream transaction:transaction];
    }];
    return buddy;
}

- (OTRGroup *)groupWithName:(NSString *)name xmppStream:(XMPPStream *)stream
{
    __block OTRGroup *group = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        group = [self groupWithName:name xmppStream:stream transaction:transaction];
    }];
    return group;
}


- (OTRXMPPBuddy *)buddyWithJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream transaction:(YapDatabaseReadTransaction *)transaction
{
    if (![self.accountUniqueId length]) {
        OTRAccount *account = [OTRXMPPAccount accountForStream:stream transaction:transaction];
        self.accountUniqueId = account.uniqueId;
    }
    __block OTRXMPPBuddy *chatter = nil;
    
    chatter = [[OTRXMPPBuddy fetchChatterWithUsername:[jid bare] withAccountUniqueId:self.accountUniqueId transaction:transaction] copy];
    
    if (!chatter) {
        chatter = [[OTRXMPPBuddy alloc] init];
        chatter.username = [jid bare];
        chatter.accountUniqueId = self.accountUniqueId;
    }
    
    return chatter;
}



- (NSMutableArray *) fetchGroupsFromBuddy:(OTRBuddy *)buddy
{
    
    __block NSMutableArray *exGroups;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        exGroups = [OTRBuddyGroup fetchGroupBuddiesFromBuddy:buddy transaction:transaction];
    }];
    
    return exGroups;
}


- (OTRGroup *)groupWithName:(NSString *)name xmppStream:(XMPPStream *)stream transaction:(YapDatabaseReadTransaction *)transaction
{
    if (![self.accountUniqueId length]) {
        OTRAccount *account = [OTRXMPPAccount accountForStream:stream transaction:transaction];
        self.accountUniqueId = account.uniqueId;
    }
    __block OTRGroup *group = nil;
    
    group = [[OTRGroup fetchGroupWithGroupName:name withAccountUniqueId:self.accountUniqueId transaction:transaction] copy];
    
    if (!group) {
        group = [[OTRGroup alloc] initWithGroupName:name];
        group.accountUniqueId = self.accountUniqueId;
    }
    
    return group;
}

- (BOOL)existsBuddyWithJID:(XMPPJID *)jid xmppStram:(XMPPStream *)stream
{
    __block BOOL result = NO;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        OTRXMPPAccount *account = [OTRXMPPAccount accountForStream:stream transaction:transaction];
        OTRChatter *chatter = [OTRChatter fetchChatterWithUsername:[jid bare] withAccountUniqueId:account.uniqueId transaction:transaction];
        
        if (chatter) {
            result = YES;
        }
    }];
    return result;
}

-(BOOL)isPendingApprovalElement:(NSXMLElement *)item
{
    NSString *subscription = [item attributeStringValueForName:@"subscription"];
	NSString *ask = [item attributeStringValueForName:@"ask"];
	
	if ([subscription isEqualToString:@"none"] || [subscription isEqualToString:@"from"])
    {
        if([ask isEqualToString:@"subscribe"])
        {
            return YES;
        }
    }
    return NO;
}

- (void)updateBuddy:(OTRXMPPBuddy *)chatter withItem:(NSXMLElement *)item
{
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        
        OTRXMPPBuddy *localBuddy = [[OTRXMPPBuddy fetchObjectWithUniqueID:chatter.uniqueId transaction:transaction] copy];
        if (!localBuddy) {
            localBuddy = chatter;
        }
        
        if (![localBuddy isKindOfClass:[OTRXMPPBuddy class]]) {
            OTRXMPPBuddy *xmppChatter = [[OTRXMPPBuddy alloc] init];
            [xmppChatter mergeValuesForKeysFromModel:localBuddy];
            [localBuddy removeWithTransaction:transaction];
            localBuddy = xmppChatter;
        }
        
        localBuddy.displayName = [item attributeStringValueForName:@"name"];
        
        
        if ([self isPendingApprovalElement:item]) {
            localBuddy.pendingApproval = YES;
        }
        else {
            localBuddy.pendingApproval = NO;
        }
        
        
        [localBuddy saveWithTransaction:transaction];
    }];
}

- (void) removeEmptyGroups:(NSMutableArray *)groupArray withBuddy:(OTRBuddy *)buddy
{
    NSMutableArray *exGroups = [self fetchGroupsFromBuddy:buddy];
    
    if(exGroups.count > 0)
    {
        for(OTRBuddyGroup *buddyGroup in exGroups)
        {
            [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                
                OTRGroup *group = [OTRGroup fetchObjectWithUniqueID:buddyGroup.groupUniqueId transaction:transaction];
                
                if(![groupArray containsObject:group])
                {
                    [transaction setObject:nil forKey:buddyGroup.uniqueId inCollection:[OTRBuddyGroup collection]];
                    return;
                }
            }];
        }
    }
}



#pragma - mark XMPPRosterStorage Methods

- (BOOL)configureWithParent:(XMPPRoster *)aParent queue:(dispatch_queue_t)queue
{
    return YES;
}

- (void)beginRosterPopulationForXMPPStream:(XMPPStream *)stream
{
    DDLogVerbose(@"%@ - %@",THIS_FILE,THIS_METHOD);
}
- (void)endRosterPopulationForXMPPStream:(XMPPStream *)stream
{
    DDLogVerbose(@"%@ - %@",THIS_FILE,THIS_METHOD);
}

- (void)handleRosterItem:(NSXMLElement *)item xmppStream:(XMPPStream *)stream
{
    
    NSString *jidStr = [item attributeStringValueForName:@"jid"];
    NSArray *groups = [item elementsForName:@"group"];
    XMPPJID *jid = [[XMPPJID jidWithString:jidStr] bareJID];
    
    
    if([[jid bare] isEqualToString:[[stream myJID] bare]])
    {
        // ignore self buddy
        return;
    }
    
    OTRXMPPBuddy *buddy = [self buddyWithJID:jid xmppStream:stream];
    if(![buddy isKindOfClass:[OTRXMPPBuddy class]])
        return;
    
    NSMutableArray *groupsArray = [[NSMutableArray alloc] init];
    
    
    if([groups count] >= 1)
    {
        
        for (DDXMLElement *object in groups)
        {
            OTRGroup *group = [self groupWithName:[object stringValue] xmppStream:stream];
            
            if(group)
            {
                
                [groupsArray addObject:group];
                
                [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                    [group saveWithTransaction:transaction];
                }];
            }
            
            if(buddy)
            {
                
                [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                    OTRBuddyGroup *buddyGroup = [OTRBuddyGroup fetchBuddyGroupWithBuddyUniqueId:buddy.uniqueId withGroupUniqueId:group.uniqueId transaction:transaction];
                    
                    if (!buddyGroup) {
                        buddyGroup = [[OTRBuddyGroup alloc] init];
                        buddyGroup.buddyUniqueId = buddy.uniqueId;
                        buddyGroup.groupUniqueId = group.uniqueId;
                    }
                    
                    if(buddyGroup)
                        [buddyGroup saveWithTransaction:transaction];
                    
                }];
            }
            
            
        }
        
    }
    else
    {
        
        NSString *subscription = [item attributeStringValueForName:@"subscription"];
        if ([subscription isEqualToString:@"remove"])
        {
            if (buddy)
            {
                [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                    [transaction setObject:nil forKey:buddy.uniqueId inCollection:[OTRChatter collection]];
                }];
            }
        }
        
    }
    
    
    [self removeEmptyGroups:groupsArray withBuddy:buddy];
    
    if(buddy)
        [self updateBuddy:buddy withItem:item];

    
}

- (void)handlePresence:(XMPPPresence *)presence xmppStream:(XMPPStream *)stream
{
    
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        
        OTRXMPPBuddy *buddy = [self buddyWithJID:[presence from] xmppStream:stream transaction:transaction];
        
        OTRAccount *account = [OTRXMPPAccount accountForStream:stream transaction:transaction];
        
        if([buddy.username isEqualToString:account.username])
            return;
        
        if ([[presence type] isEqualToString:@"unavailable"] || [presence isErrorPresence]) {
            buddy.status = OTRChatterStatusOffline;
            buddy.statusMessage = OFFLINE_STRING;

        }
        else if (buddy) {
            NSString *defaultMessage = OFFLINE_STRING;
            switch (presence.intShow)
            {
                case 0  :
                    buddy.status = OTRChatterStatusDnd;
                    defaultMessage = DO_NOT_DISTURB_STRING;
                    break;
                case 1  :
                    buddy.status = OTRChatterStatusXa;
                    defaultMessage = EXTENDED_AWAY_STRING;
                    break;
                case 2  :
                    buddy.status = OTRChatterStatusAway;
                    defaultMessage = AWAY_STRING;
                    break;
                case 3  :
                case 4  :
                    buddy.status = OTRChatterStatusAvailable;
                    defaultMessage = AVAILABLE_STRING;
                    break;
                default :
                    buddy.status = OTRChatterStatusOffline;
                    break;
            }
            
            if ([[presence status] length]) {
                buddy.statusMessage = [presence status];
            }
            else {
                buddy.statusMessage = defaultMessage;
            }
            
        }
        
        buddy.dateLastChatState = [NSDate date];
        
        [buddy saveWithTransaction:transaction];
      
        NSMutableArray *buddyGroups = [OTRBuddyGroup fetchGroupBuddiesFromBuddy:buddy transaction:transaction];
        
        if([buddyGroups count])
        {
            for(OTRBuddyGroup *buddyGroup in buddyGroups)
            {
                [buddyGroup saveWithTransaction:transaction];
            }
        }
    }];
    
}

- (BOOL)userExistsWithJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    if ([self existsBuddyWithJID:jid xmppStram:stream]) {
        return YES;
    }
    else {
        return NO;
    }
}

- (void)clearAllResourcesForXMPPStream:(XMPPStream *)stream
{
    DDLogVerbose(@"%@ - %@",THIS_FILE,THIS_METHOD);

}
- (void)clearAllUsersAndResourcesForXMPPStream:(XMPPStream *)stream
{
    DDLogVerbose(@"%@ - %@",THIS_FILE,THIS_METHOD);

}

- (NSArray *)jidsForXMPPStream:(XMPPStream *)stream
{
    __block NSMutableArray *jidArray = [NSMutableArray array];
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [transaction enumerateKeysAndObjectsInCollection:[OTRXMPPBuddy collection] usingBlock:^(NSString *key, id object, BOOL *stop) {
            if ([object isKindOfClass:[OTRXMPPBuddy class]]) {
                OTRXMPPBuddy *buddy = (OTRXMPPBuddy *)object;
                if ([buddy.username length]) {
                    [jidArray addObject:buddy.username];
                }
            }
        }];
    }];
    return jidArray;
}

@end
