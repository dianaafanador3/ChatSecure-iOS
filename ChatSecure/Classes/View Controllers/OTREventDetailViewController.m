//
//  OTRCreatEventViewController.m
//  ChatSecure
//
//  Created by Diana Perez on 3/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//


#import "OTREventDetailViewController.h"

#import "OTREvent.h"
#import "OTRProtocolManager.h"
#import <EventKit/EventKit.h>
#import "Strings.h"

#import "ContentTableViewStringCell.h"
#import "ContentTableViewCell.h"

static NSString *kContentTableStringIdentifier = @"ContentTable.String";

@interface OTREventDetailViewController ()

@property (nonatomic, readwrite) BOOL isDisplaying;

@end

@implementation OTREventDetailViewController

- (instancetype)init {
    self = [super init];
    
    if (self) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit {
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.itemCellInsets = UIEdgeInsetsMake(10.0, 20.0, 10.0, 5.0);
    self.itemCellBackgroundColor = [UIColor clearColor];
    self.itemCellTextAttributes = @{NSFontAttributeName : [UIFont systemFontOfSize:18.0]};
    self.itemCellLinkAttributes = @{NSFontAttributeName : [UIFont systemFontOfSize:18.0], NSForegroundColorAttributeName : [UIColor colorWithRed:54/255.0 green:136/255.0 blue:251/255.0 alpha:1.0]};
    self.itemCellContentMode = UIViewContentModeScaleAspectFit;
    self.items = @[];
    
    [self.tableView registerClass:[ContentTableViewStringCell class] forCellReuseIdentifier:kContentTableStringIdentifier];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editPressed:)];
    
    [self addDeleteButton];
    
}


- (void)setEvent:(OTREvent *)event
{
    
    NSString *string = [NSString stringWithFormat:@"%@ \n%@ \n\n%@ \n%@ \n%@", event.title, event.location, [self stringWithDate:event.startsDate withAllDay:event.allDay], [NSDateFormatter localizedStringFromDate:event.endsDate dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle], [self getRepeatString:event.repeat]];
    NSMutableAttributedString *titleString = [[NSMutableAttributedString alloc] initWithString:string];
    
    NSRange rangeTitle = [string rangeOfString:event.title];
    NSRange rangeLocation = [string rangeOfString:event.location];
    NSRange rangeStartDate = [string rangeOfString:[self stringWithDate:event.startsDate withAllDay:event.allDay]];
    NSRange rangeEndDate = [string rangeOfString:[NSDateFormatter localizedStringFromDate:event.endsDate dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle]];
    
    NSInteger strLength = [string length];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:6];
    [titleString addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, strLength)];
     
    [titleString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:18.0] range:rangeTitle];
    [titleString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:rangeLocation];
    [titleString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15.0] range:rangeLocation];
    [titleString addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:rangeStartDate];
    [titleString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15.0] range:rangeStartDate];
    [titleString addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:rangeEndDate];
    [titleString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15.0] range:rangeEndDate];
    
    
    NSString *calendar = [[OTRProtocolManager sharedInstance].calendarManager calendarForIdentifier:event.calendarIdentifier].title;
    
    NSAttributedString *notesString = [[NSAttributedString alloc] initWithString:@"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum." attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:10.0], NSForegroundColorAttributeName : [UIColor darkGrayColor]}];

    
    self.items = @[titleString, calendar, notesString];

}


-(NSString *)getRepeatString:(OTRRepeatStates)repeat
{
    NSString *repeatString = nil;
    switch (repeat)
    {
        case 0:
            break;
        case 1:
            repeatString = [NSString stringWithFormat:@"%@ %@", REPEATS_STRING, DAILY_STRING];
            break;
        case 2:
            repeatString = [NSString stringWithFormat:@"%@ %@", REPEATS_STRING, WEEKLY_STRING];
            break;
        case 3:
            repeatString = [NSString stringWithFormat:@"%@ %@", REPEATS_STRING, [EVERY_TWO_WEEKS_STRING lowercaseString]];
            break;
        case 4:
            repeatString = [NSString stringWithFormat:@"%@ %@", REPEATS_STRING, MONTHLY_STRING];
            break;
        case 5:
            repeatString = [NSString stringWithFormat:@"%@ %@", REPEATS_STRING, YEARLY_STRING];
            break;
    }
    
    return repeatString;
}

-(NSString *)stringWithDate:(NSDate *)date withAllDay:(BOOL)allDay
{
    if(allDay)
        return  [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
    else
        return  [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.isDisplaying = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    self.isDisplaying = NO;
}


-(IBAction) editPressed:(UIBarButtonItem * __unused)button
{
}


-(IBAction) deleteButtonTapped:(UIBarButtonItem * __unused)button
{
    
}

#pragma mark - setters

- (void)setItemCellInsets:(UIEdgeInsets)itemCellInsets {
    _itemCellInsets = itemCellInsets;
    
    if (self.isDisplaying) {
        [self.tableView reloadData];
    }
}

- (void)setItemCellBackgroundColor:(UIColor *)itemCellBackgroundColor {
    _itemCellBackgroundColor = itemCellBackgroundColor;
    
    if (self.isDisplaying) {
        [self.tableView reloadData];
    }
}

- (void)setItemCellTextAttributes:(NSDictionary *)itemCellTextAttributes {
    _itemCellTextAttributes = itemCellTextAttributes;
    
    if (self.isDisplaying) {
        [self.tableView reloadData];
    }
}

- (void)setItemCellContentMode:(UIViewContentMode)itemCellContentMode {
    _itemCellContentMode = itemCellContentMode;
    
    if (self.isDisplaying) {
        [self.tableView reloadData];
    }
}

- (void)setItems:(NSArray *)items {
    _items = items;
    
    if (self.isDisplaying) {
        [self.tableView reloadData];
    }
}

- (void)setEmptyPlaceholderView:(UIView *)emptyPlaceholderView {
    _emptyPlaceholderView = emptyPlaceholderView;
    
    if (self.isDisplaying && self.items.count == 0) {
        [self.tableView reloadData];
    }
}

#pragma mark - table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.tableView.style == UITableViewStylePlain || self.items.count == 0) {
        return 1;
    }
    
    return self.items.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.tableView.style == UITableViewStyleGrouped ||  self.items.count == 0) {
        return 1;
    }
    
    return self.items.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.items.count == 0) {
        return 100.0;
    }
    
    NSInteger itemIndex = tableView.style == UITableViewStylePlain ? indexPath.row : indexPath.section;
    NSObject *item = self.items[itemIndex];
    
    if ([item isKindOfClass:[NSString class]] ) {
        NSString *stringItem = (NSString *)item;
        CGSize tableSize = UIEdgeInsetsInsetRect(tableView.frame, tableView.contentInset).size;
        
        CGSize stringItemSize = [stringItem boundingRectWithSize:CGSizeMake(tableSize.width - (self.itemCellInsets.left + self.itemCellInsets.right), INFINITY) options:NSStringDrawingUsesLineFragmentOrigin attributes:self.itemCellTextAttributes context:nil].size;
        
        CGFloat insetStringHeight = stringItemSize.height + (self.itemCellInsets.top + self.itemCellInsets.bottom);
        return insetStringHeight + 1;
    }
    
    else if ([item isKindOfClass:[NSAttributedString class]]) {
        NSAttributedString *attributedStringItem = (NSAttributedString *)item;
        CGSize tableSize = UIEdgeInsetsInsetRect(tableView.frame, tableView.contentInset).size;
        
        CGSize attributedStringItemSize = [attributedStringItem boundingRectWithSize:CGSizeMake(tableSize.width - (self.itemCellInsets.left + self.itemCellInsets.right), INFINITY) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
        
        CGFloat insetStringHeight = attributedStringItemSize.height + (self.itemCellInsets.top + self.itemCellInsets.bottom);
        return insetStringHeight + 50;
    }
    
    return 0;
}

#pragma mark delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSInteger itemIndex = self.tableView.style == UITableViewStylePlain ? indexPath.row : indexPath.section;
    NSObject *item = self.items[itemIndex];
    
    if ([item isKindOfClass:[NSString class]]) {
        NSString *stringItem = (NSString *)item;
        
        ContentTableViewStringCell *stringCell = [tableView dequeueReusableCellWithIdentifier:kContentTableStringIdentifier forIndexPath:indexPath];
        stringCell.selectionStyle = self.contentDelegate ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
        stringCell.displayString = [[NSAttributedString alloc] initWithString:stringItem attributes:self.itemCellTextAttributes];
        return stringCell;
    }
    else if ([item isKindOfClass:[NSAttributedString class]]) {
        NSAttributedString *attributedStringItem = (NSAttributedString *)item;
        
        ContentTableViewStringCell *stringCell = [tableView dequeueReusableCellWithIdentifier:kContentTableStringIdentifier forIndexPath:indexPath];
        //stringCell.selectionStyle = self.contentDelegate ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
        stringCell.displayString = attributedStringItem;
        return stringCell;
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[ContentTableViewCell class]]) {
        ContentTableViewCell *contentCell = (ContentTableViewCell *)cell;
        
        [contentCell setParentController:self];
    }
    
    cell.contentView.backgroundColor = self.itemCellBackgroundColor;
    
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsMake(0, self.itemCellInsets.left, 0, self.itemCellInsets.right)];
    }
    
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsMake(0, self.itemCellInsets.left, 0, self.itemCellInsets.right)];
    }
}



-(void)addDeleteButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button addTarget:self action:@selector(deleteButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:DELETE_EVENT_STRING forState:UIControlStateNormal];
    
    
    button.autoresizingMask =
    (UIViewAutoresizingFlexibleTopMargin |
     UIViewAutoresizingFlexibleRightMargin);
    // that's for BOTTOM LEFT, nowhere else
    
    CGSize buttonSize = button.frame.size;
    float heightMainView = self.view.frame.size.height;
    
    float heightStatusBar =
    [UIApplication sharedApplication].statusBarFrame.size.height;
    float heightImage = buttonSize.height;
    float heightNavBar =
    self.navigationController.navigationBar.frame.size.height;
    
    float tweakUP = 10.0;
    float tweakOUT = 10.0;
    
    CGRect gg = CGRectMake( 0  + tweakOUT,
                           heightMainView -heightStatusBar -heightImage -heightNavBar
                           - tweakUP,
                           buttonSize.width, buttonSize.height);
    
    button.frame = gg;
    [self.view addSubview:button];
    
}
@end
