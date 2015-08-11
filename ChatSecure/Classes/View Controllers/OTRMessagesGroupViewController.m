 //
//  OTRMessagesViewController.m
//  Off the Record
//
//  Created by David Chiles on 5/12/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRMessagesGroupViewController.h"

#import "OTRAccount.h"
#import "OTRBroadcastGroup.h"
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


@interface OTRMessagesGroupViewController ()

@property (nonatomic, strong) YapDatabaseViewMappings *groupMappings;

@property (nonatomic, weak) id textViewNotificationObject;


@end

@implementation OTRMessagesGroupViewController

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



- (void)setBroadcastGroup:(OTRBroadcastGroup *)broadcastGroup
{
    [super setSender:broadcastGroup];
    OTRBroadcastGroup *originalGroup = self.broadcastGroup;
    
    if ([originalGroup.uniqueId isEqualToString:broadcastGroup.uniqueId]) {
        // really same buddy with new info like chatState, EncryptionState, Name
        _broadcastGroup = broadcastGroup;
        
    } else {
        //different buddy
        _broadcastGroup = broadcastGroup;
        if (self.broadcastGroup) {
            NSParameterAssert(self.broadcastGroup.uniqueId != nil);
            self.groupMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[self.broadcastGroup.uniqueId] view:OTRAllBroadcastListDatabaseViewExtensionName];
            
            [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                [self.groupMappings updateWithTransaction:transaction];
            }];
            
            
        } else {
            
            self.groupMappings = nil;
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
        message.chatterUniqueId = self.broadcastGroup.uniqueId;
        message.text = text;
        message.read = YES;
        message.transportedSecurely = NO;
        message.broadcastMessage = YES;
        
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [message saveWithTransaction:transaction];
        }];
        
        for (OTRBuddy *buddy in self.broadcastGroup.buddies)
        {
            OTRMessage *message2 = [[OTRMessage alloc] init];
            
            message2.chatterUniqueId = buddy.uniqueId;
            message2.text = text;
            message2.read = YES;
            message2.transportedSecurely = NO;
            message2.broadcastMessage = YES;
            
            [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                    [message2 saveWithTransaction:transaction];
                    buddy.lastMessageDate = message2.date;
                    [buddy saveWithTransaction:transaction];
            } completionBlock:^{
                [[OTRProtocolManager sharedInstance] sendMessage:message2];
            }];
        }
        
        
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
