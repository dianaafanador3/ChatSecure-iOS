//
//  OTRComposeViewController.h
//  Off the Record
//
//  Created by David Chiles on 3/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>


@class OTRBuddy;
@class OTRContactsViewController;

@protocol OTRContactsViewControllerDelegate <NSObject>

@required
- (void)controller:(OTRContactsViewController *)viewController didSelectBuddy:(OTRBuddy *)buddy;
- (void)controller:(OTRContactsViewController *)viewController didSelectBuddies:(NSMutableArray *)buddies;

@end

@interface OTRContactsViewController : UIViewController

@property (nonatomic, weak) id<OTRContactsViewControllerDelegate> delegate;

@property(nonatomic,strong) NSMutableArray * dataModelArray;

- (id)init;

@end
