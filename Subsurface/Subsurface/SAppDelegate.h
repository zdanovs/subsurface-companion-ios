//
//  SAppDelegate.h
//  Subsurface
//
//  Created by Andrey Zhdanov on 18/05/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
