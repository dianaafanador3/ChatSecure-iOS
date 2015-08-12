//
//  OTRMessagesViewController.h
//  Off the Record
//
//  Created by David Chiles on 5/12/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "JSQMessagesViewController.h"
#import "OTRKit.h"

@class OTRChatter, OTRXMPPManager, OTRAccount, YapDatabaseViewMappings, YapDatabaseConnection, OTRMessage;

@protocol OTRMessagesViewControllerProtocol <NSObject>

- (void)receivedTextViewChangedNotification:(NSNotification *)notification;
- (void)setupAccessoryButtons:(BOOL)enabled;

@end

@interface OTRMessagesViewController : JSQMessagesViewController <UISplitViewControllerDelegate, OTRMessagesViewControllerProtocol, UIPopoverPresentationControllerDelegate>

@property (nonatomic, strong) OTRAccount *account;
@property (nonatomic, strong) OTRChatter *chatter;
@property (nonatomic, weak, readonly) OTRXMPPManager *xmppManager;

@property (nonatomic, strong) UIButton *microphoneButton;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIButton *cameraButton;

@property (nonatomic, strong) YapDatabaseViewMappings *messageMappings;

@property (nonatomic, strong) YapDatabaseConnection *uiDatabaseConnection;

- (void)setSender:(OTRChatter *)chatter;

- (OTRMessage *)messageAtIndexPath:(NSIndexPath *)indexPath;

- (void)sendAudioFileURL:(NSURL *)url;

- (void)showDropdownWithTitle:(NSString *)title buttons:(NSArray *)buttons animated:(BOOL)animated tag:(NSInteger)tag;

- (void)hideDropdownAnimated:(BOOL)animated completion:(void (^)(void))completion;


@end
