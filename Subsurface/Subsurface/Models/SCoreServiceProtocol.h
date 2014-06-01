//
//  SCoreServiceProtocol.h
//  Subsurface
//
//  Created by Andrey Zhdanov on 01/06/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kDbTableDive        @"SDive"

#define FULL_ARRAY          @"batchArray"
#define BATCH_ARRAY         @"fullArray"
#define DEFAULT_BATCH_SIZE  1000
#define BATCH_DELAY         0.1

typedef enum {
    eActionTypeSave     = 0,
    eActionTypeMerge    = 1,
    eActionTypeDelete   = 2,
} ActionType;

typedef void (^BatchProcessBlock)(BOOL isSavedSuccessfully, NSArray *remainingArray);
typedef void (^BatchProcessEndedBlock)();
typedef void (^ServiceCompletionBlock)(NSString *completedServiceType, NSString *serviceHash);


@protocol SCoreServiceProtocol <NSObject>

- (void)updateWithServerEntryData:entityData;

@end