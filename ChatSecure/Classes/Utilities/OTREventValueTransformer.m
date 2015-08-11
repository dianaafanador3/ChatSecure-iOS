//
//  OTREventValueTransformer.m
//  ChatSecure
//
//  Created by Diana Perez on 6/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTREventValueTransformer.h"
#import <EventKit/EventKit.h>

#import "OTRCalendarController.h"

@implementation OTREventValueTransformer

+ (Class)transformedValueClass
{
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)value
{
    if (!value) return nil;
    
    EKCalendar *calendar = (EKCalendar *)value;
    
    return calendar.title;
}

@end