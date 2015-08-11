//
//  OTRLockButton.m
//  Off the Record
//
//  Created by David Chiles on 2/10/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRProfileIcon.h"
#import "OTRChatter.h"
#import "UIControl+JTTargetActionBlock.h"

#define PROFILE_BUTTON_DIAMETER 34

@implementation OTRProfileIcon

- (void)setChatterAvatar:(OTRChatter *)chatter
{
    if(chatter.avatarImage)
    {
        UIImage * backgroundImage = chatter.avatarImage;
        CGRect buttonFrame = [self frame];
        
        buttonFrame.size.width = PROFILE_BUTTON_DIAMETER;
        buttonFrame.size.height = PROFILE_BUTTON_DIAMETER;
        
        [self setFrame:buttonFrame];
        
        [self setBackgroundImage:backgroundImage forState:UIControlStateNormal];
        
        //[self willChangeValueForKey:NSStringFromSelector(@selector(lockStatus))];
        //[self didChangeValueForKey:NSStringFromSelector(@selector(lockStatus))];
    }
}


+(instancetype) loadButtonWithInitialAvatar:(OTRChatter *)chatter
{
    OTRProfileIcon *profileIcon = [self buttonWithType:UIButtonTypeCustom];
    profileIcon.chatterAvatar = chatter;
    profileIcon.userInteractionEnabled = NO;
    
    return profileIcon;
}


@end
