//
//  OTRConversationViewController.m
//  Off the Record
//
//  Created by David Chiles on 3/2/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRConversationViewController.h"

#import "OTRSettingsViewController.h"
#import "OTRMessagesBuddyViewController.h"
#import "OTRMessagesRoomViewController.h"
#import "OTRComposeViewController.h"
#import "OTRSubscriptionRequestsViewController.h"

#import "OTRConversationCell.h"
#import "OTRNotificationPermissions.h"
#import "OTRAccount.h"
#import "OTRBuddy.h"
#import "OTRRoom.h"
#import "OTRMessage.h"
#import "OTRBroadcastGroup.h"
#import "UIViewController+ChatSecure.h"
#import "OTRLog.h"

#import "YapDatabaseFullTextSearchTransaction.h"
#import "YapDatabaseView.h"
#import "YapDatabase.h"
#import "OTRDatabaseManager.h"
#import "YapDatabaseConnection.h"
#import "OTRDatabaseView.h"
#import "YapDatabaseViewMappings.h"

#import "OTRAppDelegate.h"


static CGFloat kOTRConversationCellHeight = 80.0;

@interface OTRConversationViewController () <OTRComposeViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate >

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSTimer *cellUpdateTimer;
@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *mappings;
@property (nonatomic, strong) YapDatabaseViewMappings *subscriptionRequestsMappings;
@property (nonatomic, strong) YapDatabaseViewMappings *unreadMessagesMappings;

@property (nonatomic, strong) UIBarButtonItem *composeBarButtonItem;

@property (nonatomic, strong) NSString *searchString;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, strong) NSLayoutConstraint *  tableViewBottomConstraint;

@end

@implementation OTRConversationViewController

- (id) init {
    if (self = [super init]) {
        
        //DDLogInfo(@"Account Dictionary: %@",[account accountDictionary]);
        
        //////////// TabBar Icon /////////
        UITabBarItem *tab1 = [[UITabBarItem alloc] init];
        [tab1 setImage:[UIImage imageNamed:@"OTRSpeechBubble"]];
        tab1.title = CHATS_STRING;
        [self setTabBarItem:tab1];
        
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    ////// Reset buddy status //////
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [OTRBuddy resetAllBuddyStatusesWithTransaction:transaction];
        [OTRBuddy resetAllChatStatesWithTransaction:transaction];
    }];
    
   
    ///////////// Setup Navigation Bar /////////////
    self.composeBarButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(composeButtonPressed:)];
    self.navigationItem.leftBarButtonItems = @[self.composeBarButtonItem];
    
    
    /////////// Search Bar ///////////
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchBar.delegate = self;
    self.searchBar.placeholder = SEARCH_STRING;
    [self.view addSubview:self.searchBar];

    
    ////////// Create TableView /////////////////
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.accessibilityIdentifier = @"conversationTableView";
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = kOTRConversationCellHeight;
    [self.view addSubview:self.tableView];
    
    [self.tableView registerClass:[OTRConversationCell class] forCellReuseIdentifier:[OTRConversationCell reuseIdentifier]];
    
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchBar]|" options:0 metrics:0 views:@{@"searchBar":self.searchBar}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:0 views:@{@"tableView":self.tableView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLayoutGuide][searchBar][tableView]" options:0 metrics:0 views:@{@"tableView":self.tableView,@"searchBar":self.searchBar,@"topLayoutGuide":self.topLayoutGuide}]];
    self.tableViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    [self.view addConstraint:self.tableViewBottomConstraint];
    
    ////////// Create YapDatabase View /////////////////
    
    self.databaseConnection = [[OTRDatabaseManager sharedInstance] newConnection];
    self.databaseConnection.name = NSStringFromClass([self class]);
    [self.databaseConnection beginLongLivedReadTransaction];
    
    self.mappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[OTRConversationGroup]
                                                               view:OTRConversationDatabaseViewExtensionName];
    
    self.subscriptionRequestsMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[OTRAllPresenceSubscriptionRequestGroup]
                                                            view:OTRAllSubscriptionRequestsViewExtensionName];

    self.unreadMessagesMappings = [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL(NSString *group, YapDatabaseReadTransaction *transaction) {
        return YES;
    } sortBlock:^NSComparisonResult(NSString *group1, NSString *group2, YapDatabaseReadTransaction *transaction) {
        return NSOrderedSame;
    } view:OTRUnreadMessagesViewExtensionName];
    
    
        
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.mappings updateWithTransaction:transaction];
        [self.subscriptionRequestsMappings updateWithTransaction:transaction];
        [self.unreadMessagesMappings updateWithTransaction:transaction];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:nil];
    
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
    [self.cellUpdateTimer invalidate];
    [self.tableView reloadData];
    [self updateInbox];
    [self updateTitle];
    self.cellUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:60.0 target:self selector:@selector(updateVisibleCells:) userInfo:nil repeats:YES];
    
    if([OTRProtocolManager sharedInstance].numberOfConnectedProtocols){
        [self enableComposeButton];
    }
    else {
        [self disableComposeButton];
    }
    
    [[OTRProtocolManager sharedInstance] addObserver:self forKeyPath:NSStringFromSelector(@selector(numberOfConnectedProtocols)) options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [OTRNotificationPermissions checkPermissions];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.cellUpdateTimer invalidate];
    self.cellUpdateTimer = nil;
    
    [[OTRProtocolManager sharedInstance] removeObserver:self forKeyPath:NSStringFromSelector(@selector(numberOfConnectedProtocols))];
    
}

- (void)settingsButtonPressed:(id)sender
{
    OTRSettingsViewController * settingsViewController = [[OTRSettingsViewController alloc] init];
    
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (void)composeButtonPressed:(id)sender
{
    OTRComposeViewController * composeViewController = [[OTRComposeViewController alloc] init];
    composeViewController.delegate = self;
    UINavigationController * modalNavigationController = [[UINavigationController alloc] initWithRootViewController:composeViewController];
    modalNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self presentViewController:modalNavigationController animated:YES completion:nil];
}

- (void)enterConversationWithBuddy:(OTRChatter *)buddy
{
    if (buddy) {
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [buddy setAllMessagesRead:transaction];
        }];
    }
    
    if([buddy isKindOfClass:[OTRBuddy class]])
    {
        OTRMessagesBuddyViewController *messagesViewController = [OTRAppDelegate appDelegate].messagesBuddyViewController;
        messagesViewController.buddy = (OTRBuddy *)buddy;
        messagesViewController.hidesBottomBarWhenPushed = YES;
        
        //if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && ![messagesViewController otr_isVisible]) {
        if(messagesViewController)
            [self.navigationController pushViewController:messagesViewController animated:YES];
        //}
    }
    else if([buddy isKindOfClass:[OTRRoom class]])
    {
        OTRMessagesRoomViewController *messagesViewController = [OTRAppDelegate appDelegate].roomMessagesViewController;
        messagesViewController.roomGroup = (OTRRoom *)buddy;
        messagesViewController.hidesBottomBarWhenPushed = YES;
        
        //if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && ![messagesViewController otr_isVisible]) {
        if(messagesViewController)
            [self.navigationController pushViewController:messagesViewController animated:YES];
        //}
    }
    
}




- (void)updateVisibleCells:(id)sender
{
    NSArray * indexPathsArray = [self.tableView indexPathsForVisibleRows];
    for(NSIndexPath *indexPath in indexPathsArray)
    {
        OTRChatter *buddy = [self cellForIndexPath:indexPath];
        
        UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
        if ([cell isKindOfClass:[OTRConversationCell class]]) {
            [(OTRConversationCell *)cell setChatter:buddy];
        }
        
    }
}


- (OTRMessage *)messageForIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *viewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
    
    
    if ([self useSearchResults]) {
        if (indexPath.row < [self.searchResults count]) {
            if(![self.searchResults[viewIndexPath.row] isKindOfClass:[OTRBuddy class]])
            {
                return self.searchResults[viewIndexPath.row];
            }
        }
    }
    
    return nil;
}

- (OTRChatter *)cellForIndexPath:(NSIndexPath *)indexPath
{
    
    NSIndexPath *viewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
    
    
    if ([self useSearchResults]) {
        if (indexPath.row < [self.searchResults count])
        {
            if([self.searchResults[viewIndexPath.row] isKindOfClass:[OTRChatter class]])
            {
                return self.searchResults[viewIndexPath.row];
            }
            else{
                __block OTRChatter *buddy = nil;
                OTRMessage *message = self.searchResults[viewIndexPath.row];
                [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                    
                    buddy =  [message chatterWithTransaction:transaction];
                }];
                
                return buddy;
            }
        }
    }
    else
    {
        __block OTRChatter *buddy = nil;
        [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            
            buddy = [[transaction extension:OTRConversationDatabaseViewExtensionName] objectAtIndexPath:indexPath withMappings:self.mappings];
        }];
        
        if(buddy)
            return buddy;
    }
    
    return nil;
}



- (BOOL)useSearchResults
{
    if([self.searchBar.text length])
    {
        return YES;
    }
    return NO;
}



- (void)enableComposeButton
{
    self.composeBarButtonItem.enabled = YES;
}

- (void)disableComposeButton
{
    self.composeBarButtonItem.enabled = NO;
}

#pragma KVO Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSUInteger numberConnectedAccounts = [[change objectForKey:NSKeyValueChangeNewKey] unsignedIntegerValue];
    if (numberConnectedAccounts) {
        [self enableComposeButton];
    }
    else {
        [self disableComposeButton];
    }
}

#pragma - mark Inbox Methods

- (void)showInbox
{
    if ([self.navigationItem.leftBarButtonItems count] != 2) {
        UIBarButtonItem *inboxBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"inbox"] style:UIBarButtonItemStylePlain target:self action:@selector(inboxButtonPressed:)];
        
        self.navigationItem.leftBarButtonItems = @[self.composeBarButtonItem,inboxBarButtonItem];
    }
}

- (void)hideInbox
{
    if ([self.navigationItem.leftBarButtonItems count] > 1) {
        self.navigationItem.leftBarButtonItems = @[self.composeBarButtonItem];
    }
    
}

- (void)inboxButtonPressed:(id)sender
{
    OTRSubscriptionRequestsViewController *viewController = [[OTRSubscriptionRequestsViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.navigationController presentViewController:navController animated:YES completion:nil];
}

- (void)updateInbox
{
    if ([self.subscriptionRequestsMappings numberOfItemsInAllGroups] > 0) {
        [self showInbox];
    }
    else {
        [self hideInbox];
    }
}

- (void)updateTitle
{
    NSUInteger numberUnreadMessages = [self.unreadMessagesMappings numberOfItemsInAllGroups];
    if (numberUnreadMessages > 99) {
        self.title = [NSString stringWithFormat:@"%@ (99+)",CHATS_STRING];
    }
    else if (numberUnreadMessages > 0)
    {
        self.title = [NSString stringWithFormat:@"%@ (%d)",CHATS_STRING,(int)numberUnreadMessages];
    }
    else {
        self.title = CHATS_STRING;
    }
}


#pragma - mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.mappings numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    
    if ([self useSearchResults]) {
        numberOfRows = [self.searchResults count];
    }
    else {
        numberOfRows = [self.mappings numberOfItemsInSection:section];
    }
    
    return numberOfRows;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Delete conversation
    if ([self useSearchResults]) {
        return;
    }
    
    
    //Delete conversation
    if(editingStyle == UITableViewCellEditingStyleDelete) {
        OTRChatter *cellBuddy = [[self cellForIndexPath:indexPath] copy];
        
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction)
        {
             [OTRMessage deleteAllMessagesForChatterId:cellBuddy.uniqueId transaction:transaction];
             //TODO[[[OTRXMPPBuddy fetchObjectWithUniqueID:cellBuddy.uniqueId transaction:transaction] copy] removeWithTransaction:transaction] ;
            
        }
        completionBlock:^{
             [self.tableView reloadData];
        }];
        
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *viewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
    
    if ([self useSearchResults])
    {
        if (indexPath.row < [self.searchResults count])
        {
            if([self.searchResults[viewIndexPath.row] isKindOfClass:[OTRChatter class]])
            {
                OTRConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRConversationCell reuseIdentifier] forIndexPath:indexPath];
                OTRChatter *buddy = [self cellForIndexPath:indexPath];
                
                [cell.avatarImageView.layer setCornerRadius:(kOTRConversationCellHeight-2.0*OTRBuddyImageCellPadding)/2.0];
                
                [cell setChatter:buddy];
                
                return cell;
            }
            else
            {
                OTRConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRConversationCell reuseIdentifier] forIndexPath:indexPath];
                
                OTRChatter * buddy = [self cellForIndexPath:indexPath];
                OTRMessage * message = [self messageForIndexPath:indexPath];
                
                [cell.avatarImageView.layer setCornerRadius:(kOTRConversationCellHeight-2.0*OTRBuddyImageCellPadding)/2.0];
                
                [cell setBuddy:buddy withMessage:message andSearch:self.searchString];
                
                return cell;
                
            }
            
            return nil;
        }
        
        return nil;
    }
    else{
        
        OTRConversationCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRConversationCell reuseIdentifier] forIndexPath:indexPath];
        OTRChatter * buddy = [self cellForIndexPath:indexPath];
        
        [cell.avatarImageView.layer setCornerRadius:(kOTRConversationCellHeight-2.0*OTRBuddyImageCellPadding)/2.0];
        
        [cell setChatter:buddy];
        
        return cell;
    }
}

#pragma - mark UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kOTRConversationCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kOTRConversationCellHeight;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if ([self useSearchResults])
    {
        OTRChatter *buddy = [self cellForIndexPath:indexPath];
        OTRMessage * message = [self messageForIndexPath:indexPath];
        
        
        [self enterConversationWithBuddy:buddy];
        
        //TODO enter conversation after a search
    }
    else{
        
        OTRChatter *buddy = [self cellForIndexPath:indexPath];
        [self enterConversationWithBuddy:buddy];
        
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
    
    
    if ([self useSearchResults]) {
        return;
    }

    
    [[self.databaseConnection ext:OTRConversationDatabaseViewExtensionName] getSectionChanges:&sectionChanges
                                                                                   rowChanges:&rowChanges
                                                                             forNotifications:notifications
                                                                                 withMappings:self.mappings];
    
    
    
    
    NSArray *subscriptionSectionChanges = nil;
    NSArray *subscriptionRowChanges = nil;
    [[self.databaseConnection ext:OTRAllSubscriptionRequestsViewExtensionName] getSectionChanges:&subscriptionSectionChanges
                                                                                      rowChanges:&subscriptionRowChanges
                                                                                forNotifications:notifications
                                                                                    withMappings:self.subscriptionRequestsMappings];
    
    if ([subscriptionSectionChanges count] || [subscriptionRowChanges count]) {
        [self updateInbox];
    }
    
    
    
    NSArray *unreadMessagesSectionChanges = nil;
    NSArray *unreadMessagesRowChanges = nil;
    
    [[self.databaseConnection ext:OTRUnreadMessagesViewExtensionName] getSectionChanges:&unreadMessagesSectionChanges
                                                                             rowChanges:&unreadMessagesRowChanges
                                                                       forNotifications:notifications
                                                                           withMappings:self.unreadMessagesMappings];
    
    if ([unreadMessagesSectionChanges count] || [unreadMessagesRowChanges count]) {
        [self updateTitle];
    }
    
    
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
        switch (sectionChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
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
        switch (rowChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.tableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.tableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeMove :
            {
                [self.tableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate :
            {
                [self.tableView reloadRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }
    
    [self.tableView endUpdates];
}

#pragma - mark OTRComposeViewController Method

- (void)controller:(OTRComposeViewController *)viewController didSelectBuddy:(OTRBuddy *)buddy
{
    [viewController dismissViewControllerAnimated:YES completion:^{
        [self enterConversationWithBuddy:buddy];
    }];
}


#pragma - mark UISearchBarDelegateMethods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText length])
    {
        self.searchString = [NSString stringWithFormat:@"%@*",searchText];
        
        NSMutableArray *tempSearchResults = [NSMutableArray new];
        
        [self.databaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
            [[transaction ext:OTRChatNameSearchDatabaseViewExtensionName] enumerateKeysAndObjectsMatching:self.searchString usingBlock:^(NSString *collection, NSString *key, id object, BOOL *stop) {
                if ([object isKindOfClass:[OTRChatter class]]) {
                    [tempSearchResults addObject:object];
                }
                
                if ([object isKindOfClass:[OTRMessage class]]) {
                    [tempSearchResults addObject:object];
                }
                
            }];
        } completionBlock:^{
            self.searchResults = tempSearchResults;
            [self.tableView reloadData];
        }];
    }
    else{
        [self.tableView reloadData];
    }
}


- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
    [searchBar resignFirstResponder];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}



@end
