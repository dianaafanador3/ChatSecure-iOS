//
//  OTRstatusImage.m
//  Off the Record
//
//  Created by David on 3/19/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//


#import "OTRDateUtil.h"

@implementation OTRDateUtil

+ (NSString *)curentDateStringFromDate:(NSDate *)dateTimeInLine withFormat:(NSString *)dateFormat {
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    
    [formatter setDateFormat:dateFormat];
    
    NSString *convertedString = [formatter stringFromDate:dateTimeInLine];
    
    return convertedString;
}

+ (NSInteger)numberOfDaysFrom:(NSDate *)date until:(NSDate *)aDate {
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSDateComponents *components = [gregorianCalendar components:NSDayCalendarUnit fromDate:date toDate:aDate options:0];
    
    return [components day];
};

+ (NSDate *) getDate:(NSDate *)fromDate daysAhead:(NSUInteger)days
{
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.day = days;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *previousDate = [calendar dateByAddingComponents:dateComponents
                                                     toDate:fromDate
                                                    options:0];
    
    return previousDate;
}

+ (NSUInteger) getNumberOfDaysInMonth:(NSDate *)curDate
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSRange range = [cal rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:curDate];
    return  range.length;
}



+ (NSDate *)getFirstDayOfMonth:(NSDate *)curDate
{
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* comps = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSWeekCalendarUnit|NSWeekdayCalendarUnit fromDate:curDate]; // Get necessary date components

    // set last of month
    [comps setMonth:[comps month]];
    [comps setDay:1];
    return [calendar dateFromComponents:comps];
    
}

+ (NSDate *)beginningOfDay:(NSDate *)date
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    
    NSDateComponents *components = [cal components:( NSMonthCalendarUnit | NSYearCalendarUnit | NSDayCalendarUnit ) fromDate:date];
    components.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    
    return [cal dateFromComponents:components];
}

+ (NSDate *)endOfDay:(NSDate *)date
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:( NSMonthCalendarUnit | NSYearCalendarUnit | NSDayCalendarUnit ) fromDate:date];
    components.timeZone = [NSTimeZone timeZoneWithName:@"GMT"];
    
    [components setHour:23];
    [components setMinute:59];
    [components setSecond:59];
    
    return [cal dateFromComponents:components];
}
@end
