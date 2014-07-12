//
//  SCoreDiveService.h
//  Subsurface
//
//  Created by Andrey Zhdanov on 01/06/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
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
