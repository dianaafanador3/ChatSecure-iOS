//
//  OTRFileItem.m
//  ChatSecure
//
//  Created by Diana Perez on 6/22/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRFileItem.h"
#import "OTRImages.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"
#import "YapDatabaseRelationshipTransaction.h"
#import "OTRDatabaseManager.h"
#import "OTRMessage.h"
#import "UIImage+JSQMessages.h"
#import "PureLayout.h"
#import "OTRMediaServer.h"

@import AVFoundation;

@implementation OTRFileItem

- (NSURL *)mediaURL
{
    __block NSString *buddyUniqueId = nil;
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        OTRMessage *message = [self parentMessageInTransaction:transaction];
        buddyUniqueId = message.chatterUniqueId;
    }];
    
    return [[OTRMediaServer sharedInstance] urlForMediaItem:self chatterUniqueId:buddyUniqueId];
}



+ (instancetype)fileItemWithFileURL:(NSURL *)url
{
    
    OTRFileItem *videoItem = [[OTRFileItem alloc] init];
    videoItem.filename = url.lastPathComponent;
    
    return videoItem;
}

+ (NSString *)collection
{
    return [OTRMediaItem collection];
}


@end
