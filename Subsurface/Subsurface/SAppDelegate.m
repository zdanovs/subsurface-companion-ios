//
//  SAppDelegate.m
//  Subsurface
//
//  Created by Andrey Zhdanov on 19/05/14.
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

#import "SAppDelegate.h"

#define kAnimationOpacityKey    @"animateOpacity"

@interface SAppDelegate () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@property UIWindow  *primaryWindow;
@property UIWindow  *notificationWindow;
@property UIView    *notificationView;

@end

@implementation SAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self registerDefaultsFromSettingsBundle];
    [self createLocationServiceView];
    
    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self registerDefaultsFromSettingsBundle];
    [self startPulseAnimation];
}

#pragma mark - Additional methods

- (void)createLocationServiceView {
    self.primaryWindow = [[UIApplication sharedApplication] keyWindow];
    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    CGFloat viewHeight = 50.0f;
    
    UILabel *notificationLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, screenWidth - viewHeight - 15, viewHeight)];
    notificationLabel.text = NSLocalizedString(@"Location Service is working", @"");
    notificationLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
    notificationLabel.textColor = [UIColor whiteColor];
    
    UIButton *stopLocationServiceButton = [UIButton buttonWithType:UIButtonTypeCustom];
    stopLocationServiceButton.tintColor = [UIColor whiteColor];
    stopLocationServiceButton.frame = CGRectMake(screenWidth - viewHeight, 0, viewHeight, viewHeight);
    [stopLocationServiceButton setImage:[UIImage imageNamed:@"icon-stop.png"] forState:UIControlStateNormal];
    [stopLocationServiceButton addTarget:self action:@selector(stopLocationService) forControlEvents:UIControlEventTouchUpInside];
    
    self.notificationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, viewHeight)];
    self.notificationView.backgroundColor = [UIColor redColor];
    self.notificationView.alpha = 0.0f;
    [self.notificationView addSubview:notificationLabel];
    
    self.notificationWindow = [[UIWindow alloc] initWithFrame:CGRectMake(0, screenHeight - viewHeight, 320, viewHeight)];
    self.notificationWindow.backgroundColor = [UIColor clearColor];
    self.notificationWindow.windowLevel = UIWindowLevelStatusBar;
    [self.notificationWindow addSubview:self.notificationView];
    [self.notificationWindow addSubview:stopLocationServiceButton];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = [[[NSUserDefaults standardUserDefaults] objectForKey:kPreferencesDistanceKey] floatValue];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startLocationService)
                                                 name:kLocationServiceStartNotification
                                               object:nil];
}

- (void)startLocationService {
    [self startPulseAnimation];
    [self.notificationWindow makeKeyAndVisible];
    [self.locationManager startUpdatingLocation];
    self.notificationWindow.alpha = 1.0f;
}

- (void)stopLocationService {
    [self.locationManager stopUpdatingLocation];
    
    [self.notificationView.layer removeAnimationForKey:kAnimationOpacityKey];
    self.notificationWindow.alpha = 0.0f;
    [self.primaryWindow makeKeyAndVisible];
}

- (void)startPulseAnimation {
    CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    pulseAnimation.duration = 1.0;
    pulseAnimation.repeatCount = HUGE_VALF;
    pulseAnimation.autoreverses = YES;
    pulseAnimation.fromValue = [NSNumber numberWithFloat:0.8];
    pulseAnimation.toValue = [NSNumber numberWithFloat:0.2];
    [self.notificationView.layer addAnimation:pulseAnimation forKey:kAnimationOpacityKey];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    NSString *defaultName = [[NSUserDefaults standardUserDefaults] objectForKey:kPreferencesDefaultNameKey];
    [SWEB addDive:defaultName];
}

- (void)registerDefaultsFromSettingsBundle {
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    if(!settingsBundle) {
        return;
    }
    
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    for (NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if(key && ![key isEqualToString:@""]) {
            [defaultsToRegister setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
        }
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults registerDefaults:defaultsToRegister];
    [userDefaults synchronize];
}

@end
