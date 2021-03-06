//
//  SDive.h
//  Subsurface
//
//  Created by Andrey Zhdanov on 01/06/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface SDive : NSManagedObject

@property (nonatomic, retain) NSDate   *date;
@property (nonatomic, retain) NSNumber *latitude;
@property (nonatomic, retain) NSNumber *longitude;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSNumber *uploaded;
@property (nonatomic, retain) NSNumber *deleted;
@property (nonatomic, retain) NSString *userId;

- (NSString *)getDateString;
- (NSString *)getTimeString;

@end
