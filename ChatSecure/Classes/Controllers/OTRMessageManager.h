//
//  OTRMessageManager.h
//  ChatSecure
//
//  Created by Diana Perez on 6/29/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OTRMessageManager : NSObject

+ (instancetype) sharedInstance;


- (void)decodeMessage:(NSString*)message
             username:(NSString*)username
          accountName:(NSString*)accountName
             protocol:(NSString*)protocol
         mediaMessage:(BOOL)mediaMessage
                  tag:(id)tag;

@end
