//
//  OTRCreatEventViewController.m
//  ChatSecure
//
//  Created by Diana Perez on 3/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRCreateEventViewController.h"
#import "XLForm.h"
#import "OTRContactPickerViewController.h"
#import "OTRCalendarController.h"
#import "OTREvent.h"
#import "DateAndTimeValueTrasformer.h"
#import "OTRProtocol.h"
#import "OTRDateUtil.h"
#import "Strings.h"
#import "OTRDatabaseManager.h"
#import "OTRSettingsManager.h"
#import "OTRProtocolManager.h"
#import "OTREventValueTransformer.h"
#import "OTRBuddyValueTransformer.h"

#import "OTRBuddy.h"
#import "OTRAccount.h"
#import "OTRSubEvent.h"
#import "OTRMessage.h"
#import "OTRFileItem.h"


//#import "OTRFileTransferController.h"
//#import "OTRFileTransferUtil.h"
#define TITLE_TAG @"title"
#define LOCATION_TAG @"location"
#define STARTS_TAG @"starts"
#define ENDS_TAG @"ends"
#define INVITEES_TAG @"invitees"
#define NOTES_TAG @"notes"
#define ALL_DAY_TAG @"allDay"
#define REPEAT_TAG @"repeat"
#define TRAVEL_TIME_TAG @"travelTime"
#define ALERT_TAG @"alert"
#define SHOW_AS_TAG @"showAs"
#define URL_TAG @"url"
#define SECOND_ALERT_TAG @"secondAlert"
#define CALENDAR_TAG @"calendar"

@import EventKit;
@import EventKitUI;

@interface OTRCreateEventViewController ()

@property (nonatomic, strong) XLFormDescriptor *form;

@property (nonatomic, strong) OTRAccount *account;

@end

@implementation OTRCreateEventViewController

@dynamic form;

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initializeForm];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initializeForm];
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.account = [[OTRAccountsManager allAutoLoginAccounts] objectAtIndex:0];
    
    //[self.view setTintColor:[UIColor redColor]];
    //[self.navigationController.view setTintColor:[UIColor redColor]];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPressed:)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(savePressed:)];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
}




- (void)initializeForm
{
    
    
    XLFormDescriptor * form;
    XLFormSectionDescriptor * section;
    XLFormRowDescriptor * row;
    
    form = [XLFormDescriptor formDescriptorWithTitle:ADD_EVENT_STRING];
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    // Title
    row = [XLFormRowDescriptor formRowDescriptorWithTag:TITLE_TAG rowType:XLFormRowDescriptorTypeText];
    [row.cellConfigAtConfigure setObject:TITLE_STRING forKey:@"textField.placeholder"];
    [section addFormRow:row];
    
    // Location
    row = [XLFormRowDescriptor formRowDescriptorWithTag:LOCATION_TAG rowType:XLFormRowDescriptorTypeText];
    [row.cellConfigAtConfigure setObject:LOCATION_STRING forKey:@"textField.placeholder"];
    [section addFormRow:row];
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    
    //All Day
    row = [XLFormRowDescriptor formRowDescriptorWithTag:ALL_DAY_TAG rowType:XLFormRowDescriptorTypeBooleanSwitch title:ALLDAY_STRING];
    [section addFormRow:row];

    
    // Starts
    row = [XLFormRowDescriptor formRowDescriptorWithTag:STARTS_TAG rowType:XLFormRowDescriptorTypeDateTimeInline title:START_DATE_STRING];
    [section addFormRow:row];
    
    // Ends
    row = [XLFormRowDescriptor formRowDescriptorWithTag:ENDS_TAG rowType:XLFormRowDescriptorTypeDateTimeInline title:ENDS_DATE_STRING];
    [section addFormRow:row];
    
    //Repeat
    row = [XLFormRowDescriptor formRowDescriptorWithTag:REPEAT_TAG rowType:XLFormRowDescriptorTypeSelectorPush title:REPEAT_STRING];
    row.selectorTitle = REPEAT_STRING;
    row.value = [XLFormOptionsObject formOptionsObjectWithValue:@(OTRRepeatNone) displayText:NEVER_STRING];
    row.selectorOptions = @[[XLFormOptionsObject formOptionsObjectWithValue:@(OTRRepeatNone) displayText:NEVER_STRING],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(OTRRepeatEveryDay) displayText:EVERY_DAY_STRING],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(OTRRepeatEveryWeek) displayText:EVERY_WEEK_STRING],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(OTRRepeatEveryTwoWeeks) displayText:EVERY_TWO_WEEKS_STRING],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(OTRRepeatEveryMonth) displayText:EVERY_MONTH_STRING],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(OTRRepeatEveryYear) displayText:EVERY_YEAR_STRING],
                            ];
    [section addFormRow:row];

    
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    //Calendar
    
    if([OTRProtocolManager sharedInstance].calendarManager.permission)
    {
        row = [XLFormRowDescriptor formRowDescriptorWithTag:CALENDAR_TAG rowType:XLFormRowDescriptorTypeSelectorPush title:CALENDAR_STRING];
        row.valueTransformer = [OTREventValueTransformer class];
        row.value = [[[OTRProtocolManager sharedInstance].calendarManager fetchAllCalendars] objectAtIndex:0];
        row.selectorOptions = [[OTRProtocolManager sharedInstance].calendarManager fetchAllCalendars];
        [section addFormRow:row];
    }
    
    // Invites
    row = [XLFormRowDescriptor formRowDescriptorWithTag:INVITEES_TAG rowType:XLFormRowDescriptorTypeMultipleSelector title:INVITEES_STRING];
    row.noValueDisplayText = NONE_STRING;
    row.valueTransformer = [OTRBuddyValueTransformer class];
    row.action.viewControllerClass = [OTRContactPickerViewController class];
    [section addFormRow:row];
    
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    // Alert
    row = [XLFormRowDescriptor formRowDescriptorWithTag:ALERT_TAG rowType:XLFormRowDescriptorTypeSelectorPush title:ALERT_STRING];
    row.value = [XLFormOptionsObject formOptionsObjectWithValue:@(OTRAlertNone) displayText:NONE_STRING];
    row.selectorTitle = EVENT_ALERT_STRING;
    row.selectorOptions = @[[XLFormOptionsObject formOptionsObjectWithValue:@(OTRAlertNone) displayText:NONE_STRING],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(OTRAlertAtTimeOfEvent) displayText:AT_TIME_OF_EVENT_STRING],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(OTRAlertFiveMinutesBefore) displayText:FIVE_MINUTES_BEFORE_STRING],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(OTRAlertFifteenMinutesBefore) displayText:FIFTEEN_MINUTES_BEFORE_STRING],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(OTRAlertThirtyMinutesBefore) displayText:THIRTY_MINUTES_BEFORE_STRING],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(OTRAlertOneHourBefore) displayText:ONE_HOUR_BEFORE_STRING],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(OTRAlertTwoHoursBefore) displayText:TWO_HOURS_BEFORE_STRING],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(OTRAlertOneDayBefore) displayText:ONE_DAY_BEFORE_STRING],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(OTRAlertTwoDaysBefore) displayText:TWO_DAYS_BEFORE_STRING],
                            ];
    [section addFormRow:row];
    
    // Show As
    row = [XLFormRowDescriptor formRowDescriptorWithTag:SHOW_AS_TAG rowType:XLFormRowDescriptorTypeSelectorPush title:SHOW_AS_STRING];
    row.value = [XLFormOptionsObject formOptionsObjectWithValue:@(OTRShowAsBusy) displayText:BUSY_STRING];
    row.selectorTitle = SHOW_AS_STRING;
    row.selectorOptions = @[[XLFormOptionsObject formOptionsObjectWithValue:@(OTRShowAsBusy) displayText:BUSY_STRING],
                            [XLFormOptionsObject formOptionsObjectWithValue:@(OTRShowAsFree) displayText:FREE_STRING]];
    [section addFormRow:row];
    
    section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    // URL
    row = [XLFormRowDescriptor formRowDescriptorWithTag:URL_TAG rowType:XLFormRowDescriptorTypeURL];
    [row.cellConfigAtConfigure setObject:URL_STRING forKey:@"textField.placeholder"];
    [section addFormRow:row];
    
    // Notes
    row = [XLFormRowDescriptor formRowDescriptorWithTag:NOTES_TAG rowType:XLFormRowDescriptorTypeTextView];
    [row.cellConfigAtConfigure setObject:NOTES_STRING forKey:@"textView.placeholder"];
    [section addFormRow:row];
    
    
    self.form = form;
}


- (void)setDate:(NSDate *)date
{
    _date = date;
    
    for (XLFormSectionDescriptor * section in self.form.formSections) {
        if (!section.isMultivaluedSection){
            for (XLFormRowDescriptor * row in section.formRows) {
                if (row.tag && [row.tag isEqualToString:STARTS_TAG]){
                    row.value = self.date;
                }
                else if(row.tag && [row.tag isEqualToString:ENDS_TAG]){
                    row.value = [NSDate dateWithTimeInterval:60*60 sinceDate:self.date];
                }

            }
        }
        
    }

}






#pragma mark - XLFormDescriptorDelegate

-(void)formRowDescriptorValueHasChanged:(XLFormRowDescriptor *)rowDescriptor oldValue:(id)oldValue newValue:(id)newValue
{
    BOOL success = NO;
    
    [super formRowDescriptorValueHasChanged:rowDescriptor oldValue:oldValue newValue:newValue];
    
    if ([rowDescriptor.tag isEqualToString:ALERT_TAG]){
        if ([[rowDescriptor.value valueData] isEqualToNumber:@(0)] == NO && [[oldValue valueData] isEqualToNumber:@(0)]){
            
            XLFormRowDescriptor * newRow = [rowDescriptor copy];
            newRow.tag = SECOND_ALERT_TAG;
            newRow.title = SECOND_ALERT_STRING;
            newRow.value = [XLFormOptionsObject formOptionsObjectWithValue:@(OTRAlertNone) displayText:NONE_STRING];;
            [self.form addFormRow:newRow afterRow:rowDescriptor];
        }
        else if ([[oldValue valueData] isEqualToNumber:@(0)] == NO && [[newValue valueData] isEqualToNumber:@(0)]){
            [self.form removeFormRowWithTag:SECOND_ALERT_TAG];
        }
    }
    else if ([rowDescriptor.tag isEqualToString:ALL_DAY_TAG]){
        XLFormRowDescriptor * startDateDescriptor = [self.form formRowWithTag:STARTS_TAG];
        XLFormRowDescriptor * endDateDescriptor = [self.form formRowWithTag:ENDS_TAG];
        XLFormDateCell * dateStartCell = (XLFormDateCell *)[[self.form formRowWithTag:STARTS_TAG] cellForFormController:self];
        XLFormDateCell * dateEndCell = (XLFormDateCell *)[[self.form formRowWithTag:ENDS_TAG] cellForFormController:self];
        if ([[rowDescriptor.value valueData] boolValue] == YES){
            startDateDescriptor.valueTransformer = [DateValueTrasformer class];
            endDateDescriptor.valueTransformer = [DateValueTrasformer class];
            [dateStartCell setFormDatePickerMode:XLFormDateDatePickerModeDate];
            [dateEndCell setFormDatePickerMode:XLFormDateDatePickerModeDate];
        }
        else{
            startDateDescriptor.valueTransformer = [DateTimeValueTrasformer class];
            endDateDescriptor.valueTransformer = [DateTimeValueTrasformer class];
            [dateStartCell setFormDatePickerMode:XLFormDateDatePickerModeDateTime];
            [dateEndCell setFormDatePickerMode:XLFormDateDatePickerModeDateTime];
        }
        [self updateFormRow:startDateDescriptor];
        [self updateFormRow:endDateDescriptor];
    }
    else if ([rowDescriptor.tag isEqualToString:STARTS_TAG]){
        XLFormRowDescriptor * startDateDescriptor = [self.form formRowWithTag:STARTS_TAG];
        XLFormRowDescriptor * endDateDescriptor = [self.form formRowWithTag:ENDS_TAG];
        if ([startDateDescriptor.value compare:endDateDescriptor.value] == NSOrderedDescending) {
            // startDateDescriptor is later than endDateDescriptor
            endDateDescriptor.value =  [[NSDate alloc] initWithTimeInterval:(60*60) sinceDate:startDateDescriptor.value];
            [endDateDescriptor.cellConfig removeObjectForKey:@"detailTextLabel.attributedText"];
            [self updateFormRow:endDateDescriptor];
        }
    }
    else if ([rowDescriptor.tag isEqualToString:ENDS_TAG]){
        XLFormRowDescriptor * startDateDescriptor = [self.form formRowWithTag:STARTS_TAG];
        XLFormRowDescriptor * endDateDescriptor = [self.form formRowWithTag:ENDS_TAG];
        XLFormDateCell * dateEndCell = (XLFormDateCell *)[endDateDescriptor cellForFormController:self];
        if ([startDateDescriptor.value compare:endDateDescriptor.value] == NSOrderedDescending) {
            // startDateDescriptor is later than endDateDescriptor
            [dateEndCell update]; // force detailTextLabel update
            NSDictionary *strikeThroughAttribute = [NSDictionary dictionaryWithObject:@1
                                                                               forKey:NSStrikethroughStyleAttributeName];
            NSAttributedString* strikeThroughText = [[NSAttributedString alloc] initWithString:dateEndCell.detailTextLabel.text attributes:strikeThroughAttribute];
            [endDateDescriptor.cellConfig setObject:strikeThroughText forKey:@"detailTextLabel.attributedText"];
            [self updateFormRow:endDateDescriptor];
        }
        else{
            [endDateDescriptor.cellConfig removeObjectForKey:@"detailTextLabel.attributedText"];
            [self updateFormRow:endDateDescriptor];
        }
    }
    else if ([rowDescriptor.tag isEqualToString:TITLE_TAG]){
        if([((NSString *)rowDescriptor.value) length] > 0)
        {
            success = YES;
        }
    }
    
    if(success)
    {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

-(IBAction)cancelPressed:(UIBarButtonItem * __unused)button
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


-(IBAction) savePressed:(UIBarButtonItem * __unused)button
{
    NSArray * validationErrors = [self formValidationErrors];
    
    if (validationErrors.count > 0)
    {
        [self showFormValidationError:[validationErrors firstObject]];
        return;
    }
    
    [self.tableView endEditing:YES];
    
    
    NSMutableDictionary *dir = [[self getFormValues] copy];
    
    OTREvent *event = [[OTREvent alloc] initWithTitle:[dir objectForKey:TITLE_TAG]];
    event.accountUniqueId = self.account.uniqueId;
    
    event.startsDate = [dir objectForKey:STARTS_TAG];
    event.endsDate = [dir objectForKey:ENDS_TAG];
    event.location = [dir objectForKey:LOCATION_TAG];
    event.notes = [dir objectForKey:NOTES_TAG];
    event.allDay = [dir objectForKey:ALL_DAY_TAG];
    event.repeat = [((XLFormOptionsObject *)[dir objectForKey:REPEAT_TAG]).formValue intValue];
    event.calendarIdentifier = ((EKCalendar *)[dir objectForKey:CALENDAR_TAG]).calendarIdentifier;
    event.invitees = [dir objectForKey:INVITEES_TAG];
    event.alert = [((XLFormOptionsObject *)[dir objectForKey:ALERT_TAG]).formValue intValue];
    event.secondAlert = [((XLFormOptionsObject *)[dir objectForKey:SECOND_ALERT_TAG]).formValue intValue];
    event.showAs = [((XLFormOptionsObject *)[dir objectForKey:SHOW_AS_TAG]).formValue intValue];
    event.url = [dir objectForKey:URL_TAG];

    [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        
        for(int i = 0; i <= (int)[OTRDateUtil numberOfDaysFrom:event.startsDate until:event.endsDate]; i++)
        {
            
            OTRSubEvent *event2 = [[OTRSubEvent alloc] initWithTitle:event.title];
            event2.accountUniqueId = self.account.uniqueId;
            
            event2.startsDate = event.startsDate;
            event2.endsDate = event.endsDate;
            event2.location = event.location;
            event2.notes = event.notes;
            event.allDay = [dir objectForKey:ALL_DAY_TAG];
            event.repeat = [((XLFormOptionsObject *)[dir objectForKey:REPEAT_TAG]).formValue intValue];
            event.calendarIdentifier = ((EKCalendar *)[dir objectForKey:CALENDAR_TAG]).calendarIdentifier;
            event.invitees = [dir objectForKey:INVITEES_TAG];
            event.alert = [((XLFormOptionsObject *)[dir objectForKey:ALERT_TAG]).formValue intValue];
            event.secondAlert = [((XLFormOptionsObject *)[dir objectForKey:SECOND_ALERT_TAG]).formValue intValue];
            event.showAs = [((XLFormOptionsObject *)[dir objectForKey:SHOW_AS_TAG]).formValue intValue];
            event.url = [dir objectForKey:URL_STRING];
            
            event2.day = [OTRDateUtil getDate:event.startsDate daysAhead:i];
            event2.eventId = event.uniqueId;
            [event2 saveWithTransaction:transaction];
        }
        
    } completionBlock:^{
        
        /*OTRFileTransferController *fileTransfer = [[OTRFileTransferController alloc] initWithPath:resu andDelegate:self];
        [fileTransfer handleSendDelete:false andDelete:false];*/
        
        NSURL *url = [[OTRProtocolManager sharedInstance].calendarManager addEventAt:event];
        if (url) {
            //TODO send file
            __block OTRFileItem *fileItem = [OTRFileItem fileItemWithFileURL:url];
            
            if(event.invitees && [event.invitees count] > 0)
            {
                for(OTRChatter *chatter in event.invitees)
                {
                    __block OTRMessage *message = [[OTRMessage alloc] init];
                    message.read = YES;
                    message.incoming = NO;
                    message.mediaItemUniqueId = fileItem.uniqueId;
                    message.chatterUniqueId = chatter.uniqueId;
                    message.transportedSecurely = YES;
                    
                    BOOL service = [OTRSettingsManager boolForOTRSettingKey:kOTRSettingKeyServiceUse];
                    
                    if (!service) {
                        [[OTRProtocolManager sharedInstance].encryptionManager.dataHandler sendFileWithURL:url username:chatter.username accountName:self.account.username protocol:kOTRProtocolTypeXMPP tag:message];
                    }
                    else
                    {
                        [[OTRProtocolManager sharedInstance].dataManager sendFileWithURL:url username:chatter.username accountName:self.account.username protocol:kOTRProtocolTypeXMPP tag:message];
                    }
                }
            }
            
            [[OTRDatabaseManager sharedInstance].readWriteDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                event.filePath = url;
                [event saveWithTransaction:transaction];
                
            }];
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
        
    }];
    
}



- (NSMutableDictionary *)getFormValues
{
    NSMutableDictionary * result = [NSMutableDictionary dictionary];
    for (XLFormSectionDescriptor * section in self.form.formSections) {
        if (!section.isMultivaluedSection){
            for (XLFormRowDescriptor * row in section.formRows) {
                if (row.tag && ![row.tag isEqualToString:@""]){
                    [result setObject:(row.value ?: [NSNull null]) forKey:row.tag];
                }
            }
        }
        else{
            NSMutableArray * multiValuedValuesArray = [NSMutableArray new];
            for (XLFormRowDescriptor * row in section.formRows) {
                if (row.value){
                    [multiValuedValuesArray addObject:row.value];
                }
            }
            [result setObject:multiValuedValuesArray forKey:section.multivaluedTag];
        }
    }
    return result;
}


@end

