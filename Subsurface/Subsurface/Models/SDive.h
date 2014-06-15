//
//  SDive.h
//  Subsurface
//
//  Created by Andrey Zhdanov on 01/06/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SDive : NSManagedObject

@property (nonatomic, retain) NSDate *date;
@property (nonatomic, retain) NSNumber *latitude;
@property (nonatomic, retain) NSNumber *longitude;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSNumber *uploaded;

- (NSString *)getDateString;
- (NSString *)getTimeString;

@end
