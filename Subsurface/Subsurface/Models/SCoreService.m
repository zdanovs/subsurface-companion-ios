//
//  SCoreService.m
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

#define BLOCK_SAFE_PERFORM(block, ...) block ? block(__VA_ARGS__) : nil

@interface SCoreService ()

@property (nonatomic, copy) BatchProcessBlock       batchProcessBlock;
@property (nonatomic, copy) BatchProcessEndedBlock  batchProcessEndedBlock;

@property BOOL stateIsBackground;

@end

@implementation SCoreService

#pragma mark - Initialization

- (id)init {
    self = [super init];
    if (self) {
        if ([[UIApplication sharedApplication] respondsToSelector:@selector(applicationState)] ){
            UIApplicationState state = [[UIApplication sharedApplication] applicationState];
            
            self.stateIsBackground = (state == UIApplicationStateBackground);
            
            [[NSNotificationCenter defaultCenter] addObserver: self
                                                     selector: @selector(appIsInBackground)
                                                         name: UIApplicationDidEnterBackgroundNotification
                                                       object: nil];
            
            [[NSNotificationCenter defaultCenter] addObserver: self
                                                     selector: @selector(appIsInForeground)
                                                         name: UIApplicationDidBecomeActiveNotification
                                                       object: nil];
        }
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Batch date saving

- (void)performBatchSaving:(NSArray *)entityArray {
    self.stateIsBackground = NO;
    
    //******BATCH PROCESS BLOCK*******
    //process operation block by block
    BatchProcessBlock batchProcessBlock = ^(BOOL isSavedSuccessfully, NSArray *remainingArray) {
        
        if (!self.stateIsBackground) {
            [self performSelector:@selector(saveBatchArray:)
                       withObject:remainingArray
                       afterDelay:BATCH_DELAY];
        }
        else {
            [self saveBatchArray:remainingArray];
        }
    };
    
    //perform tasks when saving ended
    BatchProcessEndedBlock batchProcessBlockEnded = ^() {
        [self storeCompleted];
    };
    
    self.batchProcessBlock = batchProcessBlock;
    self.batchProcessEndedBlock = batchProcessBlockEnded;
    
    
    if (entityArray.count) {
        [self saveBatchArray:entityArray];
    }
    else {
        BLOCK_SAFE_PERFORM(self.batchProcessEndedBlock);
    }
}

- (void)saveBatchArray:(NSArray *)remainingArray {
    NSDictionary *modifiedArrayDictionary = [self separateArray:remainingArray];
    
    NSArray *batchArray = [modifiedArrayDictionary objectForKey:BATCH_ARRAY];
    NSArray *fullArray  = [modifiedArrayDictionary objectForKey:FULL_ARRAY];
    
    if ([remainingArray count]) {
        dispatch_async(dispatch_get_main_queue(), ^() {
            [self storeEntitiesFromArray:batchArray];
            [self saveState];
            BLOCK_SAFE_PERFORM(self.batchProcessBlock, YES, fullArray);
        });
    }
    else {
        BLOCK_SAFE_PERFORM(self.batchProcessEndedBlock);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"CommitFinished" object:self];
    }
}

- (NSDictionary *)separateArray:(NSArray *)receivedArray {
    NSMutableArray *shortArray = [receivedArray mutableCopy];
    NSMutableArray *partOfArray = [[NSMutableArray alloc] init];
    
    if (!self.batchSavingSize) {
        self.batchSavingSize = DEFAULT_BATCH_SIZE;
    }
    
    if (shortArray.count > self.batchSavingSize) {
        //fast move 100 first objects from array received array to batch array
        for (int i = 0; i < self.batchSavingSize; i++) {
            [partOfArray addObject:shortArray[i]];
        }
        //fast remove first 100 objects from received array
        for (int i = 0; i < self.batchSavingSize; i++) {
            [shortArray removeObjectAtIndex:0];
        }
    }
    else {
        for (int j = 0; j < shortArray.count; j++) {
            [partOfArray addObject:receivedArray[j]];
        }
        [shortArray removeAllObjects];
    }
    
    NSDictionary *returnArraysDictionary = @{BATCH_ARRAY : partOfArray,
                                             FULL_ARRAY : shortArray};
    
    return returnArraysDictionary;
}

#pragma mark - Background state handling

- (void)appIsInBackground {
    self.stateIsBackground = YES;
}

- (void)appIsInForeground {
    self.stateIsBackground = NO;
}

#pragma mark - Service data retrieval protocols

- (void)updateWithServerEntryData:(id)entityData {
    //Override this method in subclass
}

#pragma mark - Methods to override

- (void)storeEntitiesFromArray:(NSArray *)entityArray {
    //Override this method in subclass
}

- (void)storeCompleted {
    //Override this method in subclass
}

- (void)saveState {
    //Override this method in subclass
}

@end