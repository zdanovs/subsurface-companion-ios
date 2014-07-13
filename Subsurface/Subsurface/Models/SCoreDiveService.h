//
//  SCoreDiveService.h
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

#import "SCoreService.h"
#import "SCoreDataContext.h"
#import "SDive.h"

#define SDIVE   [SCoreDiveService sharedDiveService]

@interface SCoreDiveService : SCoreService

#pragma mark - Initialization
- (id)initWithContext:(SCoreDataContext *)context;

#pragma mark - Shared instance
+ (SCoreDiveService *)sharedDiveService;

#pragma mark - Inserting dives information
- (void)storeDive:(NSDictionary *)diveData;
- (void)storeDives:(NSArray *)divesArray;

#pragma mark - Getting dives
- (SDive *)getDive:(NSDate *)date;
- (NSArray *)getDives;
- (NSArray *)getAllDives;

#pragma mark - Removing dives
- (void)removeDive:(SDive *)dive;

#pragma mark - Save service state
- (void)saveState;

@end
