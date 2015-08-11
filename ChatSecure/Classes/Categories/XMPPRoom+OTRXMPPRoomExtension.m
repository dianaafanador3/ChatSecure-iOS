//
//  OTRXMPPRoomExtension.m
//  ChatSecure
//
//  Created by Diana Perez on 2/18/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "XMPPRoom+OTRXMPPRoomExtension.h"
#import "XMPP.h"

#import "OTRXMPPAccount.h"

@implementation XMPPRoom (OTRXMPPRoomExtension)

- (void) grantMemberAccess:(XMPPJID *)jid WithAccount:(OTRXMPPAccount *)account
{
    
    
    //<iq from='crone1@shakespeare.lit/desktop'
    //  id='member1'
    //  to='coven@chat.shakespeare.lit'
    //  type='set'>
    //  <query xmlns='http://jabber.org/protocol/muc#admin'>
    //      <item affiliation='member'
    //          jid='hag66@shakespeare.lit'
    //          nick='thirdwitch'/>
    //  </query>
    //</iq>
    
    
    NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
    [item addAttributeWithName:@"affiliation" stringValue:@"member"];
    [item addAttributeWithName:@"jid" stringValue:[jid full]];
    
    
    
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPMUCAdminNamespace];
    [query addChild:item];
    
    XMPPIQ *iq = [XMPPIQ iq];
    [iq addAttributeWithName:@"to" stringValue:[roomJID full]];
    [iq addAttributeWithName:@"from" stringValue:[[XMPPJID jidWithString:account.username resource:account.resource] full]];
    [iq addAttributeWithName:@"type" stringValue:@"set"];
    [iq addChild:query];
    
    [xmppStream sendElement:iq];
    
    
}

- (void)discoverRoomMembersWithAccount:(OTRXMPPAccount *)account
{
    
    
    // <iq from='hag66@shakespeare.lit/pda'
    //      id='gp7w61v3'
    //      to='conference.shakespeare.lit'
    //      type='get'>
    //  <query xmlns='http://jabber.org/protocol/muc#user'
    //      <item affiliation='member'/>
    //     />
    //  </iq>
    
    NSXMLElement *item = [NSXMLElement elementWithName:@"item"];
    [item addAttributeWithName:@"affiliation" stringValue:@"member"];
    
    NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:XMPPMUCAdminNamespace];
    [query addChild:item];
    
    XMPPIQ *iq = [XMPPIQ iq];
    [iq addAttributeWithName:@"to" stringValue:[roomJID bare]];
    [iq addAttributeWithName:@"from" stringValue:[[XMPPJID jidWithString:account.username resource:account.resource] bare]];
    [iq addAttributeWithName:@"type" stringValue:@"get"];
    [iq addChild:query];
    
    
    
    [xmppStream sendElement:iq];
}

@end
