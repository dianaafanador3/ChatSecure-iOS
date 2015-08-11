//
//  THContactPickerViewControllerDemo.h
//  ContactPicker
//
//  Created by Vladislav Kovtash on 12.11.13.
//  Copyright (c) 2013 Tristan Himmelman. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "THContactPickerView.h"
#import "THContactPickerTableViewCell.h"
#import "XLForm.h"

@class OTRContactPickerViewController;

@protocol OTRContactPickerViewControllerDelegate <NSObject>

- (void)controller:(OTRContactPickerViewController *)viewController didSelectBuddies:(NSArray *)buddies;

@end


@interface OTRContactPickerViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, THContactPickerDelegate, XLFormRowDescriptorViewController>

@property (nonatomic, strong) THContactPickerView *contactPickerView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *contacts;
@property (nonatomic, strong) NSMutableArray *selectedContacts;
@property (nonatomic, strong) NSArray *filteredContacts;

@property (nonatomic, weak) id<OTRContactPickerViewControllerDelegate> delegate;

@end
