//
//  OTRCalendarController.h
//  ChatSecure
//
//  Created by Diana Perez on 4/14/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OTREvent, EKEvent, EKCalendar, EKEventStore;

@interface OTRCalendarController : NSObject

@property (nonatomic, strong) EKCalendar *calendar;

@property (nonatomic, strong) EKEventStore *eventStore;

@property (nonatomic ) BOOL permission;

- (NSURL *) addEventAt:(OTREvent *)event;

- (EKEvent *)eventsForIdentifier:(NSString *)identifier;

- (NSArray *)fetchAllCalendars;

- (EKCalendar *)calendarForIdentifier:(NSString *)identifier;

@end
