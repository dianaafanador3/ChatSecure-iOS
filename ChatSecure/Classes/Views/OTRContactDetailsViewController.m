//
//  OTRContactDetailView.m
//  ChatSecure
//
//  Created by IN2 on 01/07/15.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//
//

#import "OTRContactDetailsViewController.h"
#import "XLForm.h"
#import "OTRProfileInfoCell.h"
#import "OTRProfileButtonsCell.h"
#import "Strings.h"
#import "OTRDatabaseManager.h"

#import "OTRChatter.h"
#import "XLFormViewController+ChatSecure.h"



#define AVATAR_IMAGE_TAG @"avatarImage"
#define NAME_TAG @"name"
#define BUTTONS_TAG @"buttons"
#define CLEAR_CHAR_BUTTON_TAG @"clearChatButton"


@interface OTRContactDetailsViewController ()

@property (nonatomic, strong) XLFormDescriptor *form;

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;

@end

@implementation OTRContactDetailsViewController

@dynamic form;

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initializeForm];
    }
    return self;
}

- (instancetype)initWithChatter:(OTRChatter *)chatter
{
    self = [super init];
    if (self) {
        self.chatter = chatter;
        [self initializeForm];
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = CONTACT_INFO_STRING;
    
    self.databaseConnection = [[OTRDatabaseManager sharedInstance] newConnection];
    self.databaseConnection.name = NSStringFromClass([self class]);
    [self.databaseConnection beginLongLivedReadTransaction];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:nil];
    
}


- (void)initializeForm
{

    XLFormDescriptor * form;
    XLFormSectionDescriptor * section;
    XLFormRowDescriptor * row;
    
    
    form = [XLFormDescriptor formDescriptor];
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    //Avatar Image
    row = [XLFormRowDescriptor formRowDescriptorWithTag:AVATAR_IMAGE_TAG rowType:XLFormRowDescriptorTypeProfileInfo];
    row.value = self.chatter;
    [section addFormRow:row];
    
    
    // Buttons
    row = [XLFormRowDescriptor formRowDescriptorWithTag:BUTTONS_TAG rowType:XLFormRowDescriptorTypeProfileButtons];
    [section addFormRow:row];
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];

    // Display Name
    row = [XLFormRowDescriptor formRowDescriptorWithTag:NAME_TAG rowType:XLFormRowDescriptorTypeText];
    row.disabled = @YES;
    row.title = self.chatter.displayName;
    [row.cellConfig setObject:[UIColor blackColor] forKey:@"textLabel.color"];

    [section addFormRow:row];
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    //Button Clear Chat
    row = [XLFormRowDescriptor formRowDescriptorWithTag:CLEAR_CHAR_BUTTON_TAG rowType:XLFormRowDescriptorTypeButton];
    row.title = CLEAR_CHAT_STRING;
    [row.cellConfig setObject:[UIColor redColor] forKey:@"textLabel.color"];
    [section addFormRow:row];

    
    
    self.form = form;
}



#pragma mark - XLFormDescriptorDelegate

-(void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)rowDescriptor oldValue:(id)oldValue newValue:(id)newValue
{
   
}




-(IBAction) clearChatPressed:(UIBarButtonItem * __unused)button
{
    
    
}



- (void)refreshProfileValues
{
   
    for (XLFormSectionDescriptor * section in self.form.formSections) {
        
        for (XLFormRowDescriptor * row in section.formRows) {
            if (row.tag && [row.tag isEqualToString:AVATAR_IMAGE_TAG]){
                row.value = self.chatter;
                
            }
        }
    }

}


- (void)yapDatabaseModified:(NSNotification *)notification
{
    // Process the notification(s),
    // and get the change-set(s) as applies to my view and mappings configuration.
    NSArray *notifications = [self.databaseConnection beginLongLivedReadTransaction];
    
    //TODO check if the view is not visible
    // If the view isn't visible, we might decide to skip the UI animation stuff.
    //    if ([self viewIsNotVisible])
    //    {
    //        // Since we moved our databaseConnection to a new commit,
    //        // we need to update the mappings too.
    //        [self.uiDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
    //            [self.messageMappings updateWithTransaction:transaction];
    //        }];
    //        return;
    //    }
    
    
    BOOL buddyChanged = [self.databaseConnection hasChangeForKey:self.chatter.uniqueId inCollection:[OTRChatter collection] inNotifications:notifications];
    if (buddyChanged)
    {
        __block OTRChatter *updatedChatter = nil;
        [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            updatedChatter = [OTRChatter fetchObjectWithUniqueID:self.chatter.uniqueId transaction:transaction];
        }];
        
        self.chatter = updatedChatter;
        [self refreshProfileValues];
    }
    
    // When deleting messages/buddies we shouldn't animate the changes
    if (!self.chatter) {
        return;
    }
    
    
    [self.tableView reloadData];
}

@end

