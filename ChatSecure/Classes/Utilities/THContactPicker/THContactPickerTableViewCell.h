//
//  THContactPickerTableViewCell.h
//  ContactPicker
//
//  Created by Mac on 3/27/14.
//  Copyright (c) 2014 Tristan Himmelman. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OTRBuddy;

@interface THContactPickerTableViewCell : UITableViewCell

@property (nonatomic, strong) UIColor *imageViewBorderColor;
@property (weak, nonatomic) IBOutlet UIImageView *contactImage;

- (void)setBuddy:(OTRBuddy *)buddy;

@end
