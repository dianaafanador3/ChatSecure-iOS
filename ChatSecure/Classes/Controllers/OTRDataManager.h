//
//  OTRDataManager.h
//  ChatSecure
//
//  Created by Diana Perez on 6/18/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OTRUploadConnectionManager.h"

@protocol OTRDataManagerDelegate <NSObject>

@end


@interface OTRDataManager : NSObject <OTRDataManagerDelegate, OTRUploadConnectionManagerDelegate>

/**
 *  All OTRDataHandlerDelegate callbacks will be done on this queue.
 *  Defaults to main queue.
 */

@property (nonatomic, strong, readwrite) dispatch_queue_t callbackQueue;

/**
 *  Implement a delegate listener to handle file events.
 */
@property (nonatomic, weak, readwrite) id<OTRDataManagerDelegate> delegate;

- (id) init;

/** For now, this won't work for large files because of RAM limitations */
- (void) sendFileWithURL:(NSURL*)fileURL
                username:(NSString*)username
             accountName:(NSString*)accountName
                protocol:(NSString*)protocol
                     tag:(id)tag;

/** For now, this won't work for large files because of RAM limitations */
- (void) sendFileWithName:(NSString*)fileName
                 fileData:(NSData*)fileData
                 username:(NSString*)username
              accountName:(NSString*)accountName
                 protocol:(NSString*)protocol
                      tag:(id)tag;


@end


