//
//  OTRCreatEventViewController.m
//  ChatSecure
//
//  Created by Diana Perez on 3/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//


#import "OTRContactsViewController.h"

#import "OTRProtocolManager.h"

#import "OTRBuddy.h"
#import "OTRGroup.h"
#import "OTRBuddyGroup.h"
//#import "OTRXMPPBuddy.h"
#import "OTRAccount.h"
#import "OTRAccountsManager.h"
#import "OTRDatabaseView.h"
#import "OTRLog.h"
#import "OTRDatabaseManager.h"
#import "OTRDatabaseView.h"
#import "OTRAccountsManager.h"
#import "YapDatabaseFullTextSearchTransaction.h"
#import "Strings.h"
#import "OTRBuddyInfoCell.h"
#import "OTRNewBuddyViewController.h"
#import "OTRChooseAccountViewController.h"
#import "OTRConversationCell.h"
#import "OTRBroadcastListViewController.h"
#import "DTCustomColoredAccessory.h"
//#import "OTRRoom.h"
#import "OTRXMPPRoom.h"


#import "OTRMessagesBuddyViewController.h"
#import "OTRMessagesRoomViewController.h"
#import "OTRAppDelegate.h"

static CGFloat cellHeight = 80.0;

@interface OTRContactsViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>


@property (nonatomic, strong) OTRMessagesRoomViewController *roomMessagesViewController;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSLayoutConstraint *  tableViewBottomConstraint;
@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;

@property (nonatomic, strong) YapDatabaseViewMappings *mappings;
@property (nonatomic, strong) YapDatabaseViewMappings *contactmappings;

@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, strong) OTRAccount *account;
@property (nonatomic, strong) OTRRoom *xmppRoom;

@property (nonatomic, strong) NSMutableArray *arSelectedRows;
@property (nonatomic, strong) UIBarButtonItem * addBuddyButtonItem;
@property (nonatomic) int currentExpandedIndex;
@property (nonatomic, strong) NSMutableIndexSet *expandedSections;
@property (nonatomic, strong) UIRefreshControl *refreshControl;


@property (nonatomic, weak) id kOTRProtocolJoinOrCreateFailObject;
@property (nonatomic, weak) id kOTRProtocolJoinSuccessObject;
@property (nonatomic, weak) id kOTRProtocolCreateSuccessObject;


@property (nonatomic, strong) NSTimer * timeoutTimer;


@end

@implementation OTRContactsViewController


- (id) init {
    if (self = [super init]) {
    
        //DDLogInfo(@"Account Dictionary: %@",[account accountDictionary]);
        
        /////////// TabBar icon /////////////
        UITabBarItem *tab2 = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemContacts tag:2];
        tab2.title =  CONTACTS_STRING;
        [self setTabBarItem:tab2];
        
        self.currentExpandedIndex = -1;

    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSArray *accounts = [OTRAccountsManager allAutoLoginAccounts];
    
    if([accounts count] > 0)
        self.account = [[OTRAccountsManager allAutoLoginAccounts] objectAtIndex:0];
    
    self.view.backgroundColor = [UIColor whiteColor];
    

    /////////// Navigation Bar ///////////
    self.title = CONTACTS_STRING;
    //UIBarButtonItem *settingsBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"OTRSettingsIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsButtonPressed:)];
    //self.navigationItem.rightBarButtonItem = settingsBarButtonItem;
    
    self.addBuddyButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBuddyPressed:)];
    self.navigationItem.rightBarButtonItem = self.addBuddyButtonItem;

    
    
    /////////// Search Bar ///////////
    
    self.searchBar = [[UISearchBar alloc] init];
    self.searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.searchBar.delegate = self;
    self.searchBar.placeholder = SEARCH_STRING;
    [self.view addSubview:self.searchBar];
    
    
    /////////// TableView ///////////
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    
    //Cells
    [self.tableView registerClass:[OTRBuddyInfoCell class] forCellReuseIdentifier:[OTRBuddyInfoCell reuseIdentifier]];
    
    //////Refresh Control   ////
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = [UIColor grayColor];
    [self.refreshControl addTarget:self action:@selector(refreshInfo) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];

    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|" options:0 metrics:0 views:@{@"tableView":self.tableView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchBar]|" options:0 metrics:0 views:@{@"searchBar":self.searchBar}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[topLayoutGuide][searchBar][tableView]" options:0 metrics:0 views:@{@"tableView":self.tableView,@"searchBar":self.searchBar,@"topLayoutGuide":self.topLayoutGuide}]];
    self.tableViewBottomConstraint = [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    [self.view addConstraint:self.tableViewBottomConstraint];
    
    
    
    //////// YapDatabase Connection /////////
    self.databaseConnection = [[OTRDatabaseManager sharedInstance] newConnection];
    self.databaseConnection.name = NSStringFromClass([self class]);
    [self.databaseConnection beginLongLivedReadTransaction];
    
    
    
    self.mappings = [[YapDatabaseViewMappings alloc] initWithGroups:OTRContactByGroupList view:OTRContactByGroupDatabaseViewExtensionName];
    
     self.contactmappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[OTRBuddyNoGroupList] view:OTRContactDatabaseViewExtensionName];
    
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.mappings updateWithTransaction:transaction];
        [self.contactmappings updateWithTransaction:transaction];
    }];
    
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseDidUpdate:)
                                                 name:YapDatabaseModifiedNotification
                                               object:nil];
    
    self.arSelectedRows = [[NSMutableArray alloc] init];
    self.expandedSections = [[NSMutableIndexSet alloc] init];
}




- (void)refreshInfo
{
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.mappings updateWithTransaction:transaction];
        [self.contactmappings updateWithTransaction:transaction];
    }];

    
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}




- (void)viewWillAppear:(BOOL)animated
{
    
    __weak OTRContactsViewController *welf = self;
    
    
    self.kOTRProtocolJoinOrCreateFailObject = [[NSNotificationCenter defaultCenter] addObserverForName:kOTRProtocolLoginFail object:[[OTRProtocolManager sharedInstance] protocolForAccount:self.account] queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [welf protocolJoinOrCreateFailed:note];
    }];
    
    self.kOTRProtocolJoinSuccessObject = [[NSNotificationCenter defaultCenter] addObserverForName:kOTRProtocolJoinRoomSuccess object:[[OTRProtocolManager sharedInstance] protocolForAccount:self.account] queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [welf protocolJoinSuccess:note];
    }];
    
    self.kOTRProtocolCreateSuccessObject = [[NSNotificationCenter defaultCenter] addObserverForName:kOTRProtocolCreateRoomSuccess object:[[OTRProtocolManager sharedInstance] protocolForAccount:self.account] queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [welf protocolCreateSuccess:note];
    }];
}


- (void)addBuddyPressed:(id)sender
{
    //add buddy cell
    UIViewController *viewController = nil;
    OTRAccount *account = self.account;
    
    viewController = [[OTRNewBuddyViewController alloc] initWithAccountId:account.uniqueId];
    
    [self.navigationController pushViewController:viewController animated:YES];
}



#pragma mark - Expanding

-(BOOL)tableView:(UITableView *)tableView canCollapseSection:(NSInteger)section
{
    
    if((section >= 1)  && (section < (1 + [self.mappings numberOfSections]))) return YES;
    
    return NO;
}


- (void)cancelButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}



- (BOOL)canAddBuddies
{
    if([OTRAccountsManager allAccountsAbleToAddBuddies]) {
        return YES;
    }
    return NO;
}




- (OTRBuddy *)buddyAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSIndexPath *viewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection: indexPath.section - 1];
    
    if ([self useSearchResults]) {
        if (indexPath.row < [self.searchResults count]) {
            return self.searchResults[viewIndexPath.row];
        }
    }
    else
    {
        __block OTRBuddy *buddy = nil;
        if(indexPath.section >= 1  && (indexPath.section < (1 +[self.mappings numberOfSections])))
        {
            __block OTRBuddyGroup *buddyGroup;
            [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                buddyGroup = [[transaction ext:OTRContactByGroupDatabaseViewExtensionName] objectAtIndexPath:viewIndexPath withMappings:self.mappings];
                
            }];
            

            [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
                buddy = [[OTRBuddy fetchObjectWithUniqueID:buddyGroup.buddyUniqueId transaction:transaction] copy];
            }];
            
        }
        
        return buddy;
    }
    
    return nil;
}


- (OTRBuddy *)buddySolitareAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *viewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
    
    if ([self useSearchResults]) {
        if (indexPath.row < [self.searchResults count]) {
            return self.searchResults[viewIndexPath.row];
        }
    }
    else
    {
        __block OTRBuddy *buddy;
        [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            buddy = [[transaction ext:OTRContactDatabaseViewExtensionName] objectAtIndexPath:viewIndexPath withMappings:self.contactmappings];
            
        }];
        
        return buddy;
    }
    
    
    return nil;
}


- (OTRGroup *)groupAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *viewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:indexPath.section-1];
    
    if ([self useSearchResults]) {
        if (indexPath.row < [self.searchResults count]) {
            return self.searchResults[viewIndexPath.row];
        }
    }
    else
    {
        __block OTRGroup *group;
        [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            group = [OTRGroup fetchGroupWithGroupName:[[self.mappings groupForSection:viewIndexPath.section] substringFromIndex:3] withAccountUniqueId:self.account.uniqueId transaction:transaction];
            
        }];
        
        return group;
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


- (void)enterConversationWithBuddy:(OTRBuddy *)buddy
{
    if (buddy) {
        [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [buddy setAllMessagesRead:transaction];
        }];
    }
    
    OTRMessagesBuddyViewController *messagesViewController = [OTRAppDelegate appDelegate].messagesBuddyViewController;
    messagesViewController.hidesBottomBarWhenPushed = YES;
    messagesViewController.buddy = buddy;
    
    
    //if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController pushViewController:messagesViewController animated:YES];
    //}
    
}




- (void)enterGroupChatWithGroup:(OTRGroup *)group
{
    __block OTRXMPPRoom *room = nil;
    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        room = [OTRXMPPRoom fetchRoomWithGroupName:group.displayName withAccountUniqueId:self.account.uniqueId transaction:transaction];
        if (!room) {
            
            room = [[OTRXMPPRoom alloc] init];
            room.accountUniqueId = self.account.uniqueId;
            room.groupUniqueId = group.uniqueId;
            
        }
        
        room.displayName = group.displayName;
        [room saveWithTransaction:transaction];
    }];
    
    [self createMUCWithRoom:room];
    
    self.timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:45.0 target:self selector:@selector(timeout:) userInfo:nil repeats:NO];
    

}

- (void)createMUCWithRoom:(OTRRoom *)room
{
    id<OTRProtocol> protocol = [[OTRProtocolManager sharedInstance] protocolForAccount:self.account];
    [protocol createRoom:room];
    
    self.xmppRoom = nil;
    
    if(room)
        self.xmppRoom = room;
    
}


- (void)protocolCreateSuccess:(NSNotification*)notification
{
    self.roomMessagesViewController = [OTRAppDelegate appDelegate].roomMessagesViewController;
    self.roomMessagesViewController.hidesBottomBarWhenPushed = YES;
    
    if(self.xmppRoom)
        self.roomMessagesViewController.roomGroup = self.xmppRoom;
}



- (void)protocolJoinSuccess:(NSNotification*)notification
{
    //if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
    if(!self.roomMessagesViewController)
    {
        self.roomMessagesViewController = [OTRAppDelegate appDelegate].roomMessagesViewController;
        self.roomMessagesViewController.hidesBottomBarWhenPushed = YES;
        
        if(self.xmppRoom)
            self.roomMessagesViewController.roomGroup = self.xmppRoom;
        
        

    }
    //}
    [self.navigationController pushViewController:self.roomMessagesViewController animated:YES];
}


- (void)protocolJoinOrCreateFailed:(NSNotification*)notification
{
    
   
}


-(void) timeout:(NSTimer *) timer
{

}


#pragma - mark UISearchBarDelegateMethods

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText length]) {
        
        searchText = [NSString stringWithFormat:@"%@*",searchText];
        
        NSMutableArray *tempSearchResults = [NSMutableArray new];
        [self.databaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
            [[transaction ext:OTRBuddyNameSearchDatabaseViewExtensionName] enumerateKeysAndObjectsMatching:searchText usingBlock:^(NSString *collection, NSString *key, id object, BOOL *stop) {
                if ([object isKindOfClass:[OTRBuddy class]]) {
                    [tempSearchResults addObject:object];
                }
                
                if ([object isKindOfClass:[OTRGroup class]]) {
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


#pragma - mark UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    NSInteger sections = 1;
    if ([self useSearchResults]) {
        sections = 1;
    }
    else {
        sections += [self.mappings numberOfSections];
        
        if([self.contactmappings numberOfSections])
        {
            sections += 1;
        }
        
    }
    
    return sections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   
    NSInteger numberOfRows = 0;
    
    if ([self useSearchResults]) {
        numberOfRows = [self.searchResults count];
    }
    else{

        if([self tableView:tableView canCollapseSection:section])
        {

            if(section >= 1 && section < (1 + [self.mappings numberOfSections]))
            {
                
                if([self.expandedSections containsIndex:section])
                {
                    numberOfRows = [self.mappings numberOfItemsInSection:(section - 1)] + 1;
                }
                else
                {
                    numberOfRows = 1;
                }
                
            }
            
        }
        else{
            
            if(section == 0)
            {
                numberOfRows = 1;
            }
            else
            {
                numberOfRows = [self.contactmappings numberOfItemsInSection:0];
            }
            
        }
    }
   
    return numberOfRows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NSIndexPath *viewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];

    if ([self useSearchResults]) {
        if (indexPath.row < [self.searchResults count]) {
            if([self.searchResults[viewIndexPath.row] isKindOfClass:[OTRBuddy class]])
            {
                OTRBuddyInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRBuddyInfoCell reuseIdentifier] forIndexPath:indexPath];
                
                OTRBuddy * buddy = [self buddyAtIndexPath:indexPath];
                
                [cell setChatter:buddy];
                
                [cell.avatarImageView.layer setCornerRadius:(cellHeight-2.0*OTRBuddyImageCellPadding)/2.0];
                
                return cell;
                
            }
            else if([self.searchResults[viewIndexPath.row] isKindOfClass:[OTRGroup class]])
            {
                static NSString *addCellIdentifier = @"addCellIdentifier";
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:addCellIdentifier];
                if (!cell) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:addCellIdentifier];
                }
                
                OTRGroup * group = [self groupAtIndexPath:indexPath];
                cell.textLabel.text =group.displayName;
                return cell;
            }
            
            return nil;
        }
        
        return nil;
        
    }
    else{
        
        if(indexPath.section == 0) {
            // add new buddy cell
            static NSString *addCellIdentifier = @"addCellIdentifier";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:addCellIdentifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:addCellIdentifier];
            }
            cell.textLabel.text = LIST_OF_DIFUSSION_STRING;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            return cell;
        }
        else if(indexPath.section >= 1 && (indexPath.section < 1 +[self.mappings numberOfSections]))
        {
            //OTRBuddyInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRBuddyInfoCell reuseIdentifier] forIndexPath:indexPath];
            
            if([self tableView:tableView canCollapseSection:indexPath.section])
            {
                if(!indexPath.row){
                    
                    static NSString *addCellIdentifier = @"addCellIdentifier";
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:addCellIdentifier];
                    if (!cell) {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:addCellIdentifier];
                    }
                    
                    OTRGroup * group = [self groupAtIndexPath:indexPath];
                    cell.textLabel.text =group.displayName;
                    
                    
                    
                    if([self.expandedSections containsIndex:indexPath.section])
                    {
                        DTCustomColoredAccessory *h = [DTCustomColoredAccessory accessoryWithColor:[UIColor grayColor] type:DTCustomColoredAccessoryTypeUp];
                        [h addTarget:self action:@selector(didSelectAccessory:withEvent:) forControlEvents:UIControlEventTouchUpInside];
                        cell.accessoryView = h;
                        cell.accessoryView.frame = CGRectMake(-50.0, 0, 50.0, 20.0);
                    }
                    else{
                        DTCustomColoredAccessory *h = [DTCustomColoredAccessory accessoryWithColor:[UIColor grayColor] type:DTCustomColoredAccessoryTypeDown];
                        [h addTarget:self action:@selector(didSelectAccessory:withEvent:) forControlEvents:UIControlEventTouchUpInside];
                        cell.accessoryView = h;
                        cell.accessoryView.frame = CGRectMake(-50.0, 0, 50.0, 20.0);
                    }
                
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
                    return cell;
                }
                else{
                    
                    OTRBuddyInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRBuddyInfoCell reuseIdentifier] forIndexPath:indexPath];
                    
                    NSInteger newLast = [indexPath indexAtPosition:indexPath.length-1]-1;
                    indexPath = [[indexPath indexPathByRemovingLastIndex] indexPathByAddingIndex:newLast];
                    
                    OTRBuddy * buddy = [self buddyAtIndexPath:indexPath];
                    
                    [cell setChatter:buddy];
                    
                    [cell.avatarImageView.layer setCornerRadius:(cellHeight-2.0*OTRBuddyImageCellPadding)/2.0];
                   
                    return cell;
                }
            }
            return nil;
        }
        else {
            
            OTRBuddyInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:[OTRBuddyInfoCell reuseIdentifier] forIndexPath:indexPath];
             
            OTRBuddy * buddy = [self buddySolitareAtIndexPath:indexPath];
            [cell setChatter:buddy];
             
            [cell.avatarImageView.layer setCornerRadius:(cellHeight-2.0*OTRBuddyImageCellPadding)/2.0];
             
            return cell;
            
        }
    }
    
}


#pragma mark - private

-(void)didSelectAccessory:(UIControl *)button withEvent:(UIEvent *)event
{
    UITableViewCell *cell = (UITableViewCell*)button.superview;
    UITableView *tableView = (UITableView*)cell.superview.superview;
    NSIndexPath *indexPath = [tableView indexPathForCell:cell];
    [tableView.delegate tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
}



#pragma - mark UITableViewDelegate Methods

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if([self tableView:tableView canCollapseSection:indexPath.section])
    {
        if(!indexPath.row)
        {
            
            NSInteger section = indexPath.section;
            
            BOOL currentlyExpanded = [self.expandedSections containsIndex:section];
            NSInteger rows;
            
            NSMutableArray *tmpArray = [NSMutableArray array];
            
            if(currentlyExpanded)
            {
                rows = [self tableView:tableView numberOfRowsInSection:section];
                [self.expandedSections removeIndex:section];
            }
            else{
                [self.expandedSections addIndex:section];
                rows = [self tableView:tableView numberOfRowsInSection:section];
            }
            
            
            for (int i = 1; i < rows; i++)
            {
                NSIndexPath *tmpIndexPath = [NSIndexPath indexPathForRow:i inSection:section];
                
                [tmpArray addObject:tmpIndexPath];
            }
            
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            
            if(currentlyExpanded)
            {
                [tableView deleteRowsAtIndexPaths:tmpArray withRowAnimation:UITableViewRowAnimationTop];
                DTCustomColoredAccessory *h = [DTCustomColoredAccessory accessoryWithColor:[UIColor grayColor] type:DTCustomColoredAccessoryTypeDown];
                [h addTarget:self action:@selector(didSelectAccessory:withEvent:) forControlEvents:UIControlEventTouchUpInside];
                cell.accessoryView = h;
                cell.accessoryView.frame = CGRectMake(-50.0, 0, 50.0, 20.0);
            }
            else{
                [tableView insertRowsAtIndexPaths:tmpArray withRowAnimation:UITableViewRowAnimationTop];
                DTCustomColoredAccessory *h = [DTCustomColoredAccessory accessoryWithColor:[UIColor grayColor] type:DTCustomColoredAccessoryTypeUp];
                [h addTarget:self action:@selector(didSelectAccessory:withEvent:) forControlEvents:UIControlEventTouchUpInside];
                cell.accessoryView =  h;
                cell.accessoryView.frame = CGRectMake(-50.0, 0, 50.0, 20.0);
            }
        }
    }

}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return  cellHeight;
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSIndexPath *viewIndexPath =  [NSIndexPath indexPathForItem:indexPath.row inSection:0];
    
    if ([self useSearchResults]) {
        
        if([self.searchResults[viewIndexPath.row] isKindOfClass:[OTRBuddy class]])
        {
            OTRBuddy * buddy = [self buddyAtIndexPath:indexPath];
            [self enterConversationWithBuddy:buddy];
        }
        else if([self.searchResults[viewIndexPath.row] isKindOfClass:[OTRGroup class]])
        {
            //TODO Add to language and strings
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:@"Create Room"
                                                  message:@"Create Room"
                                                  preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *cancelAction = [UIAlertAction
                                           actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                           style:UIAlertActionStyleCancel
                                           handler:^(UIAlertAction *action)
                                           {
                                               NSLog(@"Cancel action");
                                           }];
            
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action)
                                       {
                                           
                                           OTRGroup *group = [self groupAtIndexPath:indexPath];
                                           [self enterGroupChatWithGroup:group];

                                       }];
            
            [alertController addAction:cancelAction];
            [alertController addAction:okAction];
            
            [self presentViewController:alertController animated:YES completion:nil];
        }
        
    }
    else{
        if(indexPath.section == 0 )
        {
            
            OTRBroadcastListViewController *broadcastViewController = [[OTRBroadcastListViewController alloc] init];
            broadcastViewController.hidesBottomBarWhenPushed = YES;
            
            [self.navigationController pushViewController:broadcastViewController animated:YES];
            
        }
        else if(indexPath.section >= 1  && (indexPath.section < (1 +[self.mappings numberOfSections])))
        {
            if([self tableView:tableView canCollapseSection:indexPath.section])
            {
                if(!indexPath.row)
                {//TODO Add to language and strings
                    UIAlertController *alertController = [UIAlertController
                                                          alertControllerWithTitle:@"Create Room"
                                                          message:@"Create Room"
                                                          preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *cancelAction = [UIAlertAction
                                                   actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                                   style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction *action)
                                                   {
                                                       NSLog(@"Cancel action");
                                                   }];
                    
                    UIAlertAction *okAction = [UIAlertAction
                                               actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                                               style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction *action)
                                               {
                                                   
                                                   OTRGroup *group = [self groupAtIndexPath:indexPath];
                                                   [self enterGroupChatWithGroup:group];
                                                   
                                               }];
                    
                    [alertController addAction:cancelAction];
                    [alertController addAction:okAction];
                    
                    [self presentViewController:alertController animated:YES completion:nil];
                }
                else
                {
                    NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row-1 inSection:indexPath.section];
                    OTRBuddy * buddy = [self buddyAtIndexPath:newIndexPath];
                    [self enterConversationWithBuddy:buddy];
                    
                }
            }
            
        }
        else
        {
            OTRBuddy * buddy = [self buddySolitareAtIndexPath:indexPath];
            [self enterConversationWithBuddy:buddy];
        }

    }
    
}




#pragma - mark UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}



#pragma - mark YapDatabaseViewUpdate

- (void)yapDatabaseDidUpdate:(NSNotification *)notification;
{
    // Process the notification(s),
    // and get the change-set(s) as applies to my view and mappings configuration.
    NSArray *notifications = [self.databaseConnection beginLongLivedReadTransaction];
    
    
    if ([self useSearchResults]) {
        return;
    }
    
    NSArray *contactGroupSectionChanges = nil;
    NSArray *contactGroupRowChanges = nil;
    [[self.databaseConnection ext:OTRContactByGroupDatabaseViewExtensionName] getSectionChanges:&contactGroupSectionChanges
                                                                              rowChanges:&contactGroupRowChanges
                                                                        forNotifications:notifications
                                                                            withMappings:self.mappings];
    NSArray *contactSectionChanges = nil;
    NSArray *contactRowChanges = nil;
    [[self.databaseConnection ext:OTRContactDatabaseViewExtensionName] getSectionChanges:&contactSectionChanges
                                                                            rowChanges:&contactRowChanges
                                                                      forNotifications:notifications
     
                                                                            withMappings:self.contactmappings];
    
    // No need to update mappings.
    // The above method did it automatically.
     
     // No need to update mappings.
     // The above method did it automatically.
    
    /*
     if (![contactSectionChanges count] == 0 || ![contactRowChanges count] == 0)
     {
         // Nothing has changed that affects our tableView
         
         [self.tableView beginUpdates];
         
         for (YapDatabaseViewSectionChange *sectionChange in contactSectionChanges)
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
                 case YapDatabaseViewChangeMove :
                 case YapDatabaseViewChangeUpdate :
                 break;
             }
         }
         
         
         
         for (YapDatabaseViewRowChange *rowChange in contactRowChanges)
         {
             NSIndexPath *indexPath = rowChange.indexPath;
             NSIndexPath *newIndexPath = rowChange.newIndexPath;
             
             indexPath = [NSIndexPath indexPathForItem:rowChange.indexPath.row inSection:rowChange.indexPath.section+1];
             newIndexPath = [NSIndexPath indexPathForItem:rowChange.newIndexPath.row inSection:rowChange.newIndexPath.section+1];
             
             
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
                     [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ]
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
     
     if (![contactGroupSectionChanges count] == 0 || ![contactGroupRowChanges count] == 0)
     {
     // Nothing has changed that affects our tableView
         
         [self.tableView beginUpdates];
         
         for (YapDatabaseViewSectionChange *contactGroupSectionChange in contactGroupSectionChanges)
         {
             NSUInteger sectionIndex = contactGroupSectionChange.index;
             sectionIndex += (1 + [self.mappings numberOfSections]);
             
             
             switch (contactGroupSectionChange.type)
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
                 case YapDatabaseViewChangeMove :
                 case YapDatabaseViewChangeUpdate :
                 break;
             }
         }
     
         for (YapDatabaseViewRowChange *contactGroupRowChange in contactGroupRowChanges)
         {
             NSIndexPath *indexPath = contactGroupRowChange.indexPath;
             NSIndexPath *newIndexPath = contactGroupRowChange.newIndexPath;
     
     
             indexPath = [NSIndexPath indexPathForItem:contactGroupRowChange.indexPath.row inSection:contactGroupRowChange.indexPath.section+(1 + [self.mappings numberOfSections])];
             newIndexPath = [NSIndexPath indexPathForItem:contactGroupRowChange.newIndexPath.row inSection:contactGroupRowChange.newIndexPath.section + (1 + [self.mappings numberOfSections])];
     
     
            switch (contactGroupRowChange.type)
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
                    [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ]
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
     
     [self.tableView reloadData];

    */
    // Familiar with NSFetchedResultsController?
    // Then this should look pretty familiar
    
   
}


@end
