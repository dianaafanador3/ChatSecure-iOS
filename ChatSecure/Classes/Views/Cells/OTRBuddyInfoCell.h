//
//  OTRBuddyInfoCell.h
//  Off the Record
//
//  Created by David Chiles on 3/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyImageCell.h"

@class OTRChatter;

@interface OTRBuddyInfoCell : OTRBuddyImageCell

@property (nonatomic, strong, readonly) UILabel *nameLabel;
@property (nonatomic, strong, readonly) UILabel *identifierLabel;
@property (nonatomic, strong, readonly) UILabel *accountLabel;

- (void)setChatter:(OTRChatter *)buddy withAccountName:(NSString *)accountName;

- (void)setChatter:(OTRChatter *)chatter;

@end
