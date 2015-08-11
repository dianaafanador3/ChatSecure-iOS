//
//  OTRProfileButtonsCell.m
//  ChatSecure
//
//  Created by Diana Perez on 7/2/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRProfileButtonsCell.h"

NSString * const XLFormRowDescriptorTypeProfileButtons = @"XLFormRowDescriptorTypeProfileButtons";

@implementation OTRProfileButtonsCell

+(void)load
{
    [XLFormViewController.cellClassesForRowDescriptorTypes setObject:NSStringFromClass([OTRProfileButtonsCell class]) forKey:XLFormRowDescriptorTypeProfileButtons];
}


- (void)configure
{
    [super configure];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
}

- (void)update
{
    [super update];
    
    
}

+(CGFloat)formDescriptorCellHeightForRowDescriptor:(XLFormRowDescriptor *)rowDescriptor
{
    return 70.0f;
}


#pragma mark - Events

-(void)changeContactImage
{
    NSLog(@"touched");
}

@end
