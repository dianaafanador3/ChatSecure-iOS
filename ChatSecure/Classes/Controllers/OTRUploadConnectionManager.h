//
//  WEServiceUploadConnectionManager.h
//  WECatalog
//
//  Created by Diana Perez on 3/11/15.
//  Copyright (c) 2015 Diana Perez. All rights reserved.
//

#import <Foundation/Foundation.h>

#define UPLOADFILE @"uploadFile"

@class OTRMessage, OTRAccount, OTRDataOutgoingTransfer;

@interface OTRUploadConnectionManager : NSObject <NSURLConnectionDelegate>

+ (OTRUploadConnectionManager *) sharedServiceController;

- (void) uploadChatFileWithURL:(NSURL *)url transfer:(OTRDataOutgoingTransfer *)transfer andDelegate:(id)delegate;

@end

@protocol OTRUploadConnectionManagerDelegate <NSObject>

- (void) uploadFailedWithError:(NSError *)message andTransferId:(NSString *)transferId;
- (void) uploadFinishedWithData:(NSData *)data andTransferId:(NSString *)transferId;
- (void) updateProgress:(float)progress withId:(NSString *)transferId;



@end
