//
//  SWebService.h
//  Subsurface
//
//  Created by Andrey Zhdanov on 21/05/14.
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

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define SWEB    [SWebService sharedWebService]

@class SDive;

@interface SWebService : NSObject <CLLocationManagerDelegate> {
    CLLocationManager *locationManager;
}

#pragma mark - Shared instance
+ (SWebService *)sharedWebService;
- (BOOL)internetIsAvailable:(NSString *)alertTitle;

#pragma mark - Service API
- (void)retrieveAccount:(NSString *)email;
- (void)deleteAccount:(NSString *)userID withEmail:(NSString *)userEmail;

- (void)syncDives:(NSString *)userID;
- (void)getDivesList:(NSString *)userID;
- (void)deleteDive:(SDive *)dive fully:(BOOL)fully;
- (void)uploadDive:(SDive *)dive fully:(BOOL)fully;
- (void)addDive:(NSString *)diveName;

@end
