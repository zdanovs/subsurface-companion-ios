//
//  SWebService.m
//  Subsurface
//
//  Created by Andrey Zhdanov on 21/05/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//

#import "SWebService.h"
#import "SCoreDiveService.h"

#define kServerAddress  [self apiServerAddress]
#define kAutoUpload     [self shouldAutoUpload]

@interface SWebService ()
@property NSString *diveNewName;
@end

@implementation SWebService

static SWebService *_staticWebService = nil;
static NSString *_staticApiAddress = nil;
static BOOL _autoUpload;

#pragma mark - Shared instance
+ (SWebService *)sharedWebService {
    static dispatch_once_t sharedServiceTag = 0;
    
    dispatch_once(&sharedServiceTag, ^{
        _staticWebService = [[SWebService alloc] init];
    });
    
    return _staticWebService;
}

- (NSString *)apiServerAddress {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults objectForKey:kPreferencesApiKey];
}

- (BOOL)shouldAutoUpload {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [[userDefaults objectForKey:kPreferencesUploadKey] boolValue];
}

- (void)retrieveAccount:(NSString *)email {
    NSString *urlString = [NSString stringWithFormat:@"%@/user/lost/%@", kServerAddress, email];
    NSURL *url = [NSURL URLWithString:urlString];
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        if (data.length > 0 && connectionError == nil) {
             
             NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
             NSString *result = json[@"request"];
             
             if ([result isEqualToString:@"ok"]) {
                 NSArray *information = @[NSLocalizedString(@"ID Retrieval", ""), [NSString stringWithFormat:@"%@\n%@", NSLocalizedString(@"Your ID was send to", ""), email]];
                 [self informUser:information];
             }
             else if ([result isEqualToString:@"notok"]) {
                 [self createAccount:email];
             }
         }
     }];
}

- (void)createAccount:(NSString *)email {
    NSString *urlString = [NSString stringWithFormat:@"%@/user/new/%@", kServerAddress, email];
    NSURL *url = [NSURL URLWithString:urlString];
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
     {
         if (data.length > 0 && connectionError == nil) {
             
             NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
             NSString *userID = json[@"user"];
             
             NSArray *information = @[NSLocalizedString(@"You are one of us!", ""), [NSString stringWithFormat:@"%@\n%@:\n\n%@", NSLocalizedString(@"Your new ID for", ""), email, userID]];
             [self informUser:information];
             [[NSNotificationCenter defaultCenter] postNotificationName:kCreatedAccountNotification object:userID];
         }
     }];
}

- (void)deleteAccount:(NSString *)userID withEmail:(NSString *)userEmail {
    NSString *bodyString = [NSString stringWithFormat:@"login=%@&email=%@", userID, userEmail];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/user/delete/", kServerAddress]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [bodyString dataUsingEncoding:NSASCIIStringEncoding];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               [[NSNotificationCenter defaultCenter] postNotificationName:kDeletedAccountNotification object:userEmail];
                               
                           }];
}

- (void)informUser:(NSArray *)information {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:information[0]
                                                        message:information[1]
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Got it!", "")
                                              otherButtonTitles:nil, nil];
    [alertView show];
}

- (void)syncDives:(NSString *)userID {
    NSArray *dives = [SDIVE getDives];
    for (SDive *dive in dives) {
        if (![dive.uploaded boolValue]) {
            [self uploadDive:dive fully:YES];
        } else {
#warning (improve sync) do not delete all dives before getting from server; better to make merge
            [SDIVE removeDive:dive];
            [SDIVE saveState];
        }
    }
    
    [self getDivesList:userID];
}

- (void)getDivesList:(NSString *)userID {
    NSString *urlString = [NSString stringWithFormat:@"%@/dive/get/?login=%@", kServerAddress, userID];
    NSURL *url = [NSURL URLWithString:urlString];
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
     {
         if (data.length > 0 && connectionError == nil) {
             
             NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
             NSArray *divesListArray = json[@"dives"];
             
             NSMutableArray *updatedDives = [NSMutableArray arrayWithCapacity:divesListArray.count];
             for (NSDictionary *dive in divesListArray) {
                 NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:dive];
                 [dict setObject:[NSNumber numberWithBool:YES] forKey:@"uploaded"];
                 [updatedDives addObject:dict];
             }
             
             [SDIVE storeDives:updatedDives];
             [SDIVE saveState];
         }
     }];
}

- (void)deleteDive:(SDive *)dive fully:(BOOL)fully {
    NSString *userID = [[NSUserDefaults standardUserDefaults] objectForKey:kUserIdKey];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    NSString *dateString = [dateFormat stringFromDate:dive.date];
    NSString *timeString = [timeFormat stringFromDate:dive.date];
    
    NSString *urlString = [NSString stringWithFormat:@"login=%@&dive_date=%@&dive_time=%@", userID, dateString, timeString];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/dive/delete/", kServerAddress]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [urlString dataUsingEncoding:NSASCIIStringEncoding];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                           
                               if (fully) {
                                   [SDIVE removeDive:dive];
                                   [SDIVE saveState];
                               }
                               
                           }];
}

- (void)uploadDive:(SDive *)dive fully:(BOOL)fully {
    NSString *userID = [[NSUserDefaults standardUserDefaults] objectForKey:kUserIdKey];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    NSString *dateString = [dateFormat stringFromDate:dive.date];
    NSString *timeString = [timeFormat stringFromDate:dive.date];
    
    NSString *bodyString = [NSString stringWithFormat:@"login=%@&dive_date=%@&dive_latitude=%f&dive_longitude=%f&dive_time=%@&dive_name=%@", userID, dateString, [dive.latitude floatValue], [dive.longitude floatValue], timeString, dive.name];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/dive/add/", kServerAddress]];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [bodyString dataUsingEncoding:NSASCIIStringEncoding];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               
                               if (fully) {
                                   dive.uploaded = [NSNumber numberWithBool:(connectionError == nil)];
                                   [SDIVE saveState];
                               }
                               
                           }];
}

- (void)saveDive:(NSMutableDictionary *)diveInfo {
    [diveInfo setObject:[NSNumber numberWithBool:NO] forKey:@"uploaded"];
    [SDIVE storeDives:@[diveInfo]];
    [SDIVE saveState];
    
    if (kAutoUpload) {
        NSString *userID = [[NSUserDefaults standardUserDefaults] objectForKey:kUserIdKey];
        
        NSString *bodyString = [NSString stringWithFormat:@"login=%@&dive_date=%@&dive_latitude=%f&dive_longitude=%f&dive_time=%@&dive_name=%@", userID, diveInfo[@"date"], [diveInfo[@"latitude"] floatValue], [diveInfo[@"longitude"] floatValue], diveInfo[@"time"], diveInfo[@"name"]];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/dive/add/", kServerAddress]];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod = @"POST";
        request.HTTPBody = [bodyString dataUsingEncoding:NSASCIIStringEncoding];
        
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   
                                   NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                                   [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                                   [dateFormatter setLocale:[NSLocale currentLocale]];
                                   NSDate *convertedDate = [dateFormatter dateFromString:[NSString stringWithFormat:@"%@ %@", diveInfo[@"date"], diveInfo[@"time"]]];
        
                                   SDive *dive = [SDIVE getDive:convertedDate];
                                   dive.uploaded = [NSNumber numberWithBool:(connectionError == nil)];
                                   [SDIVE saveState];
                                   
                                   [[NSNotificationCenter defaultCenter] postNotificationName:kDivesListLoadNotification object:@[dive]];
                               }];
    }
}

- (void)addDive:(NSString *)diveName {
    self.diveNewName = diveName;
    
    if (!locationManager) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLDistanceFilterNone;
    }
    [locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocation *newLocation = [locations lastObject];
    [locationManager stopUpdatingLocation];
    
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    NSString *dateString = [dateFormat stringFromDate:now];
    NSString *timeString = [timeFormat stringFromDate:now];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:self.diveNewName forKey:@"name"];
    [dict setObject:[NSNumber numberWithFloat:newLocation.coordinate.latitude] forKey:@"latitude"];
    [dict setObject:[NSNumber numberWithFloat:newLocation.coordinate.longitude] forKey:@"longitude"];
    [dict setObject:dateString forKey:@"date"];
    [dict setObject:timeString forKey:@"time"];
    
    [self saveDive:dict];
}

@end
