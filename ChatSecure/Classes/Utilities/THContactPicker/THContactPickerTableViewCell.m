//
//  THContactPickerTableViewCell.m
//  ContactPicker
//
//  Created by Mac on 3/27/14.
//  Copyright (c) 2014 Tristan Himmelman. All rights reserved.
//

#import "THContactPickerTableViewCell.h"
#import "OTRBuddy.h"
#import "OTRColors.h"

@interface THContactPickerTableViewCell ()


@end


@implementation THContactPickerTableViewCell

@synthesize imageViewBorderColor = _imageViewBorderColor;

- (void)awakeFromNib
{
    self.contactImage.image = [self defaultImage];
    
    CALayer *cellImageLayer = self.contactImage.layer;
    [cellImageLayer setBorderWidth:2.0];
    
    [cellImageLayer setMasksToBounds:YES];
    [cellImageLayer setBorderColor:[self.imageViewBorderColor CGColor]];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setBuddy:(OTRBuddy *)buddy
{
    if([buddy isKindOfClass:[OTRBuddy class]])
    {
        OTRBuddy *bud = (OTRBuddy *)buddy;
        
        if(bud.avatarImage) {
            self.contactImage.image = bud.avatarImage;
        }
        else {
            self.contactImage.image = [self defaultImage];
        }
        UIColor *statusColor =  [OTRColors colorWithStatus:bud.status];
        
        self.imageViewBorderColor = statusColor;
    }
    [self.contentView setNeedsUpdateConstraints];

}

- (UIColor *)imageViewBorderColor
{
    if (!_imageViewBorderColor) {
        _imageViewBorderColor = [UIColor blackColor];
    }
    return _imageViewBorderColor;
}

- (void)setImageViewBorderColor:(UIColor *)imageViewBorderColor
{
    _imageViewBorderColor = imageViewBorderColor;
    
    [self.contactImage.layer setBorderColor:[_imageViewBorderColor CGColor]];
}

- (UIImage *)defaultImage
{
    return [UIImage imageNamed:@"person"];
}


@end
