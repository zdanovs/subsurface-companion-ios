//
//  SCoreDataContext.m
//  Subsurface
//
//  Created by Andrey Zhdanov on 01/06/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//

#import "SCoreDataContext.h"
#import "SCoreDataStore.h"

static SCoreDataContext *_staticDatabaseManager = nil;

@interface SCoreDataContext ()

@property (strong, nonatomic) NSManagedObjectModel *objectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *storeCoordinator;

@property (strong, nonatomic) NSManagedObjectContext *mainContext;
@property (strong, nonatomic) NSManagedObjectContext *backgroundContext;

@end

@implementation SCoreDataContext

#pragma mark - Initializers
- (id)initWithStore:(SCoreDataStore *)store {
    if (self = [self init]) {
        if (store) {
            _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            _mainContext.persistentStoreCoordinator = store.storeCoordinator;
            _mainContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
            
            _backgroundContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            _backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
            _backgroundContext.parentContext = self.mainContext;
        }
    }
    else {
        NSLog(@"(!) No store supplied");
    }
    return self;
}

#pragma mark - Shared instance
+ (SCoreDataContext *)sharedDatabaseManager {
    static dispatch_once_t sharedDatabaseTag = 0;
    
    dispatch_once(&sharedDatabaseTag, ^{
        _staticDatabaseManager = [[SCoreDataContext alloc] initWithStore:SSTORE];
    });
    
    return _staticDatabaseManager;
}

#pragma mark - Object removal
- (void)deleteObjects:(NSArray *)objects {
    for (NSManagedObject *object in objects) {
        [self deleteObject:object];
    }
}

- (void)deleteObject:(NSManagedObject *)object {
    [object.managedObjectContext deleteObject:object];
}

- (void)removeDataFromTableNameArray:(NSArray *)tableNameArray {
    for (NSString *tableName in tableNameArray) {
        NSArray *allObjectsForName = [self fetchDataWithEntityName:tableName
                                                         predicate:nil
                                                              sort:nil
                                                            fields:nil
                                                              type:NSManagedObjectResultType
                                                             limit:-1
                                                          distinct:NO];
        
        for (NSManagedObject *object in allObjectsForName) {
            [self deleteObject:object];
        }
    }
    
    [self saveChanges];
}

- (BOOL)removeBatchData:(NSInteger)batchSize fromTableNameArray:(NSArray *)tableNameArray {
    BOOL areEntitiesRemaining = YES;
    
    for (NSString *tableName in tableNameArray) {
        NSArray *allObjectsForName = [self fetchDataWithEntityName:tableName
                                                         predicate:nil
                                                              sort:nil
                                                            fields:nil
                                                              type:NSManagedObjectResultType
                                                             limit:batchSize
                                                          distinct:NO];
        if ([allObjectsForName count] < batchSize) {
            areEntitiesRemaining = NO;
        }

        for (NSManagedObject *object in allObjectsForName) {
            [self deleteObject:object];
        }
    }

    [self saveChanges];
    
    return areEntitiesRemaining;
}

#pragma mark - Database saving and fetching
- (void)saveChanges {
    @try {
        if ([self getCurrentContext] == self.mainContext) {
            
            if (self.mainContext.hasChanges) {
                NSError *mainError = nil;
                if ([self.mainContext save:&mainError] == NO) {
                    NSLog(@"** Failed to save context:%@", mainError);
                }
            }
            
        }
        else {
            [self performSelectorOnMainThread:@selector(saveChanges) withObject:nil waitUntilDone:NO];
        }
    }
    @catch (NSException* exception ) {
        NSLog(@"** Exception on save: %@", exception);
    }
}

- (id)insertEntityWithName:(NSString *)entityName {
    id newEntity = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:[self getCurrentContext]];
    
    return newEntity;
}

- (id)insertEntityWithName:(NSString *)entityName dataDictionary:(NSDictionary *)dataDictionary andMapping:(NSDictionary *)dataMapping {
    id newEntity = [self insertEntityWithName:entityName];
    
    for (NSString *dataKey in dataDictionary.allKeys) {
        NSString *keyToSet = dataMapping[dataKey];
        
        if (keyToSet.length) {
            id dataValue = dataDictionary[dataKey];
            [newEntity setValue:dataValue forKey:keyToSet];
        }
        else {
            [NSException raise:@"Mapping target key not found" format:@"Unable to find mapping target key for initial key %@", dataKey];
        }
    }
    
    return newEntity;
}

- (NSArray *)fetchDataWithEntityName:(NSString *)name predicate:(NSPredicate *)predicate sort:(NSArray *)sortDescriptors fields:(NSArray *)fields type:(NSFetchRequestResultType)type limit:(NSInteger)limit distinct:(BOOL)disctinct {
    
    NSManagedObjectContext *context = [self getCurrentContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:name inManagedObjectContext:context];
    fetchRequest.entity = entity;
    fetchRequest.resultType = type;
    fetchRequest.returnsDistinctResults = disctinct;
    fetchRequest.returnsObjectsAsFaults = NO;
    fetchRequest.shouldRefreshRefetchedObjects = YES;
    fetchRequest.sortDescriptors = sortDescriptors;
    
    if (limit != -1) {
        fetchRequest.fetchLimit = limit;
    }
    
    if (predicate) {
        fetchRequest.predicate = predicate;
    }
    
    if (fields && type == NSDictionaryResultType) {
        fetchRequest.propertiesToFetch = fields;
    }
    
    NSArray __block *fetchedResultArray = nil;
    
    [context performBlockAndWait:^{
        NSError *error = nil;
        fetchedResultArray = [context executeFetchRequest:fetchRequest error:&error];
        
        if (error) {
            NSLog(@"Failed to fetch. Error: %@", error.localizedDescription);
        }
        
        if (!fetchedResultArray.count) {
            fetchedResultArray = nil;
        }
    }];
    
    return fetchedResultArray;
}

#pragma mark - Context management

- (NSManagedObjectContext *)getCurrentContext {
    NSManagedObjectContext *currentContext = nil;
    
    NSThread *currentThread = [NSThread currentThread];
    
    if ([currentThread isMainThread]){
        currentContext = self.mainContext;
    }
    else {
        currentContext = self.backgroundContext;
    }
    
    return currentContext;
}

@end