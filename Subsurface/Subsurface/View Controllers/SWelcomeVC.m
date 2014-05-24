//
//  SWelcomeVC.m
//  Subsurface
//
//  Created by Andrey Zhdanov on 19/05/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//

#import "SWelcomeVC.h"

@interface SWelcomeVC ()

@property (weak, nonatomic) IBOutlet UITextField *existingIdTextField;
@property (weak, nonatomic) IBOutlet UIButton *logInButton;

@end

@implementation SWelcomeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(accountJustCreated:)
                                                 name:@"NewlyCreatedAccountID"
                                               object:nil];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - UITextFieldDelegates

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger enteredTextLength = textField.text.length - range.length + string.length;
    self.logInButton.enabled = enteredTextLength > 0;
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    self.logInButton.enabled = NO;
    return YES;
}

#pragma mark - NSNotification methods

- (void)accountJustCreated:(NSNotification *)notification {
    self.existingIdTextField.text = notification.object;
    self.logInButton.enabled = YES;
}

#pragma mark - IBActions

- (IBAction)LogInButtonAction:(id)sender {
    
}

- (IBAction)SendIdButtonAction:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Where to send your ID?", "")
                                                        message:@""
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", "")
                                              otherButtonTitles:NSLocalizedString(@"Send", ""), nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.keyboardType = UIKeyboardTypeEmailAddress;
    textField.textAlignment = NSTextAlignmentCenter;
    textField.placeholder = @"send@myemail.com";
    
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        UITextField *alertTextField = [alertView textFieldAtIndex:0];
        
        [SWEB retrieveAccount:alertTextField.text];
    }
}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    
    UITextField *textField = [alertView textFieldAtIndex:0];
    return [emailTest evaluateWithObject:textField.text];
}

@end
