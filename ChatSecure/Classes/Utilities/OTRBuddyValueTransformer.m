//
//  OTREventValueTransformer.m
//  ChatSecure
//
//  Created by Diana Perez on 6/12/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRBuddyValueTransformer.h"

#import "OTRBuddy.h"

@implementation OTRBuddyValueTransformer 

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
    
    NSMutableArray *buddies = (NSMutableArray *)value;
    
    NSMutableArray *finalBuddies = [[NSMutableArray alloc] init];
    
    for(OTRBuddy *buddy in buddies)
    {
        [finalBuddies addObject:buddy.displayName];
    }
    
    return [finalBuddies componentsJoinedByString:@", "];
}

@end