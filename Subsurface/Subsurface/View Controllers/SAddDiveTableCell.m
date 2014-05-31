//
//  SAddDiveTableCell.m
//  Subsurface
//
//  Created by Andrey Zhdanov on 31/05/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//

#import "SAddDiveTableCell.h"

@implementation SAddDiveTableCell

- (IBAction)addNewDiveAction:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter dive name", "")
                                                        message:@""
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", "")
                                              otherButtonTitles:NSLocalizedString(@"Add", ""), nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.keyboardType = UIKeyboardTypeEmailAddress;
    textField.textAlignment = NSTextAlignmentCenter;
    textField.placeholder = @"dive name";
    
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        UITextField *alertTextField = [alertView textFieldAtIndex:0];
        
        [SWEB addDive:alertTextField.text];
    }
}

@end
