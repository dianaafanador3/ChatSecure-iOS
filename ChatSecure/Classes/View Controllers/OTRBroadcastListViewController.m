//
//  OTRComposeViewController.m
//  Off the Record
//
//  Created by David Chiles on 3/4/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRBroadcastListViewController.h"

#import "OTRBuddy.h"
//#import "OTRXMPPBuddy.h"
#import "OTRAccount.h"
#import "OTRDatabaseView.h"
#import "OTRLog.h"
#import "OTRDatabaseManager.h"
#import "OTRDatabaseView.h"
#import "OTRAccountsManager.h"
#import "YapDatabaseFullTextSearchTransaction.h"
#import "Strings.h"
#import "OTRBroadcastInfoCell.h"

#import "OTRChooseAccountViewController.h"
#import "OTRConversationCell.h"

#import "OTRMessagesViewController.h"
#import "OTRMessagesGroupViewController.h"
#import "OTRBroadcastGroup.h"

#import "OTRAppDelegate.h"

#import "OTRContactPickerViewController.h"

static CGFloat cellHeight = 80.0;

@interface OTRBroadcastListViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, OTRContactPickerViewControllerDelegate>


@property (nonatomic, strong) OTRAccount *account;

@property (nonatomic, strong) OTRContactPickerViewController *contactPickerView;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSLayoutConstraint *  tableViewBottomConstraint;
@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *mappings;
@property (nonatomic, strong) YapDatabaseViewMappings *broadcastmappings;
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic) BOOL viewWithcanAddBuddy;
@property (nonatomic) BOOL viewWithListOfdifussion;
@property (nonatomic, strong) NSMutableArray *arSelectedRows;
@property (nonatomic, strong) UIBarButtonItem * createBarButtonItem;



@end

@implementation OTRBroadcastListViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    /*
    UIBarButtonItem * editBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonPressed:)];
    
    self.navigationItem.rightBarButtonItem = editBarButtonItem;
    */

    
    /////////// Navigation Bar ///////////
    self.title = LIST_OF_DIFUSSION_STRING;
    
    /////////// Search Bar ///////////
    /*
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchBar.delegate = self;
    self.searchBar.placeholder = SEARCH_STRING;
    [self.view addSubview:self.searchBar];*/
    
    /////////// TableView ///////////
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    //[self.tableView setEditing:YES animated:YES];
    [self.view addSubview:self.tableView];
    
    [self.tableView registerClass:[OTRBroadcastInfoCell class] forCellReuseIdentifier:[OTRBroadcastInfoCell reuseIdentifier]];
   
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:0 views:@{@"tableView":self.tableView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]" options:0 metrics:0 views:@{@"tableView":self.tableView,@"topLayoutGuide":self.topLayoutGuide}]];
    self.tableViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    [self.view addConstraint:self.tableViewBottomConstraint];
    
    //////// YapDatabase Connection /////////
    self.databaseConnection = [[OTRDatabaseManager sharedInstance] newConnection];
    self.databaseConnection.name = NSStringFromClass([self class]);
    [self.databaseConnection beginLongLivedReadTransaction];
    
    self.broadcastmappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[OTRAllBroadcastGroupList] view:OTRAllBroadcastListDatabaseViewExtensionName];
    
    self.mappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[OTRAllBuddiesGroupList] view:OTRAllBuddiesDatabaseViewExtensionName];
    
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.broadcastmappings updateWithTransaction:transaction];
        [self.mappings updateWithTransaction:transaction];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:nil];

    
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.tableView reloadData];

    /*[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];*/
}

-(void)viewDidAppear:(BOOL)animated
{
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)editButtonPressed:(id)sender
{
    //[self dismissViewControllerAnimated:YES completion:nil];
}



- (OTRBroadcastGroup *)broadcastGroupAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *viewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
    
    __block OTRBroadcastGroup *broadcastGroup;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        broadcastGroup = [[transaction ext:OTRAllBroadcastListDatabaseViewExtensionName] objectAtIndexPath:viewIndexPath withMappings:self.broadcastmappings];
        
    }];
    
    if(broadcastGroup)
    {
        return broadcastGroup;
    }

    return nil;
}


- (void)enterConversationWithBuddies:(OTRBroadcastGroup *)broadcastGroup
{
    if(broadcastGroup)
    {
        OTRMessagesGroupViewController *messagesViewController = [OTRAppDelegate appDelegate].groupMessagesViewController;
        messagesViewController.hidesBottomBarWhenPushed = YES;
        messagesViewController.broadcastGroup = broadcastGroup;
        
        //if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [self.navigationController pushViewController:messagesViewController animated:YES];
        //}
        
    }
}


-(void)newConversationWithBuddies:(NSMutableArray *)buddies
{
    
    if([buddies count] > 1 )
    {
        OTRBroadcastGroup *broadcastGroup = [[OTRBroadcastGroup alloc] initWithBuddyArray:buddies];
        
        NSString *accountUniqueId = @"";
        for(OTRBuddy *buddy in broadcastGroup.buddies)
            accountUniqueId = buddy.accountUniqueId;
        
        
        broadcastGroup.accountUniqueId = accountUniqueId;
        
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction){
            [broadcastGroup saveWithTransaction:transaction];
        }
         completionBlock:^{
             OTRMessagesGroupViewController *messagesViewController = [OTRAppDelegate appDelegate].groupMessagesViewController;
             messagesViewController.hidesBottomBarWhenPushed = YES;
             messagesViewController.broadcastGroup = broadcastGroup;
             
             //if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
                 [self.navigationController pushViewController:messagesViewController animated:YES];
             //}
         }];
    }
    
}


#pragma - mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    NSInteger sections = 1;
    
    sections += [self.broadcastmappings numberOfSections];
    
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    if (section == 0) {
        numberOfRows = 1;
    }
    else {
        numberOfRows = [self.broadcastmappings numberOfItemsInSection:0];
    }
   
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if(indexPath.section == 0) {
        // add new buddy cell
        static NSString *addCellIdentifier = @"addCellIdentifier";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:addCellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:addCellIdentifier];
        }
        cell.textLabel.text = NEW_BROADCAST_LIST_STRING;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        return cell;
    }
    else {
        
        OTRBroadcastInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRBroadcastInfoCell reuseIdentifier] forIndexPath:indexPath];
        OTRBroadcastGroup * broadcastGroup = [self broadcastGroupAtIndexPath:indexPath];
        
        /*__block NSString *buddyAccountName = nil;
         [[OTRDatabaseManager sharedInstance].mainThreadReadOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
         buddyAccountName = [OTRAccount fetchObjectWithUniqueID:buddy.accountUniqueId transaction:transaction].username;
         }];*/
        
        [cell setBroadcastGroup:broadcastGroup];
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Delete conversation
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        OTRBroadcastGroup *cellGroup = [[self broadcastGroupAtIndexPath:indexPath] copy];
        
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction)
         {
             [[[OTRBroadcastGroup fetchObjectWithUniqueID:cellGroup.uniqueId transaction:transaction] copy] removeWithTransaction:transaction] ;
             
         }
         completionBlock:^{
             
             [self.tableView reloadData];
           }];
    }
}


#pragma - mark UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return  cellHeight;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return UITableViewCellEditingStyleNone;

    } else {
        return UITableViewCellEditingStyleDelete;
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if(indexPath.section == 0)
    {
        
        self.contactPickerView = [[OTRContactPickerViewController alloc] init];
        self.contactPickerView.hidesBottomBarWhenPushed = YES;
        self.contactPickerView.delegate = self;
        
        [self.navigationController pushViewController:self.contactPickerView  animated:YES];
    }
    else
    {
        OTRBroadcastGroup *broadcastGroup = [self broadcastGroupAtIndexPath:indexPath];
        if(broadcastGroup)
        {
            [self enterConversationWithBuddies:broadcastGroup];
        }
    }
    
}

#pragma - mark UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}

#pragma - mark YapDatabse Methods

- (void)yapDatabaseModified:(NSNotification *)notification
{
    NSArray *notifications = [self.databaseConnection beginLongLivedReadTransaction];
    
    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;
    
    [[self.databaseConnection ext:OTRAllBroadcastListDatabaseViewExtensionName] getSectionChanges:&sectionChanges
                                                                           rowChanges:&rowChanges
                                                                     forNotifications:notifications
                                                                         withMappings:self.broadcastmappings];
    
    /*
    NSArray *messageSectionChanges = nil;
    NSArray *messageRowChanges = nil;
    [[self.databaseConnection ext:OTRBroadcastChatDatabaseViewExtensionName] getSectionChanges:&messageSectionChanges
                                                                              rowChanges:&messageRowChanges
                                                                        forNotifications:notifications
                                                                            withMappings:self.subscriptionRequestsMappings];
    */
    /*if ([subscriptionSectionChanges count] || [subscriptionRowChanges count]) {
        [self updateInbox];
    }*/
    
    
   
    
    // No need to update mappings.
    // The above method did it automatically.
    
    if ([sectionChanges count] == 0 && [rowChanges count] == 0)
    {
        // Nothing has changed that affects our tableView
        return;
    }
    
    // Familiar with NSFetchedResultsController?
    // Then this should look pretty familiar
    
    [self.tableView beginUpdates];
    
    
    for (YapDatabaseViewSectionChange *sectionChange in sectionChanges)
    {
        NSUInteger sectionIndex = sectionChange.index;
        
        sectionIndex += 1;
        
        switch (sectionChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate:
            case YapDatabaseViewChangeMove:
                break;
        }
    }
    
    for (YapDatabaseViewRowChange *rowChange in rowChanges)
    {
        NSIndexPath *indexPath = rowChange.indexPath;
        NSIndexPath *newIndexPath = rowChange.newIndexPath;
        
        indexPath = [NSIndexPath indexPathForItem:rowChange.indexPath.row inSection:1];
        newIndexPath = [NSIndexPath indexPathForItem:rowChange.newIndexPath.row inSection:1];
        
        
        switch (rowChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.tableView deleteRowsAtIndexPaths:@[ indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeMove :
            {
                [self.tableView deleteRowsAtIndexPaths:@[ indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView insertRowsAtIndexPaths:@[ newIndexPath]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate :
            {
                [self.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                      withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }
    
    [self.tableView endUpdates];
}


#pragma - mark OTRContactPickerViewController Delegate


 - (void)controller:(OTRContactPickerViewController *)viewController didSelectBuddies:(NSMutableArray *)buddies
{
    [self newConversationWithBuddies:buddies];
}


@end
