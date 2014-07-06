//
//  SWebService.h
//  Subsurface
//
//  Created by Andrey Zhdanov on 21/05/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define SWEB    [SWebService sharedWebService]

@class SDive;

@interface SWebService : NSObject <CLLocationManagerDelegate> {
    CLLocationManager *locationManager;
}

#pragma mark - Shared instance
+ (SWebService *)sharedWebService;

#pragma mark - Service API
- (void)retrieveAccount:(NSString *)email;
- (void)deleteAccount:(NSString *)userID withEmail:(NSString *)userEmail;

- (void)syncDives:(NSString *)userID;
- (void)getDivesList:(NSString *)userID;
- (void)deleteDive:(SDive *)dive fully:(BOOL)fully;
- (void)uploadDive:(SDive *)dive fully:(BOOL)fully;
- (void)addDive:(NSString *)diveName;

@end
