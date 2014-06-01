//
//  SCoreDataStore.h
//  Subsurface
//
//  Created by Andrey Zhdanov on 01/06/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define SSTORE  [SCoreDataStore sharedStore]

@interface SCoreDataStore : NSObject

@property (strong, nonatomic) NSPersistentStoreCoordinator *storeCoordinator;

#pragma mark - Database setup
- (id)initWithModel:(NSURL *)modelURL andStoreURL:(NSURL *)storeURL;

#pragma mark - Shared instance
+ (SCoreDataStore *)sharedStore;

@end
