//
//  SWebService.m
//  Subsurface
//
//  Created by Andrey Zhdanov on 21/05/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//

#import "SWebService.h"

#define kServerAddress  @"http://api.hohndel.org/api"

@implementation SWebService

static SWebService *_staticWebService = nil;

#pragma mark - Shared instance
+ (SWebService *)sharedWebService {
    static dispatch_once_t sharedServiceTag = 0;
    
    dispatch_once(&sharedServiceTag, ^{
        _staticWebService = [[SWebService alloc] init];
    });
    
    return _staticWebService;
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

- (void)informUser:(NSArray *)information {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:information[0]
                                                        message:information[1]
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Got it!", "")
                                              otherButtonTitles:nil, nil];
    [alertView show];
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
             
             [[NSNotificationCenter defaultCenter] postNotificationName:kDivesListLoadNotification object:divesListArray];
         }
     }];
}

- (void)deleteDive:(NSDictionary *)dive {
    NSString *userID = [[NSUserDefaults standardUserDefaults] objectForKey:kUserIdKey];
    
    NSString *urlString = [NSString stringWithFormat:@"%@/dive/delete/login=%@&dive_date=%@&dive_time=%@", kServerAddress, userID, dive[@"date"], dive[@"time"]];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"DELETE";
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {}];
}

@end
