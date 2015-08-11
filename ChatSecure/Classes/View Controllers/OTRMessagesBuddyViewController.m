//
//  OTRMessagesBuddyViewController.m
//  ChatSecure
//
//  Created by Diana Perez on 3/30/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRMessagesBuddyViewController.h"

#import "OTRAccount.h"
#import "OTRBuddy.h"
#import "OTRXMPPTorAccount.h"
#import "OTRMessage.h"
#import "JSQMessages.h"
#import "OTRColors.h"
#import "OTRImages.h"

#import "OTRButtonView.h"

#import "UIAlertView+Blocks.h"

#import "OTRDatabaseManager.h"
#import "OTRDatabaseView.h"
#import "OTRProtocolManager.h"
#import "OTRKit.h"

//#import "OTRFileTransferController.h"
//#import "OTRFileTransferUtil.h"

#import "Strings.h"

typedef NS_ENUM(int, OTRDropDownType) {
    OTRDropDownTypeNone          = 0,
    OTRDropDownTypeEncryption    = 1,
    OTRDropDownTypePush          = 2
};

@interface OTRMessagesBuddyViewController ()



@property (nonatomic, strong) YapDatabaseViewMappings *buddyMappings;

@property (nonatomic, weak) id textViewNotificationObject;
@property (nonatomic, weak) id databaseConnectionDidUpdateNotificationObject;
@property (nonatomic, weak) id didFinishGeneratingPrivateKeyNotificationObject;
@property (nonatomic, weak) id messageStateDidChangeNotificationObject;

@property (nonatomic ,strong) UIBarButtonItem *lockBarButtonItem;
@property (nonatomic, strong) OTRButtonView *buttonDropdownView;

@end

@implementation OTRMessagesBuddyViewController

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //self.delegate = self;

    
    ///// Avatar Visibility /////////
    //self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    //self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;

    
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //[self updateEncryptionState];
    
}



- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}



/*
-(void)updateEncryptionState
{
    if (!self.account) {
        return;
    }
    [[OTRKit sharedInstance] checkIfGeneratingKeyForAccountName:self.account.username protocol:self.account.protocolTypeString completion:^(BOOL isGeneratingKey) {
        if( isGeneratingKey) {
            [self addLockSpinner];
        }
        else {
            UIBarButtonItem * rightBarItem = self.navigationItem.rightBarButtonItem;
            if ([rightBarItem isEqual:self.lockBarButtonItem]) {
                
                
                [[OTRKit sharedInstance] activeFingerprintIsVerifiedForUsername:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString completion:^(BOOL isTrusted) {
                    
                    [[OTRKit sharedInstance] hasVerifiedFingerprintsForUsername:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString completion:^(BOOL hasVerifiedFingerprints) {
                        
                        [[OTRKit sharedInstance] messageStateForUsername:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString completion:^(OTRKitMessageState messageState) {
                            
                            //Set correct lock icon and status
                            if (messageState == OTRKitMessageStateEncrypted && isTrusted) {
                                self.lockButton.lockStatus = OTRLockStatusLockedAndVerified;
                            }
                            else if (messageState == OTRKitMessageStateEncrypted && hasVerifiedFingerprints)
                            {
                                self.lockButton.lockStatus = OTRLockStatusLockedAndError;
                            }
                            else if (messageState == OTRKitMessageStateEncrypted) {
                                self.lockButton.lockStatus = OTRLockStatusLockedAndWarn;
                            }
                            else {
                                self.lockButton.lockStatus = OTRLockStatusUnlocked;
                            }
                            
                            [self setupAccessoryButtons:TRUE];
                        }];
                    }];
                }];
            }
        }
    }];
}

-(void)addLockSpinner {
    UIActivityIndicatorView * activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
    activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [activityIndicatorView sizeToFit];
    [activityIndicatorView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin)];
    UIBarButtonItem * activityBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicatorView];
    [activityIndicatorView startAnimating];
    self.navigationItem.rightBarButtonItem = activityBarButtonItem;
}
-(void)removeLockSpinner {
    self.navigationItem.rightBarButtonItem = self.lockBarButtonItem;
    [self updateEncryptionState];
}

- (void)encryptionButtonPressed:(id)sender
{
    [self hideDropdownAnimated:YES completion:nil];
    
    
    [[OTRKit sharedInstance] messageStateForUsername:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString completion:^(OTRKitMessageState messageState) {
        
        if (messageState == OTRKitMessageStateEncrypted) {
            [[OTRKit sharedInstance] disableEncryptionWithUsername:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString];
        }
        else {
            [[OTRKit sharedInstance] initiateEncryptionWithUsername:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString];
        }
        
        
    }];
}

- (void)verifyButtonPressed:(id)sender
{
    [self hideDropdownAnimated:YES completion:nil];
    
    [[OTRKit sharedInstance] fingerprintForAccountName:self.account.username protocol:self.account.protocolTypeString completion:^(NSString *ourFingerprintString) {
        
        [[OTRKit sharedInstance] activeFingerprintForUsername:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString completion:^(NSString *theirFingerprintString) {
            
            [[OTRKit sharedInstance] activeFingerprintIsVerifiedForUsername:self.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString completion:^(BOOL verified) {
                
                
                UIAlertView * alert;
                __weak OTRMessagesBuddyViewController * welf = self;
                
                RIButtonItem * verifiedButtonItem = [RIButtonItem itemWithLabel:VERIFIED_STRING action:^{
                    [[OTRKit sharedInstance] setActiveFingerprintVerificationForUsername:welf.buddy.username accountName:welf.account.username protocol:self.account.protocolTypeString verified:YES completion:^{
                        [welf updateEncryptionState];
                    }];
                }];
                
                RIButtonItem * notVerifiedButtonItem = [RIButtonItem itemWithLabel:NOT_VERIFIED_STRING action:^{
                    
                    [[OTRKit sharedInstance] setActiveFingerprintVerificationForUsername:welf.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString verified:NO completion:^{
                        [welf updateEncryptionState];
                    }];
                }];
                
                RIButtonItem * verifyLaterButtonItem = [RIButtonItem itemWithLabel:VERIFY_LATER_STRING action:^{
                    [[OTRKit sharedInstance] setActiveFingerprintVerificationForUsername:welf.buddy.username accountName:self.account.username protocol:self.account.protocolTypeString verified:NO completion:^{
                        [welf updateEncryptionState];
                    }];
                }];
                
                if(ourFingerprintString && theirFingerprintString) {
                    NSString *msg = [NSString stringWithFormat:@"%@, %@:\n%@\n\n%@ %@:\n%@\n", YOUR_FINGERPRINT_STRING, self.account.username, ourFingerprintString, THEIR_FINGERPRINT_STRING, self.buddy.username, theirFingerprintString];
                    if(verified)
                    {
                        alert = [[UIAlertView alloc] initWithTitle:VERIFY_FINGERPRINT_STRING message:msg cancelButtonItem:verifiedButtonItem otherButtonItems:notVerifiedButtonItem, nil];
                    }
                    else
                    {
                        alert = [[UIAlertView alloc] initWithTitle:VERIFY_FINGERPRINT_STRING message:msg cancelButtonItem:verifyLaterButtonItem otherButtonItems:verifiedButtonItem, nil];
                    }
                } else {
                    NSString *msg = SECURE_CONVERSATION_STRING;
                    alert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
                }
                
                [alert show];
            }];
        }];
    }];
}*/


- (void)setBuddy:(OTRBuddy *)buddy
{
    [super setSender:buddy];
    //Update chatstate if it changed
    OTRBuddy*originalBuddy = self.buddy;
    
    if ([originalBuddy.uniqueId isEqualToString:buddy.uniqueId]) {
        _buddy = buddy;
        
        if (originalBuddy.chatState != self.buddy.chatState) {
            if (buddy.chatState == kOTRChatStateComposing || buddy.chatState == kOTRChatStatePaused) {
                self.showTypingIndicator = YES;
            }
            else {
                self.showTypingIndicator = NO;
            }
        }
        
        //Update title view if the status or username or display name have changed
        if (originalBuddy.status != self.buddy.status || ![originalBuddy.username isEqualToString:self.buddy.username] || ![originalBuddy.displayName isEqualToString:self.buddy.displayName]) {
        }
        
    }
    else
    {
        //different buddy
        _buddy = buddy;
        
        if (self.buddy) {
            NSParameterAssert(self.buddy.uniqueId != nil);
            self.buddyMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[self.buddy.uniqueId] view:OTRAllBuddiesDatabaseViewExtensionName];
        
            [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                [self.buddyMappings updateWithTransaction:transaction];
            }];
        } else {
            
            self.buddyMappings = nil;
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
        message.chatterUniqueId = self.buddy.uniqueId;
        message.text = text;
        message.read = YES;
        message.transportedSecurely = NO;
        
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            self.buddy.lastMessageDate = message.date;
            [self.buddy saveWithTransaction:transaction];
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
