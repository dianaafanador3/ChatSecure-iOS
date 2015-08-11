//
//  OTRXMPPRoomExtension.h
//  ChatSecure
//
//  Created by Diana Perez on 2/18/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPPRoom.h"
#import "OTRXMPPAccount.h"

@interface XMPPRoom (OTRXMPPRoomExtension)

- (void) grantMemberAccess:(XMPPJID *)jid WithAccount:(OTRXMPPAccount *)account;

- (void) discoverRoomMembersWithAccount:(OTRXMPPAccount *)account;

@end
