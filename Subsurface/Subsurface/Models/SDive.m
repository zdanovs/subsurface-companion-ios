//
//  SDive.m
//  Subsurface
//
//  Created by Andrey Zhdanov on 01/06/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//

#import "SDive.h"


@implementation SDive

@dynamic date;
@dynamic latitude;
@dynamic longitude;
@dynamic name;
@dynamic uploaded;
@dynamic deleted;
@dynamic userId;

- (NSString *)getDateString {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    return [dateFormat stringFromDate:self.date];
}

- (NSString *)getTimeString {
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    return [timeFormat stringFromDate:self.date];
}

@end
