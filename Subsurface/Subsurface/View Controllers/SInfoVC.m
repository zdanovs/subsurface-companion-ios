//
//  SInfoVC.m
//  Subsurface
//
//  Created by Andrey Zhdanov on 23/06/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//

#import "SInfoVC.h"

@interface SInfoVC () <MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *buildVersionLabel;

@end

@implementation SInfoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    self.buildVersionLabel.text = version;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = NO;
}

- (IBAction)contactButtonAction:(id)sender {
    MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    controller.subject = @"[Subsurface-iOS]: ";
    [controller setToRecipients:@[@"subsurface@hohndel.org"]];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:controller animated:YES completion:nil];
    });
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (IBAction)visitWebsiteAction:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://subsurface.hohndel.org/"]];
}

@end
