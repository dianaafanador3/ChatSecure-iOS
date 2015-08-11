//
//  OTRWebScreenshot.h
//  ChatSecure
//
//  Created by Diana Perez on 6/29/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "FISWebViewPreloader.h"

@class FISWebViewPreloader;

@interface OTRWebScreenshot : NSObject <UIWebViewDelegate>

typedef void (^completionBlock)(UIImageView *image);

@property (nonatomic, copy) completionBlock completionHandler;

@property (nonatomic, strong) FISWebViewPreloader *preLoader;

+ (void)takeSnapshotOfWebPageAtURL:(NSString *)url completionBlock:(void (^)(UIImageView *))block;

@end