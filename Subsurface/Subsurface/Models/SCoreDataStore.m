//
//  SCoreDataStore.m
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

#import "SCoreDataStore.h"

@interface SCoreDataStore ()
@property (strong, nonatomic) NSManagedObjectModel *objectModel;
@end

@implementation SCoreDataStore

#define kDatabaseModelName          @"SModel"
#define kDatabaseModelExtension     @"momd"
#define kDatabaseNameDefault        @"Subsurface.sqlite"

static SCoreDataStore *_staticStore = nil;

#pragma mark - Database setup
- (id)initWithModel:(NSURL *)modelURL andStoreURL:(NSURL *)storeURL {
    if (self = [self init]) {
        _objectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        _storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_objectModel];
        
        NSDictionary *storeOptions = [NSDictionary dictionaryWithObjectsAndKeys:NSFileProtectionNone, NSPersistentStoreFileProtectionKey,
                                      [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                      [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        
        NSError *error = nil;
        NSPersistentStore *store = [_storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                   configuration:nil
                                                                             URL:storeURL
                                                                         options:storeOptions
                                                                           error:&error];
        
        if (!store) {
            NSLog(@"core_data_error_failed_to_add_store: %@", error.localizedDescription);
        }
    }
    
    return self;
}

#pragma mark - Shared instance
+ (SCoreDataStore *)sharedStore {
    static dispatch_once_t sharedStoreTag = 0;
    
    dispatch_once(&sharedStoreTag, ^{
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:kDatabaseModelName withExtension:kDatabaseModelExtension];
        NSURL *storeURL = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:kDatabaseNameDefault];
        
        _staticStore = [[SCoreDataStore alloc] initWithModel:modelURL andStoreURL:storeURL];
    });
    
    return _staticStore;
}

@end
