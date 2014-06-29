//
//  SAppDelegate.m
//  Subsurface
//
//  Created by Andrey Zhdanov on 19/05/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self registerDefaultsFromSettingsBundle];
    [self createLocationServiceView];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self registerDefaultsFromSettingsBundle];
    [self startPulseAnimation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
