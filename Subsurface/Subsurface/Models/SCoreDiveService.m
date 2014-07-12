//
//  SCoreDiveService.m
//  Subsurface
//
//  Created by Andrey Zhdanov on 01/06/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//

#import "SCoreDiveService.h"

@interface SCoreDiveService ()

@property (nonatomic, assign) SCoreDataContext *internalContext;

@end

@implementation SCoreDiveService

static SCoreDiveService *_staticDiveService = nil;

#pragma mark - Initialization
- (id)initWithContext:(SCoreDataContext *)context {
    self = [self init];
    if (self) {
        self.internalContext = context;
    }
    return self;
}

#pragma mark - Shared instance
+ (SCoreDiveService *)sharedDiveService {
    static dispatch_once_t sharedContactTag = 0;
    
    dispatch_once(&sharedContactTag, ^{
        _staticDiveService = [[SCoreDiveService alloc] initWithContext:SDB];
    });
    
    return _staticDiveService;
}

#pragma mark - Inserting dives
- (void)storeDive:(NSDictionary *)diveData {
    [self saveDiveToDBWithData:diveData];
}

- (void)storeDives:(NSArray *)divesArray {
    [self performBatchSaving:divesArray];
}

- (void)saveDiveToDBWithData:(NSDictionary *)diveData {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    NSDate *convertedDate = [dateFormatter dateFromString:[NSString stringWithFormat:@"%@ %@", diveData[@"date"], diveData[@"time"]]];
    
    if (![self diveExists:convertedDate]) {
        SDive *dive = [self.internalContext insertEntityWithName:kDbTableDive];
        dive.name = diveData[@"name"];
        dive.latitude = [NSNumber numberWithFloat:[diveData[@"latitude"] floatValue]];
        dive.longitude = [NSNumber numberWithFloat:[diveData[@"longitude"] floatValue]];
        
        dive.date = convertedDate;
        dive.uploaded = diveData[@"uploaded"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kDivesListLoadNotification object:@[dive]];
    }
}

#pragma mark - Getting dives
- (NSArray *)getAllDives {
    NSArray *divesArray = [self.internalContext fetchDataWithEntityName:kDbTableDive
                                                              predicate:nil
                                                                   sort:nil
                                                                 fields:nil
                                                                   type:NSManagedObjectResultType
                                                                  limit:-1
                                                               distinct:NO];
    return divesArray;
}

- (NSArray *)getDives {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"deleted == NO"];
    
    NSArray *divesArray = [self.internalContext fetchDataWithEntityName:kDbTableDive
                                                              predicate:predicate
                                                                   sort:@[sortDescriptor]
                                                                 fields:nil
                                                                   type:NSManagedObjectResultType
                                                                  limit:-1
                                                              	distinct:NO];
    return divesArray;
}

- (SDive *)getDive:(NSDate *)date {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(date == %@)", date];
    
    return [[self.internalContext fetchDataWithEntityName:kDbTableDive
                                                predicate:predicate
                                                     sort:nil
                                                   fields:nil
                                                     type:NSManagedObjectResultType
                                                    limit:-1
                                                 distinct:NO] lastObject];
}

- (BOOL)diveExists:(NSDate *)date {
    return [self getDive:date] != nil;
}

#pragma mark - Removing dives
- (void)removeDive:(SDive *)dive {
    [self.internalContext deleteObject:dive];
}

#pragma mark - Save service state
- (void)saveState {
    [self.internalContext saveChanges];
}

#pragma mark - Superclass method overriding
- (void)storeEntitiesFromArray:(NSArray *)entityArray {
    for (NSDictionary *diveEntry in entityArray) {
        [SDIVE saveDiveToDBWithData:diveEntry];
    }
}

@end
