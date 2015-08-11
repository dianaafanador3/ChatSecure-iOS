//
//  OTREvents.h
//  ChatSecure
//
//  Created by IN2 on 22/10/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "OTRYapDatabaseObject.h"

@class OTRAccount, OTRMessage, OTRBuddy, EKCalendar;

typedef NS_ENUM(int, OTRAlertStates)
{
    OTRAlertNone = 0,
    OTRAlertAtTimeOfEvent = 1,
    OTRAlertFiveMinutesBefore = 2,
    OTRAlertFifteenMinutesBefore = 3,
    OTRAlertThirtyMinutesBefore = 4,
    OTRAlertOneHourBefore = 5,
    OTRAlertTwoHoursBefore = 6,
    OTRAlertOneDayBefore = 7,
    OTRAlertTwoDaysBefore = 8
};

typedef NS_ENUM(int, OTRRepeatStates)
{
    OTRRepeatNone = 0,
    OTRRepeatEveryDay = 1,
    OTRRepeatEveryWeek = 2,
    OTRRepeatEveryTwoWeeks = 3,
    OTRRepeatEveryMonth = 4,
    OTRRepeatEveryYear = 5
};

typedef NS_ENUM(int, OTRShowAsStates)
{
    OTRShowAsNone = 0,
    OTRShowAsBusy = 1,
    OTRShowAsFree = 2
};


extern const struct OTREventAttributes {
    __unsafe_unretained NSString *title;
    __unsafe_unretained NSString *location;
    __unsafe_unretained NSString *startsDate;
    __unsafe_unretained NSString *endsDate;
    __unsafe_unretained NSString *invitees;
    __unsafe_unretained NSString *notes;
    __unsafe_unretained NSString *day;
    __unsafe_unretained NSString *allDay;
    __unsafe_unretained NSString *repeat;
    __unsafe_unretained NSString *calendar;
    __unsafe_unretained NSString *alert;
    __unsafe_unretained NSString *secondAlert;
    __unsafe_unretained NSString *showAs;
    __unsafe_unretained NSString *url;
    __unsafe_unretained NSString *eventId;
    __unsafe_unretained NSString *filePath;

    
} OTREventAttributes;

extern const struct OTREventRelationships {
    __unsafe_unretained NSString *accountUniqueId;
} OTREventRelationships;

extern const struct OTREventEdges {
    __unsafe_unretained NSString *account;
} OTREventEdges;


@interface OTREvent : OTRYapDatabaseObject <YapDatabaseRelationshipNode>

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *location;
@property (nonatomic, strong) NSDate *startsDate;
@property (nonatomic, strong) NSDate *endsDate;
@property (nonatomic, strong) NSMutableArray *invitees;
@property (nonatomic, strong) NSString *notes;
@property (nonatomic, strong) NSDate *day;
@property (nonatomic, strong) NSURL *filePath;


@property (nonatomic) BOOL allDay;
@property (nonatomic) OTRRepeatStates repeat;
@property (nonatomic, strong) NSString *calendarIdentifier;
@property (nonatomic) OTRAlertStates alert;
@property (nonatomic) OTRAlertStates secondAlert;
@property (nonatomic) OTRShowAsStates showAs;
@property (nonatomic, strong) NSString *url;


@property (nonatomic, strong) NSString *accountUniqueId;
@property (nonatomic, strong) NSString *eventId;


- (id)initWithTitle:(NSString *)title;


@end