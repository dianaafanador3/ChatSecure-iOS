//
//  OTRCreatEventViewController.m
//  ChatSecure
//
//  Created by Diana Perez on 3/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OTREventDetailViewController.h"


@class OTREventDetailViewController, ContentTableViewCell, OTREvent;



@protocol OTREventDetailViewControllerDelegate <NSObject>

@optional

- (void)contentTableViewController:(OTREventDetailViewController *)controller cellStartedBeingTouched:(ContentTableViewCell *)cell;


- (void)contentTableViewController:(OTREventDetailViewController *)controller cellStoppedBeingTouched:(ContentTableViewCell *)cell;

@required

- (void)contentTableViewController:(OTREventDetailViewController *)controller didTapItem:(NSObject *)item;

@end

@interface OTREventDetailViewController : UITableViewController

@property (nonatomic, strong) OTREvent *event;

@property (nonatomic, readwrite) UIEdgeInsets itemCellInsets;

@property (strong, nonatomic) UIColor *itemCellBackgroundColor;

@property (nonatomic, readwrite) UIViewContentMode itemCellContentMode;

@property (strong, nonatomic) NSDictionary *itemCellTextAttributes;

@property (strong, nonatomic) NSDictionary *itemCellLinkAttributes;

@property (strong, nonatomic) NSArray *items;

@property (strong, nonatomic) UIView *emptyPlaceholderView;

@property (strong, nonatomic) NSObject<OTREventDetailViewControllerDelegate> *contentDelegate;

@end



