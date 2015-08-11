//
//  OTRstatusImage.h
//  Off the Record
//
//  Created by David on 3/19/13.
//  Copyright (c) 2013 Chris Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

#define DATE_FORMAT @"dd-MM-yyyy"

@interface OTRDateUtil : NSObject

+ (NSString *)curentDateStringFromDate:(NSDate *)dateTimeInLine withFormat:(NSString *)dateFormat;

+ (NSInteger)numberOfDaysFrom:(NSDate *)date until:(NSDate *)aDate;

+ (NSDate *) getDate:(NSDate *)fromDate daysAhead:(NSUInteger)days;

+ (NSUInteger) getNumberOfDaysInMonth:(NSDate *)curDate;

+ (NSDate *)getFirstDayOfMonth:(NSDate *)curDate;

+ (NSDate *)beginningOfDay:(NSDate *)date;

+ (NSDate *)endOfDay:(NSDate *)date;

@end
