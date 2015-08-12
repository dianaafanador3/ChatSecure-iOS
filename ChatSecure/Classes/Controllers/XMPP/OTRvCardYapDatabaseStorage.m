//
//  OTRvCardYapDatabaseStorage.m
//  Off the Record
//
//  Created by David Chiles on 4/2/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRvCardYapDatabaseStorage.h"
#import "OTRDatabaseManager.h"
#import "OTRXMPPAccount.h"
#import "XMPPJID.h"
#import "OTRChatter.h"
#import "OTRXMPPChatter.h"
#import "XMPPvCardTemp.h"

@interface OTRvCardYapDatabaseStorage ()

@property (nonatomic, strong) dispatch_queue_t storageQueue;
@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;


@end

@implementation OTRvCardYapDatabaseStorage

- (id)init
{
    if (self = [super init]) {
        self.storageQueue = dispatch_queue_create("OTR.OTRvCardYapDatabaseStorage", NULL);
        self.databaseConnection = [[OTRDatabaseManager sharedInstance] newConnection];
    }
    return self;
}

- (OTRXMPPChatter *)chatterWithJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream transaction:(YapDatabaseReadTransaction *)transaction
{
    OTRXMPPAccount *account = [OTRXMPPAccount accountForStream:stream transaction:transaction];
    return [OTRXMPPChatter fetchChatterWithUsername:[jid bare] withAccountUniqueId:account.uniqueId transaction:transaction];
}


- (OTRXMPPChatter *)chatterWithJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream;
{
    __block OTRXMPPChatter *chatter = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        chatter = [self chatterWithJID:jid xmppStream:stream transaction:transaction];
    }];
    return chatter;
}

#pragma - mark XMPPvCardAvatarStorage Methods

- (NSData *)photoDataForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    return [self chatterWithJID:jid xmppStream:stream].avatarData;
    
}

- (NSString *)photoHashForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    return [self chatterWithJID:jid xmppStream:stream].photoHash;
}

/**
 * Clears the vCardTemp from the store.
 * This is used so we can clear any cached vCardTemp's for the JID.
 **/
- (void)clearvCardTempForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        OTRXMPPChatter *chatter = [[self chatterWithJID:jid xmppStream:stream transaction:transaction] copy];
        chatter.vCardTemp = nil;
        
        [transaction setObject:chatter forKey:chatter.uniqueId inCollection:[OTRXMPPChatter collection]];
    }];
}

#pragma - mark XMPPvCardTempModuleStorage Methods

/**
 * Configures the storage class, passing its parent and parent's dispatch queue.
 *
 * This method is called by the init methods of the XMPPvCardTempModule class.
 * This method is designed to inform the storage class of its parent
 * and of the dispatch queue the parent will be operating on.
 *
 * The storage class may choose to operate on the same queue as its parent,
 * or it may operate on its own internal dispatch queue.
 *
 * This method should return YES if it was configured properly.
 * The parent class is configured to ignore the passed
 * storage class in its init method if this method returns NO.
 **/
- (BOOL)configureWithParent:(XMPPvCardTempModule *)aParent queue:(dispatch_queue_t)queue
{
    return YES;
}

/**
 * Returns a vCardTemp object or nil
 **/
- (XMPPvCardTemp *)vCardTempForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    OTRXMPPChatter *chatter = [self chatterWithJID:jid xmppStream:stream];
    return chatter.vCardTemp;
}

/**
 * Used to set the vCardTemp object when we get it from the XMPP server.
 **/
- (void)setvCardTemp:(XMPPvCardTemp *)vCardTemp forJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        OTRXMPPChatter *chatter = [[self chatterWithJID:jid xmppStream:stream transaction:transaction] copy];
        
        if ([stream.myJID isEqualToJID:jid options:XMPPJIDCompareBare]) {
            //this is the self buddy
            OTRXMPPAccount *account = [[OTRXMPPAccount accountForStream:stream transaction:transaction] copy];
            account.avatarData = vCardTemp.photo;
            [account saveWithTransaction:transaction];
        }
        
        chatter.vCardTemp = vCardTemp;
        chatter.waitingForvCardTempFetch = NO;
        chatter.lastUpdatedvCardTemp = [NSDate date];
        
        [chatter saveWithTransaction:transaction];
    }];
    
}

/**
 * Returns My vCardTemp object or nil
 **/
- (XMPPvCardTemp *)myvCardTempForXMPPStream:(XMPPStream *)stream
{
    if (!stream) {
        return nil;
    }
    
    return [self chatterWithJID:stream.myJID xmppStream:stream].vCardTemp;
}

/**
 * Asks the backend if we should fetch the vCardTemp from the network.
 * This is used so that we don't request the vCardTemp multiple times.
 **/
- (BOOL)shouldFetchvCardTempForJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream
{
    
    if (![stream isAuthenticated]) {
        return NO;
    }
    __block BOOL result = NO;
    
    [self.databaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        
        OTRXMPPChatter * chatter = [[self chatterWithJID:jid xmppStream:stream transaction:transaction] copy];
        if (!chatter.isWaitingForvCardTempFetch) {
            
            chatter.waitingForvCardTempFetch = YES;
            chatter.lastUpdatedvCardTemp = [NSDate date];
            
            result = YES;
        }
        else if ([chatter.lastUpdatedvCardTemp timeIntervalSinceNow] <= -10) {
            
            chatter.lastUpdatedvCardTemp = [NSDate date];
            
            result = YES;
        }
        
        
        if (result) {
            [chatter saveWithTransaction:transaction];
        }
    }];
    
    return result;
}

@end
