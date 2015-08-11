//
//  WEServiceUploadConnectionManager.m
//  WECatalog
//
//  Created by Diana Perez on 3/11/15.
//  Copyright (c) 2015 Diana Perez. All rights reserved.
//

#import "OTRUploadConnectionManager.h"

#import "PKMultipartInputStream.h"

#import "RequestQueue.h"

#import "OTRMessage.h"
#import "OTRChatter.h"
#import "OTRAccount.h"

#import "OTRDatabaseManager.h"

#import "OTRDataRequest.h"
#import "OTRDataOutgoingTransfer.h"

@implementation OTRUploadConnectionManager

static OTRUploadConnectionManager *sharedInstance = nil;

// Get the shared instance and create it if necessary.
+ (OTRUploadConnectionManager *) sharedServiceController {
    if (sharedInstance == nil) {
        sharedInstance = [[super alloc] init];
    }
    
    return sharedInstance;
}


- (void) uploadChatFileWithURL:(NSURL *)url transfer:(OTRDataOutgoingTransfer *)transfer andDelegate:(id)delegate;
{
    //add our image to the path
    
    PKMultipartInputStream *body = [[PKMultipartInputStream alloc] init];
    [body addPartWithName:@"file" filename:transfer.fileName data:transfer.fileData contentType:transfer.mimeType];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", [body boundary]] forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[body length]] forHTTPHeaderField:@"Content-Length"];
    [request setValue:transfer.username forHTTPHeaderField:@"to"];
    [request setValue:transfer.accountName forHTTPHeaderField:@"from"];
    [request setValue:transfer.transferId forHTTPHeaderField:@"TransferId"];
    [request setHTTPBodyStream:body];
    [request setHTTPMethod:@"POST"];
    
    RQOperation *operation = [RQOperation operationWithRequest:request];
    
    operation.completionHandler = ^(NSString *transferId, __unused NSURLResponse *response, NSData *data, NSError *error) {
        
        if (!error)
        {
            [delegate uploadFinishedWithData:data andTransferId:transferId];
        }
        else
        {
            [delegate uploadFailedWithError:error andTransferId:transferId];
        }
    };
    
    //progress handler
    operation.uploadProgressHandler = ^(NSString *transferId, float progress, __unused NSInteger bytesTransferred, __unused NSInteger totalBytes) {
        
        //update progress
        [delegate updateProgress:progress withId:transferId];
        
    };
    
    //add operation to queue
    [[RequestQueue mainQueue] addOperation:operation];
}


@end
