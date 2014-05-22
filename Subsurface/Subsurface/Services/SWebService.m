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
             
             NSDictionary *greeting = [NSJSONSerialization JSONObjectWithData:data
                                                                      options:0
                                                                        error:NULL];
             
             NSString *result = greeting[@"request"];
             
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
             
             NSDictionary *greeting = [NSJSONSerialization JSONObjectWithData:data
                                                                      options:0
                                                                        error:NULL];
             
             NSString *userID = greeting[@"user"];
             
             NSArray *information = @[NSLocalizedString(@"You are one of us!", ""), [NSString stringWithFormat:@"%@ %@ %@\n%@", NSLocalizedString(@"Your new ID for", ""), email, NSLocalizedString(@"is:", ""), userID]];
             [self informUser:information];
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

@end
