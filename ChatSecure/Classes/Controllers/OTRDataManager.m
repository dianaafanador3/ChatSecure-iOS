//
//  OTRDataManager.m
//  ChatSecure
//
//  Created by Diana Perez on 6/18/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRDataManager.h"

#import "OTRHTTPMessage.h"
#import "OTRDataTransfer.h"
#import "OTRDataIncomingTransfer.h"
#import "OTRDataOutgoingTransfer.h"
#import "OTRTLV.h"
#import "OTRKit.h"
#import "NSData+OTRDATA.h"
#import "OTRDataRequest.h"
#import <MobileCoreServices/MobileCoreServices.h>

#import "OTRLog.h"

#import "OTRDatabaseManager.h"
#import "OTRMessage.h"
#import "OTRMediaItem.h"


static NSString * const kotrHTTPHeaderRange = @"Range";
static NSString * const kotrHTTPHeaderRequestID = @"Request-Id";
static NSString * const kotrHTTPHeaderFileLength = @"File-Length";
static NSString * const kotrHTTPHeaderFileHashSHA1 = @"File-Hash-SHA1";
static NSString * const kotrHTTPHeaderMimeType = @"Mime-Type";
static NSString * const kotrHTTPHeaderFileName = @"File-Name";

static const NSUInteger kotrOTRDataMaxChunkLength = 16384;
static const NSUInteger kotrOTRDataMaxFileSize = 1024*1024*64;
static const NSUInteger kotrOTRDataMaxOutstandingRequests = 3;

NSString* OTRGetMimeTypeForExtension(NSString* extension) {
    NSString* mimeType = @"application/octet-stream";
    extension = [extension lowercaseString];
    if (extension.length) {
        CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
        if (uti) {
            mimeType = CFBridgingRelease(UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType));
            CFRelease(uti);
        }
    }
    return mimeType;
}

@interface OTRDataManager ()

@property (nonatomic) dispatch_queue_t internalQueue;

/**
 *  OTRDataIncomingTransfer keyed to URL
 */
@property (nonatomic, strong, readonly) NSMutableDictionary *incomingTransfers;

/**
 *  OTRDataOutgoingTransfer keyed to URL
 */
@property (nonatomic, strong, readonly) NSMutableDictionary *outgoingTransfers;

/** OTRDataRequest keyed to Request-Id  */
@property (nonatomic, strong, readonly) NSMutableDictionary *requestCache;

@end

@implementation OTRDataManager


- (id) init{
    if (self = [super init]) {
        _internalQueue = dispatch_queue_create("OTRDATA Queue", 0);
        _delegate = self;
        _callbackQueue = dispatch_get_main_queue();
        _incomingTransfers = [[NSMutableDictionary alloc] init];
        _outgoingTransfers = [[NSMutableDictionary alloc] init];
        _requestCache = [[NSMutableDictionary alloc] init];
    }
    return self;
}


/** For now, this won't work for large files because of RAM limitations */
- (void) sendFileWithURL:(NSURL*)fileURL
                username:(NSString*)username
             accountName:(NSString*)accountName
                protocol:(NSString*)protocol
                     tag:(id)tag {
    NSString *fileName = [[fileURL path] lastPathComponent];
    NSData *fileData = [NSData dataWithContentsOfURL:fileURL];
    [self sendFileWithName:fileName fileData:fileData username:username accountName:accountName protocol:protocol tag:tag];
}

/** For now, this won't work for large files because of RAM limitations */
- (void) sendFileWithName:(NSString*)fileName
                 fileData:(NSData*)fileData
                 username:(NSString*)username
              accountName:(NSString*)accountName
                 protocol:(NSString*)protocol
                      tag:(id)tag {
    dispatch_async(self.internalQueue, ^{
        NSUInteger fileLength = fileData.length;
        
        if (fileLength > kotrOTRDataMaxFileSize) {
            dispatch_async(self.callbackQueue, ^{
                //[self.delegate dataHandler:self errorSendingFile:fileName error:[NSError errorWithDomain:kOTRDataErrorDomain code:101 userInfo:@{NSLocalizedDescriptionKey: @"File too large"}] tag:tag];
            });
            return;
        }
        
        NSString *requestID = [[NSUUID UUID] UUIDString];
        
        NSData *fileHash = [fileData otr_SHA1];
        NSString *fileHashString = [fileHash otr_hexString];
        NSString *fileExtension = [fileName pathExtension];
        NSString *mimeType = OTRGetMimeTypeForExtension(fileExtension);
        
        NSDictionary *httpHeaders = @{kotrHTTPHeaderFileLength: @(fileLength).stringValue,
                                      kotrHTTPHeaderFileHashSHA1: fileHashString,
                                      kotrHTTPHeaderFileName: fileName,
                                      kotrHTTPHeaderRequestID: requestID,
                                      kotrHTTPHeaderMimeType: mimeType};
        
        OTRDataOutgoingTransfer *transfer = [[OTRDataOutgoingTransfer alloc] initWithFileLength:fileLength username:username accountName:accountName protocol:protocol tag:tag];
        transfer.fileData = fileData;
        transfer.fileName = fileName;
        transfer.fileHash = fileHashString;
        transfer.mimeType = mimeType;
        
        NSURL *url = [self urlForTransfer];
        
        [self.outgoingTransfers setObject:transfer forKey:transfer.transferId];
        
        OTRDataRequest *request = [[OTRDataRequest alloc] initWithRequestId:requestID url:url httpMethod:@"OFFER" httpHeaders:httpHeaders];
        [self.requestCache setObject:request forKey:requestID];
        [self sendRequest:request transfer:transfer tag:tag];
    });
}

- (void) sendRequest:(OTRDataRequest*)request
            transfer:(OTRDataOutgoingTransfer*)transfer
                 tag:(id)tag {
    NSString *httpMethod = request.httpMethod;
    NSURL *url = request.url;
    NSDictionary *httpHeaders = request.httpHeaders;
    OTRHTTPMessage *message = [[OTRHTTPMessage alloc] initRequestWithMethod:httpMethod url:url version:OTRHTTPVersion1_1];
    [httpHeaders enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [message setValue:obj forHTTPHeaderField:key];
    }];
    
    [[OTRUploadConnectionManager sharedServiceController] uploadChatFileWithURL:request.url transfer:transfer andDelegate:self];
    
    /*NSData *httpData = [message HTTPMessageData];
    OTRTLV *tlv = [[OTRTLV alloc] initWithType:OTRTLVTypeDataRequest data:httpData];
    if (!tlv) {
        return;
    }*/
    //[self.otrKit encodeMessage:nil tlvs:@[tlv] username:username accountName:accountName protocol:protocol tag:tag];
}


- (NSURL*)urlForTransfer {
    NSString *urlString = @"http://10.14.4.151:9090/plugins/restservice/restservice/status/";
    NSURL *url = [NSURL URLWithString:urlString];
    return url;
}



#pragma mark OTRUploadServiceDelegate methods


- (void) uploadFailedWithError:(NSError *)error andTransferId:(NSString *)transferId
{
 
    OTRDataOutgoingTransfer *transfer = [self.outgoingTransfers objectForKey:transferId];
    
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        OTRMessage *tagMessage = transfer.tag;
        OTRMessage *databaseMessage = [OTRMessage fetchObjectWithUniqueID:tagMessage.uniqueId transaction:transaction];
        databaseMessage.error = error;
        OTRMediaItem *mediaItem = [OTRMediaItem fetchObjectWithUniqueID:databaseMessage.mediaItemUniqueId transaction:transaction];
        mediaItem.transferProgress = 0;
        [mediaItem saveWithTransaction:transaction];
        [mediaItem touchParentMessageWithTransaction:transaction];
    }];
}


- (void) uploadFinishedWithData:(NSData *)data andTransferId:(NSString *)transferId
{
    OTRDataOutgoingTransfer *transfer = [self.outgoingTransfers objectForKey:transferId];
    
    DDLogInfo(@"transfer complete: %@", transferId);
    if ([transfer isKindOfClass:[OTRDataOutgoingTransfer class]]) {
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            OTRMessage *tagMessage = transfer.tag;
            OTRMessage *message = [OTRMessage fetchObjectWithUniqueID:tagMessage.uniqueId transaction:transaction];
            message.delivered = YES;
            OTRMediaItem *mediaItem = [OTRMediaItem fetchObjectWithUniqueID:message.mediaItemUniqueId transaction:transaction];
            mediaItem.transferProgress = 1;
            [mediaItem saveWithTransaction:transaction];
            [message saveWithTransaction:transaction];
        }];
    }
}



- (void) updateProgress:(float)progress withId:(NSString *)transferId
{
    DDLogInfo(@"[OTRDATA]file transferId %@ progress: %f", transferId, progress);
    
    OTRDataOutgoingTransfer *transfer = [self.outgoingTransfers objectForKey:transferId];
    
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        OTRMessage *tagMessage = transfer.tag;
        OTRMessage *databaseMessage = [OTRMessage fetchObjectWithUniqueID:tagMessage.uniqueId transaction:transaction];
        OTRMediaItem *mediaItem = [OTRMediaItem fetchObjectWithUniqueID:databaseMessage.mediaItemUniqueId transaction:transaction];
        mediaItem.transferProgress = progress;
        [mediaItem saveWithTransaction:transaction];
        [mediaItem touchParentMessageWithTransaction:transaction];
    }];}

@end
