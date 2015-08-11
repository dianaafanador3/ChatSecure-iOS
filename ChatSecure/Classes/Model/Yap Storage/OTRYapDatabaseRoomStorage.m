//
//  OTRYapDatabaseRoomStorage.m
//  ChatSecure
//
//  Created by Diana Perez on 1/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseRoomStorage.h"
#import "YapDatabaseConnection.h"
#import "OTRDatabaseManager.h"
#import "YapDatabaseTransaction.h"

#import "OTRXMPPRoom.h"
#import "OTRAccount.h"
#import "OTRGroup.h"
#import "OTRBuddyGroup.h"

@interface OTRYapDatabaseRoomStorage ()

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) NSString *accountUniqueId;

@end

@implementation OTRYapDatabaseRoomStorage

-(id)init
{
    if (self = [super init]) {
        self.databaseConnection = [[OTRDatabaseManager sharedInstance] newConnection];
        
        
        self.messages  = [[NSMutableArray alloc] init];
        self.occupants  = [[NSMutableArray alloc] init];

        self.occupantsArray = [[NSMutableArray alloc] init];
        
    
    }
    return self;
}

- (BOOL)configureWithParent:(XMPPRoom *)aParent queue:(dispatch_queue_t)queue
{
    return true;
}



#pragma - mark Helper Methods


- (OTRXMPPRoom *)roomWithJID:(XMPPJID *)jid room:(XMPPRoom *)room
{
    __block OTRXMPPRoom *xmppRoom = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        xmppRoom = [self roomWithJID:jid room:room transaction:transaction];
    }];
    return xmppRoom;
}

- (OTRXMPPRoom *)roomWithJID:(XMPPJID *)jid room:(XMPPRoom *)room transaction:(YapDatabaseReadTransaction *)transaction
{
    if (![self.accountUniqueId length]) {
        OTRAccount *account = [[OTRAccount allAccountsWithUsername:jid.resource transaction:transaction] firstObject];
        self.accountUniqueId = account.uniqueId;
    }
    __block OTRXMPPRoom *xmppRoom = nil;
    
    xmppRoom = [[OTRXMPPRoom fetchRoomWithGroupName:[jid user] withAccountUniqueId:self.accountUniqueId transaction:transaction] copy];
    
    if (!xmppRoom) {
        xmppRoom = [[OTRXMPPRoom alloc] init];
        xmppRoom.username = [jid bare];
        
        
        OTRGroup *group = [OTRGroup fetchGroupWithGroupName:[jid user] withAccountUniqueId:self.accountUniqueId transaction:transaction];
        if(group)
        {
            xmppRoom.displayName = group.displayName;
            xmppRoom.groupUniqueId = group.uniqueId;
        }
    }
    
    return xmppRoom;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRoomStorage Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)handlePresence:(XMPPPresence *)presence room:(XMPPRoom *)room
{
    
    XMPPJID *from = [presence from];
    
    OTRXMPPRoom *xmppRoom = [self roomWithJID:from room:room];
    
    __block OTRGroup *group = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {

        group = [OTRGroup fetchGroupWithGroupName:xmppRoom.displayName withAccountUniqueId:self.accountUniqueId transaction:transaction];
    }];
    
    __block OTRBuddyGroup *occupant = nil;
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        
        occupant = [OTRBuddyGroup fetchGroupBuddyFromGroup:group andBuddyName:[from resource] transaction:transaction];
        
        if ([[presence type] isEqualToString:@"unavailable"])
        {
            if (occupant)
            {
                // Occupant did leave - remove
                
                if(occupant.online)
                {
                    occupant.online = NO;
                }
                
            }
        }
        else
        {
            
            if (occupant)
            {
                if(!occupant.online)
                {
                    occupant.online = YES;
                }
                
                /*
                 update presence if we want to
                 
                 self.jid = jid;
                 self.presence = presence;
                 
                 self.priority = [presence priority];
                 self.intShow = [presence intShow];
                 
                 self.type = [presence type];
                 self.show = [presence show];
                 self.status = [presence status];*/
            }
            
        }
        
        [occupant saveWithTransaction:transaction];
    }];
    
    
}

- (void)handleOutgoingMessage:(XMPPMessage *)message room:(XMPPRoom *)room
{
    /*XMPPLogTrace();
    AssertParentQueue();
    
    XMPPJID *msgJID = room.myRoomJID;
    
    XMPPRoomMessageMemoryStorageObject *roomMsg;
    roomMsg = [[self.messageClass alloc] initWithOutgoingMessage:message jid:msgJID];
    
    [self addMessage:roomMsg];*/
}

- (void)handleIncomingMessage:(XMPPMessage *)message room:(XMPPRoom *)room
{
    /*XMPPLogTrace();
    AssertParentQueue();
    
    XMPPJID *myRoomJID = room.myRoomJID;
    XMPPJID *messageJID = [message from];
    
    if ([myRoomJID isEqualToJID:messageJID])
    {
        if (![message wasDelayed])
        {
            // Ignore - we already stored message in handleOutgoingMessage:room:
            return;
        }
    }
    
    if ([self existsMessage:message])
    {
        XMPPLogVerbose(@"%@: %@ - Duplicate message", THIS_FILE, THIS_METHOD);
    }
    else
    {
        XMPPRoomMessageMemoryStorageObject *roomMessage = [[self.messageClass alloc] initWithIncomingMessage:message];
        [self addMessage:roomMessage];
    }*/
}

- (void)handleDidLeaveRoom:(XMPPRoom *)room
{
    /*XMPPLogTrace();
    AssertParentQueue();
    
    [occupantsDict removeAllObjects];
    [occupantsArray removeAllObjects];*/
}

@end
