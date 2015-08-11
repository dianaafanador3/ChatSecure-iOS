//
//  OTRContactDetailView.h
//  ChatSecure
//
//  Created by IN2 on 01/07/15.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//
//

#import <UIKit/UIKit.h>
#import "XLFormViewController.h"

@class OTRChatter;

@interface OTRContactDetailsViewController : XLFormViewController

@property (nonatomic, strong) OTRChatter *chatter;

- (instancetype)initWithChatter:(OTRChatter *)chatter;


@end


