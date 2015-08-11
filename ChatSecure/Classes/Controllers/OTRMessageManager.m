//
//  OTRMessageManager.m
//  ChatSecure
//
//  Created by Diana Perez on 6/29/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRMessageManager.h"

#import "OTRAppDelegate.h"
#import "OTRMessage.h"
#import "OTRChatter.h"
#import "OTRMessagesHoldTalkViewController.h"
#import "OTRDatabaseManager.h"
#import "UIViewController+ChatSecure.h"
#import "OTRWebScreenshot.h"
#import "OTRImageItem.h"

@interface OTRMessageManager ()

@property (nonatomic) dispatch_queue_t internalQueue;

@end


@implementation OTRMessageManager

- (id) init {
    if (self = [super init]) {
        self.internalQueue = dispatch_queue_create("OTRMessageManager Internal Queue", 0);
    }
    return self;
}


+ (instancetype) sharedInstance {
    static OTRMessageManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OTRMessageManager alloc] init];
    });
    return _sharedInstance;
}


- (void)decodeMessage:(NSString*)message
             username:(NSString*)username
          accountName:(NSString*)accountName
             protocol:(NSString*)protocol
         mediaMessage:(BOOL)mediaMessage
                  tag:(id)tag
{
    NSParameterAssert(message.length);
    NSParameterAssert(username.length);
    NSParameterAssert(accountName.length);
    NSParameterAssert(protocol.length);
    if (![message length] || ![username length] || ![accountName length] || ![protocol length]) {
        return;
    }
    dispatch_async(self.internalQueue, ^{
        
        OTRMessage *originalMessage = nil;
        if ([tag isKindOfClass:[OTRMessage class]]) {
            originalMessage = [tag copy];
        }
        
        NSParameterAssert(originalMessage);
        
        if ([message length]) {
            if ([[OTRAppDelegate appDelegate].messagesViewController otr_isVisible] && [[OTRAppDelegate appDelegate].messagesViewController.chatter.uniqueId isEqualToString:originalMessage.chatterUniqueId])
            {
                originalMessage.read = YES;
            }
            
            originalMessage.transportedSecurely = NO;
            
            if(mediaMessage)
            {

                UIImage *image = [UIImage imageNamed:@"OTRAttachmentIcon"];
                
                NSString *UUID = [[NSUUID UUID] UUIDString];
                
                NSData *imageData = UIImagePNGRepresentation(image);
                
                __block OTRImageItem *imageItem  = [[OTRImageItem alloc] init];
                imageItem.width = image.size.width;
                imageItem.height = image.size.height;
                imageItem.isIncoming = YES;
                imageItem.filename = [UUID stringByAppendingPathExtension:@"jpg"];
                
                originalMessage.mediaItemUniqueId = imageItem.uniqueId;
                
                [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                    [imageItem saveWithTransaction:transaction];
                } completionBlock:^{
                    [[OTRMediaFileManager sharedInstance] setData:imageData forItem:imageItem chatterUniqueId:originalMessage.chatterUniqueId completion:^(NSInteger bytesWritten, NSError *error) {
                        [imageItem touchParentMessage];
                        if (error) {
                            originalMessage.error = error;
                        }
                       
                    } completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
                }];
         
            
            }
                
            [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                [originalMessage saveWithTransaction:transaction];
                //Update lastMessageDate for sorting and grouping
                OTRChatter *chatter = [OTRChatter fetchObjectWithUniqueID:originalMessage.chatterUniqueId transaction:transaction];
                chatter.lastMessageDate = originalMessage.date;
                [chatter saveWithTransaction:transaction];
            } completionBlock:^{
                [OTRMessage showLocalNotificationForMessage:originalMessage];
            }];
        }

    });
}

@end
