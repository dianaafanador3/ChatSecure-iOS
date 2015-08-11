//
//  OTRProfileInfoCell.m
//  ChatSecure
//
//  Created by Diana Perez on 7/1/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRProfileInfoCell.h"

#import "Strings.h"
#import "OTRChatter.h"
#import "JSQMessagesTimestampFormatter.h"

NSString * const XLFormRowDescriptorTypeProfileInfo = @"XLFormRowDescriptorTypeProfileInfo";

@interface OTRProfileInfoCell ()

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *contactStatus;
@property (weak, nonatomic) IBOutlet UILabel *contactLastSeenDate;

@end


@implementation OTRProfileInfoCell

+(void)load
{
    [XLFormViewController.cellClassesForRowDescriptorTypes setObject:NSStringFromClass([OTRProfileInfoCell class]) forKey:XLFormRowDescriptorTypeProfileInfo];
}


- (void)configure
{
    [super configure];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
}

- (void)update
{
    [super update];
    
    self.avatarImageView.image = ((OTRChatter *)self.rowDescriptor.value).avatarImage;
    
    self.contactStatus.text = ((OTRChatter *)self.rowDescriptor.value).statusMessage;
    
    if(((OTRChatter *)self.rowDescriptor.value).dateLastChatState)
    {
        NSMutableAttributedString *newAttString = [[NSMutableAttributedString alloc] initWithString:LAST_PRESENCE_STRING];
        
        [newAttString appendAttributedString:[[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:((OTRChatter *)self.rowDescriptor.value).dateLastChatState]];
        
        self.contactLastSeenDate.attributedText = newAttString;
    }
    
}


+(CGFloat)formDescriptorCellHeightForRowDescriptor:(XLFormRowDescriptor *)rowDescriptor
{
    return 250.0f;
}

#pragma mark - Events

-(void)changeContactImage
{
    NSLog(@"touched");
}

@end
