//
//  OTRLockButton.h
//  Off the Record
//
//  Created by David Chiles on 2/10/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRChatter;

@interface OTRProfileIcon : UIButton

@property (nonatomic) OTRChatter *chatterAvatar;

+(instancetype) loadButtonWithInitialAvatar:(OTRChatter *)chatter;

@end
