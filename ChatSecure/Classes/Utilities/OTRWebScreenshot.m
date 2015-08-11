//
//  OTRWebScreenshot.m
//  ChatSecure
//
//  Created by Diana Perez on 6/29/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

//  MWWebSnapshot
//
//  Created by Jim McGowan on 08/09/2010.
//  Copyright 2010 Jim McGowan. All rights reserved.
//
//  This code is made available under the BSD license.
//  Please see the accompanying license.txt file
//  or view the license online at http://www.malkinware.com/developer/License.txt
//

#import "OTRWebScreenshot.h"
#import "OTRAppDelegate.h"


@interface OTRWebScreenshot()

- (id) initWithCompletionBlock:(void (^)(UIImageView *))block;
- (void) beginDownloadFromURL:(NSString *)url;

@end


@implementation OTRWebScreenshot


+ (void)takeSnapshotOfWebPageAtURL:(NSString *)url completionBlock:(void (^)(UIImageView *image))block;
{
    OTRWebScreenshot *instance = [[OTRWebScreenshot alloc] initWithCompletionBlock:block];
    [instance beginDownloadFromURL:url];

}


- (id)initWithCompletionBlock:(void (^)(UIImageView *image))block;
{
    self = [super init];
    if (self != nil)
    {
        self.completionHandler = [block copy];
        
        self.preLoader = [[FISWebViewPreloader alloc] initWithCapacity:5 scheduleType:FIFO];

    }
    return self;
}


- (void)beginDownloadFromURL:(NSString *)url;
{
    __block UIWebView *webView = nil;
    dispatch_async(dispatch_get_main_queue(), ^{
        webView = [self.preLoader setURLString:url
                                               forKey:@"Apple"
                                           withCGRect:CGRectMake(0,0,1000.0, 1000.0)];
    });
    
    UIImageView *viewImage = [[UIImageView alloc] initWithFrame:webView.frame];
    viewImage.backgroundColor = [UIColor whiteColor];
    viewImage.image = [self imageFromWebview:webView];
    
    self.completionHandler(viewImage);

}

- (UIImage *) imageFromWebview:(UIWebView*) webview
{
    
    //store the original framesize to put it back after the snapshot
    CGRect originalFrame = webview.frame;
    
    //get the width and height of webpage using js (you might need to use another call, this doesn't work always)
    int webViewHeight = [[webview stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight;"] integerValue];
    int webViewWidth = [[webview stringByEvaluatingJavaScriptFromString:@"document.body.scrollWidth;"] integerValue];
    
    //set the webview's frames to match the size of the page
    [webview setFrame:CGRectMake(0, 0, webViewWidth, webViewHeight)];
    
    //make the snapshot
    UIGraphicsBeginImageContextWithOptions(webview.frame.size, false, 0.0);
    [webview.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //set the webview's frame to the original size
    [webview setFrame:originalFrame];
    
    //and VOILA :)
    return image;
}

@end