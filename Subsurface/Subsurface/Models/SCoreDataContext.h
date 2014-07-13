//
//  SCoreDataContext.h
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

#define SDB     [SCoreDataContext sharedDatabaseManager]


@class SCoreDataStore;
@interface SCoreDataContext : NSObject

#pragma mark - Initializers
- (id)initWithStore:(SCoreDataStore *)store;

#pragma mark - Shared instance
+ (SCoreDataContext *)sharedDatabaseManager;

#pragma mark - Object removal
- (void)deleteObjects:(NSArray *)objects;
- (void)deleteObject:(NSManagedObject *)object;
- (void)removeDataFromTableNameArray:(NSArray *)tableNameArray;
- (BOOL)removeBatchData:(NSInteger)batchSize fromTableNameArray:(NSArray *)tableNameArray;

#pragma mark - Database saving and fetching
- (void)saveChanges;
- (id)insertEntityWithName:(NSString *)entityName;
- (id)insertEntityWithName:(NSString *)entityName dataDictionary:(NSDictionary *)dataDictionary andMapping:(NSDictionary *)dataMapping;
- (NSArray *)fetchDataWithEntityName:(NSString *)name predicate:(NSPredicate *)predicate sort:(NSArray *)sortDescriptors fields:(NSArray *)fields type:(NSFetchRequestResultType)type limit:(NSInteger)limit distinct:(BOOL)disctinct;

@end