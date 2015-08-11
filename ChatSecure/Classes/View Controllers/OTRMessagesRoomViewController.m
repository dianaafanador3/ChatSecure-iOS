 //
//  OTRMessagesRoomViewController.m
//  Off the Record
//
//  Created by David Chiles on 5/12/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//


#import "OTRMessagesRoomViewController.h"

#import "OTRAccount.h"
#import "OTRRoom.h"
#import "OTRXMPPTorAccount.h"
#import "OTRMessage.h"
#import "JSQMessages.h"


#import "OTRButtonView.h"

#import "UIAlertView+Blocks.h"


#import "OTRXMPPManager.h"
#import "OTRDatabaseManager.h"
#import "OTRDatabaseView.h"
#import "OTRProtocolManager.h"
#import "OTRKit.h"

//#import "OTRFileTransferController.h"
//#import "OTRFileTransferUtil.h"

#import "Strings.h"


@interface OTRMessagesRoomViewController ()

@property (nonatomic, strong) YapDatabaseViewMappings *roomMappings;

@property (nonatomic, weak) id textViewNotificationObject;

@end

@implementation OTRMessagesRoomViewController

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //self.delegate = self;
    
    ///// Avatar Visibility /////////
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;

}



- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}



- (void)setRoomGroup:(OTRRoom *)room
{
    [super setSender:room];
    OTRRoom *originalRoom = self.roomGroup;
    
    if ([originalRoom.uniqueId isEqualToString:room.uniqueId]) {
        // really same buddy with new info like chatState, EncryptionState, Name
        _roomGroup = room;
        
    } else {
        //different buddy
        _roomGroup = room;
        if (self.roomGroup) {
            NSParameterAssert(self.roomGroup.uniqueId != nil);
            self.roomMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[self.roomGroup.uniqueId] view:OTRRoomDatabaseViewExtensionName];
            
            [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                [self.roomMappings updateWithTransaction:transaction];
            }];
            
            
        } else {
            
            self.roomMappings = nil;
        }

        [self.collectionView reloadData];
    }
    
}


#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date

{
    self.navigationController.providesPresentationContextTransitionStyle = YES;
    self.navigationController.definesPresentationContext = YES;
    
    self.automaticallyScrollsToMostRecentMessage = YES;
    
    if ([[OTRProtocolManager sharedInstance] isAccountConnected:self.account]) {
        //Account is connected
        OTRMessage *message = [[OTRMessage alloc] init];
        message.chatterUniqueId = self.roomGroup.uniqueId;
        message.text = text;
        message.read = YES;
        message.transportedSecurely = NO;
        
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            self.roomGroup.lastMessageDate = message.date;
            [self.roomGroup saveWithTransaction:transaction];
            [message saveWithTransaction:transaction];
        } completionBlock:^{
            [[OTRProtocolManager sharedInstance] sendMessage:message];
        }];
        
        
    } else {
        //Account is not currently connected
        [self hideDropdownAnimated:YES completion:^{
            UIButton *okButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [okButton setTitle:CONNECT_STRING forState:UIControlStateNormal];
            [okButton addTarget:self action:@selector(connectButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            
            [self showDropdownWithTitle:YOU_ARE_NOT_CONNECTED_STRING buttons:@[okButton] animated:YES tag:0];
        }];
    }
    
    [self finishSendingMessageAnimated:YES];
}


@end

