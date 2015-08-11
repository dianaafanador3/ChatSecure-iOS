//
//  OTRXMPPChatter.h
//  ChatSecure
//
//  Created by Diana Perez on 6/26/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "OTRChatter.h"

@class XMPPvCardTemp;

extern const struct OTRXMPPChatterAttributes {
    __unsafe_unretained NSString *vCardTemp;
    __unsafe_unretained NSString *photoHash;
    __unsafe_unretained NSString *waitingForvCardTempFetch;
    __unsafe_unretained NSString *lastUpdatedvCardTemp;
    
} OTRXMPPChatterAttributes;

@interface OTRXMPPChatter : OTRChatter

@property (nonatomic, strong) XMPPvCardTemp *vCardTemp;
@property (nonatomic, strong) NSDate *lastUpdatedvCardTemp;
@property (nonatomic, getter =  isWaitingForvCardTempFetch) BOOL waitingForvCardTempFetch;
@property (nonatomic, strong) NSString *photoHash;






@end
