//
//  OTRCreatEventViewController.m
//  ChatSecure
//
//  Created by Diana Perez on 3/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//


#import <EventKitUI/EventKitUI.h>

#import "OTRCalendarViewController.h"
#import "MBProgressHUD.h"

#import "OTRCreateEventViewController.h"
#import "OTREventDetailViewController.h"

#import "YapDatabaseViewMappings.h"
#import "YapDatabaseConnection.h"
#import "OTRDatabaseManager.h"
#import "OTRDatabaseView.h"
#import "OTRCalendarController.h"
#import "OTRProtocolManager.h"

#import "OTRDateUtil.h"

#import "OTREvent.h"

#import "Strings.h"


@interface OTRCalendarViewController () <UITableViewDataSource, UITableViewDelegate, EKEventEditViewDelegate>

@property (nonatomic, strong) UIBarButtonItem * addBuddyButtonItem;

@property (nonatomic, strong) YapDatabaseViewMappings *daymappings;
@property (nonatomic, strong) YapDatabaseViewMappings *monthmappings;
@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;

@property (strong, nonatomic, readwrite) NSLayoutConstraint *calendarContentViewHeightConstraint;

@end

@implementation OTRCalendarViewController



- (instancetype)init
{
    if (self = [super init]) {
        
        //DDLogInfo(@"Account Dictionary: %@",[account accountDictionary]);
        
        //////////// TabBar Icon /////////
        UITabBarItem *tab1 = [[UITabBarItem alloc] init];
        [tab1 setImage:[UIImage imageNamed:@"OTRCalendarIcon"]];
        tab1.title = EVENTS_STRING;
        [self setTabBarItem:tab1];
        
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MBProgressHUD *loadingHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [loadingHUD setMode:MBProgressHUDModeIndeterminate];
    [loadingHUD setLabelText:@"Loading..."];
    
    self.navigationController.navigationBar.translucent = NO;
    
    
    
    self.addBuddyButtonItem =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addEventPressed:)];
    self.navigationItem.leftBarButtonItem = self.addBuddyButtonItem;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    //Cells
    
    
    [self setUpCalendar];
    [self setUpBarButtonItems];
    
    

    /*[self.currentDayTableView registerClass:[CGCalendarCell class] forCellReuseIdentifier:[OTRBuddyInfoCell reuseIdentifier]];*/
    
    self.databaseConnection = [[OTRDatabaseManager sharedInstance] newConnection];
    self.databaseConnection.name = NSStringFromClass([self class]);
    [self.databaseConnection beginLongLivedReadTransaction];
    
    
    
    
    NSDate *today = [NSDate date];
    self.daymappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[[OTRDateUtil curentDateStringFromDate:today withFormat:DATE_FORMAT]] view:OTREventDatabaseViewExtensionName];
    
    NSMutableArray *daysinMonth = [[NSMutableArray alloc] init];
    NSDate *firstDayMonth = [OTRDateUtil getFirstDayOfMonth:today];
    for(int i = 0; i < (int)[OTRDateUtil getNumberOfDaysInMonth:today]; i++)
    {
        NSDate *day = [OTRDateUtil getDate:firstDayMonth daysAhead:i];
        [daysinMonth addObject:[OTRDateUtil curentDateStringFromDate:day withFormat:DATE_FORMAT]];
        
    }
    
    self.monthmappings = [[YapDatabaseViewMappings alloc] initWithGroups:daysinMonth view:OTREventDatabaseViewExtensionName];
    
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.daymappings updateWithTransaction:transaction];
        [self.monthmappings updateWithTransaction:transaction];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:nil];
    
    
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}



- (void)addEventPressed:(id)sender
{
    
    OTRCreateEventViewController *viewController = [[OTRCreateEventViewController alloc] init];
    viewController.date = self.calendar.currentDateSelected;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:viewController];
    
    [self presentViewController:navController animated:YES completion:nil];
}


- (OTREvent *)eventForIndexPath:(NSIndexPath *)indexPath
{
    
    __block OTREvent *event = nil;
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        
        event = [[transaction extension:OTREventDatabaseViewExtensionName] objectAtIndexPath:indexPath withMappings:self.daymappings];
    }];
    
    return event;
}

#pragma mark UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([viewController isKindOfClass:[UITableViewController class]]) {
        
        UITableView *tblView= ((UITableViewController*)viewController).tableView;
        
        //Here you got the tableView now you can change everthing related to tableView.................
        UITableViewCell *cell=[tblView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:3]];
        cell.hidden = YES;
    }
}


#pragma mark EKEventEditViewControllerDelegate


- (void)eventEditViewController:(EKEventEditViewController *)controller didCompleteWithAction:(EKEventEditViewAction)action
{
    
}


- (EKCalendar *)eventEditViewControllerDefaultCalendarForNewEvents:(EKEventEditViewController *)controller
{
    EKCalendar *cal = nil;
    
    return cal;
}




#pragma mark -
#pragma mark Subview setup

- (void)setUpCalendar {
    
    self.calendar = [JTCalendar new];
    self.calendar.calendarAppearance.menuMonthTextFont = [UIFont systemFontOfSize:13.0f];
    self.calendar.calendarAppearance.menuMonthTextColor = [UIColor grayColor];
    self.calendar.calendarAppearance.monthBlock = ^NSString *(NSDate *date, JTCalendar *jt_calendar){
        NSCalendar *calendar = jt_calendar.calendarAppearance.calendar;
        NSDateComponents *comps = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth fromDate:date];
        NSInteger currentMonthIndex = comps.month;
        
        static NSDateFormatter *dateFormatter;
        if(!dateFormatter){
            dateFormatter = [NSDateFormatter new];
            dateFormatter.timeZone = jt_calendar.calendarAppearance.calendar.timeZone;
        }
        
        while(currentMonthIndex <= 0){
            currentMonthIndex += 12;
        }
        
        NSString *monthText = [[dateFormatter standaloneMonthSymbols][currentMonthIndex - 1] capitalizedString];
        
        return [NSString stringWithFormat:@"%ld %@", comps.year, monthText];
    };
    
    [self setUpMenuView];
    [self setUpContentView];
    [self setUpTableView];
    
    [self.calendar setMenuMonthsView:self.calendarMenuView];
    [self.calendar setContentView:self.calendarContentView];
    [self.calendar setDataSource:self];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self pushTodayButton:nil];
    });
}

- (void)setUpMenuView {
    self.calendarMenuView = [[JTCalendarMenuView alloc] initWithFrame:CGRectZero];
    self.calendarMenuView.translatesAutoresizingMaskIntoConstraints = NO;
    self.calendarMenuView.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.calendarMenuView];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.calendarMenuView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeTop
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.calendarMenuView
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.calendarMenuView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.calendarMenuView
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:0.0f
                                                           constant:25.0f]];
}

- (void)setUpContentView {
    self.calendarContentView = [[JTCalendarContentView alloc] initWithFrame:CGRectZero];
    self.calendarContentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.calendarContentView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.calendarContentView];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.calendarContentView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.calendarMenuView
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.calendarContentView
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.calendarContentView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    self.calendarContentViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.calendarContentView
                                                                            attribute:NSLayoutAttributeHeight
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:self.view
                                                                            attribute:NSLayoutAttributeHeight
                                                                           multiplier:0.0f
                                                                             constant:300.0f];
    [self.view addConstraint:self.calendarContentViewHeightConstraint];
}

- (void)setUpTableView {
    self.currentDayTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.currentDayTableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.currentDayTableView.dataSource = self;
    self.currentDayTableView.delegate = self;
    
    [self.view addSubview:self.currentDayTableView];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.currentDayTableView
                                                          attribute:NSLayoutAttributeTop
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.calendarContentView
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0f
                                                           constant:5.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.currentDayTableView
                                                          attribute:NSLayoutAttributeLeft
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeLeft
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.currentDayTableView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.currentDayTableView
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0f
                                                           constant:0.0f]];
}

- (void)setUpBarButtonItems {
    UIBarButtonItem *todayButton = [[UIBarButtonItem alloc] initWithTitle:@"Today" style:UIBarButtonItemStylePlain target:self action:@selector(pushTodayButton:)];
    UIBarButtonItem *changeModeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(pushChangeModeButton:)];
    
    [self.navigationItem setRightBarButtonItems:@[todayButton, changeModeButton]];
}



- (void)viewDidLayoutSubviews {
    [self.calendar repositionViews];
}

- (void)calendarDidLoadNextPage {
    [self loadEventsForDate:self.calendar.currentDate];
}

- (void)calendarDidLoadPreviousPage {
    [self loadEventsForDate:self.calendar.currentDate];
}

- (BOOL)calendarHaveEvent:(JTCalendar *)calendar date:(NSDate *)date
{
    if([self.monthmappings numberOfItemsInGroup:[OTRDateUtil curentDateStringFromDate:date withFormat:DATE_FORMAT]] > 0)
    {
        return true;
    }
    return false;
}

- (void)calendarDidDateSelected:(JTCalendar *)calendar date:(NSDate *)date {
    // Check if all the events on this day have loaded
    
    MBProgressHUD *progressHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [progressHUD setMode:MBProgressHUDModeIndeterminate];
    [progressHUD setLabelText:@"Loading..."];
    
    self.daymappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[[OTRDateUtil curentDateStringFromDate:date withFormat:DATE_FORMAT]] view:OTREventDatabaseViewExtensionName];
    
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.daymappings updateWithTransaction:transaction];
        [self.monthmappings updateWithTransaction:transaction];
    }];

    dispatch_async(dispatch_get_main_queue(), ^{
    
        [self.currentDayTableView reloadData];
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });
    
}




#pragma mark -
#pragma mark IBActions

- (void)pushTodayButton:(id)sender {
    NSDate *currentDate = [NSDate date];
    
    [self.calendar setCurrentDateSelected:currentDate];
    [self.calendar setCurrentDate:currentDate];
    [self calendarDidDateSelected:self.calendar date:currentDate];;
}

- (void)pushChangeModeButton:(id)sender {
    self.calendar.calendarAppearance.isWeekMode = !self.calendar.calendarAppearance.isWeekMode;
    
    [self transitionCalendarMode];
}

- (void)transitionCalendarMode {
    CGFloat newHeight = 300.0f;
    
    if(self.calendar.calendarAppearance.isWeekMode){
        newHeight = 75.0f;
    }
    
    [UIView animateWithDuration:.5
                     animations:^{
                         self.calendarContentViewHeightConstraint.constant = newHeight;
                         [self.view layoutIfNeeded];
                     }];
    
    [UIView animateWithDuration:.25
                     animations:^{
                         self.calendarContentView.layer.opacity = 0;
                     }
                     completion:^(BOOL finished) {
                         [self.calendar reloadAppearance];
                         
                         [UIView animateWithDuration:.25
                                          animations:^{
                                              self.calendarContentView.layer.opacity = 1;
                                          }];
                     }];
}


#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.daymappings numberOfSections];
}




- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.daymappings numberOfItemsInSection:section];
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    OTREvent *event = [self eventForIndexPath:indexPath];
    
    [cell.textLabel setText:event.title];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OTREvent *event = [self eventForIndexPath:indexPath];
    
    __block OTREvent *eventMajor = nil;
    [[OTRDatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        eventMajor = [OTREvent fetchObjectWithUniqueID:event.eventId transaction:transaction];
        
    }];
    
    if(eventMajor)
    {
        OTREventDetailViewController *detailEventViewController = [[OTREventDetailViewController alloc] init];
        detailEventViewController.event = eventMajor;
        detailEventViewController.hidesBottomBarWhenPushed = YES;
        
        [self.navigationController pushViewController:detailEventViewController animated:YES];
        
    }
}


- (void)loadEventsForDate:(NSDate *)currentDate
{
    // Show a loading HUD (https://github.com/jdg/MBProgressHUD)
    MBProgressHUD *loadingHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [loadingHUD setMode:MBProgressHUDModeIndeterminate];
    [loadingHUD setLabelText:@"Loading..."];
    
    NSMutableArray *daysinMonth = [[NSMutableArray alloc] init];
    NSDate *firstDayMonth = [OTRDateUtil getFirstDayOfMonth:currentDate];
    for(int i = 0; i < (int)[OTRDateUtil getNumberOfDaysInMonth:currentDate]; i++)
    {
        NSDate *day = [OTRDateUtil getDate:firstDayMonth daysAhead:i];
        [daysinMonth addObject:[OTRDateUtil curentDateStringFromDate:day withFormat:DATE_FORMAT]];
        
    }
    
    self.monthmappings = [[YapDatabaseViewMappings alloc] initWithGroups:daysinMonth view:OTREventDatabaseViewExtensionName];
    
    
    self.daymappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[[OTRDateUtil curentDateStringFromDate:currentDate withFormat:DATE_FORMAT]] view:OTREventDatabaseViewExtensionName];
    
    
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.daymappings updateWithTransaction:transaction];
        [self.monthmappings updateWithTransaction:transaction];
    }];

    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.currentDayTableView reloadData];
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });

}


- (void) yapDatabaseModified:(NSNotification *)notification
{
    // Process the notification(s),
    // and get the change-set(s) as applies to my view and mappings configuration.
    NSArray *notifications = [self.databaseConnection beginLongLivedReadTransaction];
    
    
    
    NSArray *daySectionChanges = nil;
    NSArray *dayRowChanges = nil;
    [[self.databaseConnection ext:OTREventDatabaseViewExtensionName] getSectionChanges:&daySectionChanges
                                                                                     rowChanges:&dayRowChanges
                                                                               forNotifications:notifications
                                                                                   withMappings:self.daymappings];
   
    NSArray *monthSectionChanges = nil;
    NSArray *monthRowChanges = nil;
    [[self.databaseConnection ext:OTREventDatabaseViewExtensionName] getSectionChanges:&monthSectionChanges
                                                                              rowChanges:&monthRowChanges
                                                                        forNotifications:notifications
     
                                                                            withMappings:self.monthmappings];
    
    if (![daySectionChanges count] == 0 || ![dayRowChanges count] == 0)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.currentDayTableView reloadData];
        });
    }
    

    if ([monthSectionChanges count] || [monthRowChanges count]) {
        [self.calendar reloadData];;
    }
    
}


@end
