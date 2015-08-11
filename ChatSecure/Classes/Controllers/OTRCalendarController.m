//
//  OTRCalendarController.m
//  ChatSecure
//
//  Created by Diana Perez on 4/14/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRCalendarController.h"
#import <EventKit/EventKit.h>
#import "EKEvent+Utilities.h"



#import "OTREvent.h"

#import "OTRDateUtil.h"

#define LOCAL_CALENDAR @"IN2STANT Calendar"



@interface OTRCalendarController ()

@end

@implementation OTRCalendarController

- (id) init
{
    if (self = [super init]) {
        if (self.eventStore == nil) {
            self.eventStore = [[EKEventStore alloc] init];
        }
        // request permissions
        [self.eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
            
            if (granted) {
                
                NSLog(@"granted");
                self.permission = YES;
                //This method checks to make sure the calendar I want exists, then move on from there...
            } else {
                //put error popup code here.
                self.permission = NO;
            }
        }];
    }
    return self;
}


- (NSURL *) addEventAt:(OTREvent *)event
{
    EKEvent *ekEvent = [EKEvent eventWithEventStore:self.eventStore];
    
    
    // assign basic information to the event; location is optional
    ekEvent.calendar = self.calendar;
    ekEvent.location = event.location;
    ekEvent.title = event.title;
    ekEvent.notes = event.notes;
    ekEvent.URL = [NSURL URLWithString:event.url];
    ekEvent.allDay = event.allDay;
    
    if(event.repeat != 0)
        ekEvent.recurrenceRules = @[[self getRepeatForOption:event.repeat]];
    
    ekEvent.calendar = [self getCalendarWithIdentifier:event.calendarIdentifier];
    //ekEvent.attendees
    
    if(event.alert != OTRAlertNone)
    {
        EKAlarm *alert = [self getAlarmForOption:event.alert andDate:event.startsDate];
        if(!alert)
            ekEvent.alarms = @[alert];
    }
    
    if(event.secondAlert != OTRAlertNone)
    {
        EKAlarm *alert = [self getAlarmForOption:event.secondAlert andDate:event.startsDate];
        if(!alert)
            ekEvent.alarms = @[alert];
    }
    
    ekEvent.availability = [self getAvailabilityForOption:event.showAs];
    
    // set the start date to the current date/time and the event duration to two hours

    ekEvent.startDate = event.startsDate;
    ekEvent.endDate = event.endsDate;
    
    
    //if(!self.calendar)
    //    return nil;
    NSError *error = nil;
    // save event to the callendar
    BOOL result = [self.eventStore saveEvent:ekEvent span:EKSpanThisEvent commit:YES error:&error];
    if (result) {
        return [OTRCalendarController getFileUrlFromEvent:ekEvent];
        

    } else {
        // NSLog(@"Error saving event: %@", error);
        // unable to save event to the calendar
        return nil;
    }

}


- (EKCalendar *) getCalendarWithIdentifier:(NSString *)calendarIdentifier
{
    
    EKEntityType type = EKEntityTypeEvent;
    
    NSArray *calendarArray = [self.eventStore calendarsForEntityType:type];
    
    EKCalendar *cal = nil;
    for(EKCalendar *calendar in calendarArray)
    {
        if([calendar.calendarIdentifier isEqualToString:calendarIdentifier])
        {
            cal = calendar;
        }
    }
    
    return cal;
}


- (EKEventAvailability) getAvailabilityForOption:(OTRShowAsStates)showAsState
{
    EKEventAvailability availability;
    
    switch (showAsState) {
        case 0:
            availability = EKEventAvailabilityUnavailable;
            break;
        case 1:
            availability = EKEventAvailabilityBusy;
            break;
        case 2:
            availability = EKEventAvailabilityFree;
            break;
    }
    return availability;
}


- (EKAlarm *) getAlarmForOption:(OTRAlertStates)alertStates andDate:(NSDate *)date
{
    EKAlarm *alert = [EKAlarm alarmWithAbsoluteDate:date];
    
    switch (alertStates)
    {
        case 0:
            return nil;
            break;
        case 1:
            break;
        case 2:
            alert.relativeOffset = 60*5*-1;
            break;
        case 3:
            alert.relativeOffset = 15*60*-1;
            break;
        case 4:
            alert.relativeOffset = 30*60*-1;
            break;
        case 5:
            alert.relativeOffset = 60*60*-1;
            break;
        case 6:
            alert.relativeOffset = 2*60*60*-1;
            break;
        case 7:
            alert.relativeOffset = 24*60*60*-1;
            break;
        case 8:
            alert.relativeOffset = 2*24*60*60*-1;
            break;
    }
    
    return alert;

}


- (EKRecurrenceRule *) getRepeatForOption:(OTRRepeatStates)repeatState
{
    EKRecurrenceFrequency recFreq;
    int rep = 0;
    
    switch (repeatState)
    {
        case 0:
            return nil;
            break;
        case 1:
            recFreq = EKRecurrenceFrequencyDaily;
            rep = 1;
            break;
        case 2:
            recFreq = EKRecurrenceFrequencyWeekly;
            rep = 1;
            break;
        case 3:
            recFreq = EKRecurrenceFrequencyWeekly;
            rep = 2;
            break;
        case 4:
            recFreq = EKRecurrenceFrequencyMonthly;
            rep = 1;
            break;
        case 5:
            recFreq = EKRecurrenceFrequencyYearly;
            rep = 1;
            break;
    }

    
    return [[EKRecurrenceRule alloc]
            initRecurrenceWithFrequency:recFreq
            interval:rep
            end:nil];
    
}


- (BOOL) createEKCalendar
{
    NSString* calendarName = LOCAL_CALENDAR;
    
    if (!self.calendar) {
        self.calendar = [EKCalendar calendarForEntityType:EKEntityTypeEvent eventStore:self.eventStore];
        self.calendar.title = calendarName;
        // find appropriate source type. I'm interested only in local calendars but
        // there are also calendars in iCloud, MS Exchange, ...
        // look for EKSourceType in manual for more options
        
        
        for (EKSource *source in self.eventStore.sources)
        {
            if (source.sourceType == EKSourceTypeCalDAV &&
                [source.title isEqualToString:LOCAL_CALENDAR]) //Couldn't find better way, if there is, then tell me too. :)
            {
                self.calendar.source = source;
                break;
            }
        }
        
        if (self.calendar.source == nil)
        {
            for (EKSource *source in self.eventStore.sources)
            {
                if (source.sourceType == EKSourceTypeLocal)
                {
                    self.calendar.source = source;
                    break;
                }
            }
        }
        
        NSError *error = nil;
        return [self.eventStore saveCalendar:self.calendar commit:YES error:&error];
    }
    else
    {
        return true;
    }

}




+ (NSURL *) getFileUrlFromEvent:(EKEvent *)event
{
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [docsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.ics", event.title]];
    NSURL *fileUrl     = [NSURL fileURLWithPath:filePath];
    
    
    NSError *error = nil;
    
    NSData *data = [[event iCalString] dataUsingEncoding:NSUTF8StringEncoding];;
    [data writeToURL:fileUrl atomically:YES];
    if (error) {
        NSLog(@"Error while writing to File: %@", [error localizedDescription]);
    }
    
    return fileUrl;
}


- (EKEvent *)eventsForIdentifier:(NSString *)identifier
{
    if([self createEKCalendar])
    {
        return [self.eventStore eventWithIdentifier:identifier];
    }
    else
    {
        return nil;
    }
}

- (EKCalendar *)calendarForIdentifier:(NSString *)identifier
{
    if(self.eventStore)
    {
        return [self.eventStore calendarWithIdentifier:identifier];
    }
    
    return nil;
}

- (NSArray *)fetchAllCalendars
{
    EKEntityType type = EKEntityTypeEvent;
    
    NSArray *array = [self.eventStore calendarsForEntityType:type];
    
    return array;
}



@end
