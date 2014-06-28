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
@property (weak, nonatomic) IBOutlet UILabel *accountIdLabel;
@property (weak, nonatomic) IBOutlet UIButton *deleteAccountButton;

@end

@implementation SInfoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(confirmAccountDeletion:)
                                                 name:kDeletedAccountNotification
                                               object:nil];
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    self.buildVersionLabel.text = version;
    
    NSString *userID = [[NSUserDefaults standardUserDefaults] objectForKey:kUserIdKey];
    self.accountIdLabel.text = userID.length > 0 ? userID : self.accountIdLabel.text;
    
    self.deleteAccountButton.hidden = userID.length < 1;
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

- (IBAction)deleteAccountButtonAction:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter email associated with your ID", "")
                                                        message:@""
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", "")
                                              otherButtonTitles:NSLocalizedString(@"Delete", ""), nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.keyboardType = UIKeyboardTypeEmailAddress;
    textField.textAlignment = NSTextAlignmentCenter;
    textField.placeholder = @"my@email.com";
    
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        UITextField *alertTextField = [alertView textFieldAtIndex:0];
        
        [SWEB deleteAccount:self.accountIdLabel.text withEmail:alertTextField.text];
    }
}

- (void)confirmAccountDeletion:(NSNotification *)notification {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check email and comfirm account deletion", "")
                                                        message:notification.object
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"I will", "")
                                              otherButtonTitles:nil];
    [alertView show];
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
