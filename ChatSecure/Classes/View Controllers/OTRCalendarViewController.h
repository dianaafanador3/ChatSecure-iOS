//
//  OTRCreatEventViewController.m
//  ChatSecure
//
//  Created by Diana Perez on 3/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//


#import <UIKit/UIKit.h>


#import "JTCalendar.h"

@interface OTRCalendarViewController : UIViewController <JTCalendarDataSource, UINavigationControllerDelegate> {
    
    NSDate *selectedDate;
    NSMutableDictionary *savedDates;
    
    NSMutableArray *currentEvents;
}
@property (strong, nonatomic) JTCalendarMenuView *calendarMenuView;
@property (strong, nonatomic) JTCalendarContentView *calendarContentView;

@property (strong, nonatomic) JTCalendar *calendar;

@property (strong, nonatomic, readwrite) UITableView *currentDayTableView;

@end
