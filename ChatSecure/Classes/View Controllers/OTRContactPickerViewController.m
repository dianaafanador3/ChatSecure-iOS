//
//  THContactPickerViewControllerDemo.m
//  ContactPicker
//
//  Created by Vladislav Kovtash on 12.11.13.
//  Copyright (c) 2013 Tristan Himmelman. All rights reserved.
//

#import "OTRContactPickerViewController.h"
#import "OTRDatabaseManager.h"
#import "OTRDatabaseView.h"
#import "YapDatabaseFullTextSearchTransaction.h"

#import "OTRBuddy.h"

#import "Strings.h"

static CGFloat cellHeight = 70.0;

//#define kKeyboardHeight 216.0
#define kKeyboardHeight 0.0

UIBarButtonItem *barButton;

@interface OTRContactPickerViewController () <THContactPickerDelegate>

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *mappings;

@end

@implementation OTRContactPickerViewController
@synthesize rowDescriptor = _rowDescriptor;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = [NSString stringWithFormat:@"%@ (0)", SELECT_CONTACTS_STRING];
        
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    //    UIBarButtonItem * barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStyleBordered target:self action:@selector(removeAllContacts:)];
    
    /*UIBarButtonItem * cancelBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
    self.navigationItem.leftBarButtonItem = cancelBarButtonItem;*/
    
    barButton = [[UIBarButtonItem alloc] initWithTitle:DONE_STRING style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
    barButton.enabled = FALSE;
    
    self.navigationItem.rightBarButtonItem = barButton;
    
    // Initialize and add Contact Picker View
    self.contactPickerView = [[THContactPickerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 100)];
    self.contactPickerView.delegate = self;
    [self.contactPickerView setPlaceholderString:TYPE_CONTACT_NAME_STRING];
    [self.view addSubview:self.contactPickerView];
    
    // Fill the rest of the view with the table view
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, self.contactPickerView.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - self.contactPickerView.frame.size.height - kKeyboardHeight) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"THContactPickerTableViewCell" bundle:nil] forCellReuseIdentifier:@"ContactCell"];
    
    [self.view insertSubview:self.tableView belowSubview:self.contactPickerView];
    
    
    //Get Contacts
    //////// YapDatabase Connection /////////
    self.databaseConnection = [[OTRDatabaseManager sharedInstance] newConnection];
    self.databaseConnection.name = NSStringFromClass([self class]);
    [self.databaseConnection beginLongLivedReadTransaction];
    
    self.mappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[OTRAllBuddiesNoStatusGroupList] view:OTRAllBuddiesNoStatusDatabaseViewExtensionName];
    
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.mappings updateWithTransaction:transaction];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseDidUpdate:)
                                                 name:YapDatabaseModifiedNotification
                                               object:nil];

    self.selectedContacts = [[NSMutableArray alloc] init];
    
    if([((NSMutableArray *)self.rowDescriptor.value) count])
    {
        self.selectedContacts = self.rowDescriptor.value;
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (OTRBuddy *)buddyAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *viewIndexPath = [NSIndexPath indexPathForItem:indexPath.row inSection:0];
    
    if ([self useSearchResults]) {
        if (indexPath.row < [self.filteredContacts count]) {
            return self.filteredContacts[viewIndexPath.row];
        }
    }
    else
    {
        __block OTRBuddy *buddy;
        [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            buddy = [[transaction ext:OTRAllBuddiesNoStatusDatabaseViewExtensionName] objectAtIndexPath:viewIndexPath withMappings:self.mappings];
            
        }];
        
        return buddy;
    }
    
    
    return nil;
}

- (NSIndexPath *)indexPathOfBuddy:(OTRBuddy *)buddy
{
    
    if ([self useSearchResults]) {
        if ([self.filteredContacts containsObject:buddy]) {
            return [NSIndexPath indexPathForItem:[self.filteredContacts indexOfObject:buddy]inSection:0];
        }
    }
    else
    {
        __block NSIndexPath *indexPath;
        [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            indexPath = [[transaction ext:OTRAllBuddiesNoStatusDatabaseViewExtensionName] indexPathForKey:buddy.uniqueId inCollection:[OTRBuddy collection] withMappings:self.mappings];
            
        }];
        
        return indexPath;
    }
    
    
    return nil;
}


- (BOOL)useSearchResults
{
    if([self.contactPickerView.textView.text length])
    {
        return YES;
    }
    return NO;
}




- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat topOffset = 0;
    if ([self respondsToSelector:@selector(topLayoutGuide)]){
        topOffset = self.topLayoutGuide.length;
    }
    CGRect frame = self.contactPickerView.frame;
    frame.origin.y = topOffset;
    self.contactPickerView.frame = frame;
    //[self adjustTableViewFrame:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)adjustTableViewFrame:(BOOL)animated
{
    CGRect frame = self.tableView.frame;
    // This places the table view right under the text field
    frame.origin.y = self.contactPickerView.frame.size.height;
    // Calculate the remaining distance
    frame.size.height = self.view.frame.size.height - self.contactPickerView.frame.size.height - kKeyboardHeight;
    
    if(animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
        [UIView setAnimationDelay:0.1];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        
        self.tableView.frame = frame;
        
        [UIView commitAnimations];
    }
    else{
        self.tableView.frame = frame;
    }
}



#pragma mark - UITableView Delegate and Datasource functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sections = 0;
    if ([self useSearchResults]) {
        sections = 1;
    }
    else {
        sections = [self.mappings numberOfSections];
    }
    
    return sections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    
    if ([self useSearchResults]) {
        numberOfRows = [self.filteredContacts count];
    }
    else {
        numberOfRows = [self.mappings numberOfItemsInSection:0];
    }
    
    
    return numberOfRows;

}

- (CGFloat)tableView: (UITableView*)tableView heightForRowAtIndexPath: (NSIndexPath*) indexPath {
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    OTRBuddy * buddy = [self buddyAtIndexPath:indexPath];
    
    NSString *cellIdentifier = @"ContactCell";
    THContactPickerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil){
        cell = [[THContactPickerTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    // Get the UI elements in the cell;
    UILabel *contactNameLabel = (UILabel *)[cell viewWithTag:101];
    UILabel *mobilePhoneNumberLabel = (UILabel *)[cell viewWithTag:102];
    UIImageView *checkboxImageView = (UIImageView *)[cell viewWithTag:104];
        
    // Assign values to to US elements
    contactNameLabel.text = buddy.displayName;
    mobilePhoneNumberLabel.text = buddy.username;
    [cell setBuddy:buddy];
    [cell.contactImage.layer setCornerRadius:cell.contactImage.frame.size.width/2];

    // Set the checked state for the contact selection checkbox
    UIImage *image;
    if ([self.selectedContacts containsObject:buddy]){
        //cell.accessoryType = UITableViewCellAccessoryCheckmark;
        image = [UIImage imageNamed:@"OTRIcon-checkbox-selected-green"];
    } else {
        //cell.accessoryType = UITableViewCellAccessoryNone;
        image = [UIImage imageNamed:@"OTRIcon-checkbox-unselected"];
    }
    checkboxImageView.image = image;
    
    // Assign a UIButton to the accessoryView cell property
    cell.accessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    // Set a target and selector for the accessoryView UIControlEventTouchUpInside
    [(UIButton *)cell.accessoryView addTarget:self action:@selector(viewContactDetail:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryView.tag = buddy.uniqueId; //so we know which ABRecord in the IBAction method
    
    // // For custom accessory view button use this.
    //    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    //    button.frame = CGRectMake(0.0f, 0.0f, 150.0f, 25.0f);
    //
    //    [button setTitle:@"Expand"
    //            forState:UIControlStateNormal];
    //
    //    [button addTarget:self
    //               action:@selector(viewContactDetail:)
    //     forControlEvents:UIControlEventTouchUpInside];
    //
    //    cell.accessoryView = button;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Hide Keyboard
    [self.contactPickerView resignFirstResponder];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OTRBuddy * buddy = [self buddyAtIndexPath:indexPath];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    // This uses the custom cellView
    // Set the custom imageView
    UIImageView *checkboxImageView = (UIImageView *)[cell viewWithTag:104];
    UIImage *image;
    
    if ([self.selectedContacts containsObject:buddy]){ // contact is already selected so remove it from ContactPickerView
        //cell.accessoryType = UITableViewCellAccessoryNone;
        [self.selectedContacts removeObject:buddy];
        [self.contactPickerView removeContact:buddy];
        // Set checkbox to "unselected"
        image = [UIImage imageNamed:@"OTRIcon-checkbox-unselected"];
    } else {
        // Contact has not been selected, add it to THContactPickerView
        //cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [self.selectedContacts addObject:buddy];
        [self.contactPickerView addContact:buddy withName:buddy.username];
        // Set checkbox to "selected"
        image = [UIImage imageNamed:@"OTRIcon-checkbox-selected-green"];
    }
    
    // Enable Done button if total selected contacts > 0
    if(self.selectedContacts.count > 0) {
        barButton.enabled = TRUE;
    }
    else
    {
        barButton.enabled = FALSE;
    }
    
    // Update window title
    self.title = [NSString stringWithFormat:@"%@ (%lu)", ADD_MEMBERS_STRING, (unsigned long)self.selectedContacts.count];
    
    // Set checkbox image
    checkboxImageView.image = image;
    // Refresh the tableview
    [self.tableView reloadData];
}

#pragma mark - THContactPickerTextViewDelegate

- (void)contactPickerTextViewDidChange:(NSString *)textViewText {
    
    if ([textViewText length]) {
        
        textViewText = [NSString stringWithFormat:@"%@*",textViewText];
        
        NSMutableArray *tempSearchResults = [NSMutableArray new];
        [self.databaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
            [[transaction ext:OTRBuddyNameSearchDatabaseViewExtensionName] enumerateKeysAndObjectsMatching:textViewText usingBlock:^(NSString *collection, NSString *key, id object, BOOL *stop) {
                if ([object isKindOfClass:[OTRBuddy class]]) {
                    [tempSearchResults addObject:object];
                }
            }];
        } completionBlock:^{
            self.filteredContacts = tempSearchResults;
            [self.tableView reloadData];
        }];
    }
    else{
        [self.tableView reloadData];
    }
    
}


- (void)contactPickerDidResize:(THContactPickerView *)contactPickerView {
    //[self adjustTableViewFrame:YES];
}

- (void)contactPickerDidRemoveContact:(id)contact {
    [self.selectedContacts removeObject:contact];
    
    if([contact isKindOfClass:[OTRBuddy class]])
    {
        NSIndexPath *index = [self indexPathOfBuddy:(OTRBuddy *)contact];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:index];
        //cell.accessoryType = UITableViewCellAccessoryNone;
        
        // Enable Done button if total selected contacts > 0
        if(self.selectedContacts.count > 0) {
            barButton.enabled = TRUE;
        }
        else
        {
            barButton.enabled = FALSE;
        }
        
        // Set unchecked image
        UIImageView *checkboxImageView = (UIImageView *)[cell viewWithTag:104];
        UIImage *image;
        image = [UIImage imageNamed:@"OTRIcon-checkbox-unselected"];
        checkboxImageView.image = image;
        
        // Update window title
        self.title = [NSString stringWithFormat:@"%@ (%lu)", ADD_MEMBERS_STRING, (unsigned long)self.selectedContacts.count];
    }
}

- (void)removeAllContacts:(id)sender
{
    [self.contactPickerView removeAllContacts];
    [self.selectedContacts removeAllObjects];
    self.filteredContacts = self.contacts;
    [self.tableView reloadData];
}






// This opens the apple contact details view: ABPersonViewController
//TODO: make a THContactPickerDetailViewController
- (IBAction)viewContactDetail:(UIButton*)sender {
    
    /*ABRecordID personId = (ABRecordID)sender.tag;
    ABPersonViewController *view = [[ABPersonViewController alloc] init];
    view.addressBook = self.addressBookRef;
    view.personViewDelegate = self;
    view.displayedPerson = ABAddressBookGetPersonWithRecordID(self.addressBookRef, personId);*/
    
    
    //[self.navigationController pushViewController:view animated:YES];
}


- (void)done:(id)sender
{
    // TODO: send contact object
    
    if ([self.delegate respondsToSelector:@selector(controller:didSelectBuddies:)]) {
        [self.navigationController popViewControllerAnimated:YES];
        [self.delegate controller:self didSelectBuddies:self.selectedContacts];
    }
    else{
        
        [self.navigationController popViewControllerAnimated:YES];
        
        if(_rowDescriptor)
        {
            _rowDescriptor.value = self.selectedContacts;
            
        }
    }
    
}


#pragma - mark YapDatabaseViewUpdate

- (void)yapDatabaseDidUpdate:(NSNotification *)notification;
{
    // Process the notification(s),
    // and get the change-set(s) as applies to my view and mappings configuration.
    NSArray *notifications = [self.databaseConnection beginLongLivedReadTransaction];
    
    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;
    
    if ([self useSearchResults]) {
        return;
    }
    
    [[self.databaseConnection ext:OTRContactDatabaseViewExtensionName] getSectionChanges:&sectionChanges
                                                                              rowChanges:&rowChanges
                                                                        forNotifications:notifications
                                                                            withMappings:self.mappings];
    
    // No need to update mappings.
    // The above method did it automatically.
    
    if ([sectionChanges count] == 0 & [rowChanges count] == 0)
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
            case YapDatabaseViewChangeMove :
            case YapDatabaseViewChangeUpdate :
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

@end
