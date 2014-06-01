//
//  SCoreService.h
//  Subsurface
//
//  Created by Andrey Zhdanov on 01/06/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCoreServiceProtocol.h"

@interface SCoreService : NSObject <SCoreServiceProtocol> {
    
}

@property NSString *serviceHash;
@property NSString *serviceType;

@property NSInteger batchSavingSize;

@property NSMutableArray *performedOperationArray;

@property (nonatomic, copy) ServiceCompletionBlock serviceCompletionBlock;

- (void)performBatchSaving:(NSArray *)entityArray;

#pragma mark - Methods to override
- (void)storeEntitiesFromArray:(NSArray *)entityArray;
- (void)storeCompleted;
- (void)saveState;

@end