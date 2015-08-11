//
//  OTRFileItem.h
//  ChatSecure
//
//  Created by Diana Perez on 6/22/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRMediaItem.h"

@interface OTRFileItem : OTRMediaItem

+ (instancetype)fileItemWithFileURL:(NSURL *)url;

@end
