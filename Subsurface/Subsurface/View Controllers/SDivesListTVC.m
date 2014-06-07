//
//  SDivesListTVC.m
//  Subsurface
//
//  Created by Andrey Zhdanov on 24/05/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//

#import "SDivesListTVC.h"
#import "SDiveTableCell.h"
#import "SCoreDiveService.h"

#define kCellHeight    44.0f

@interface SDivesListTVC ()

@property NSArray *divesList;
@property NSArray *initialDivesList;

@end

@implementation SDivesListTVC

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = self.refreshControl;
    [self.refreshControl beginRefreshing];
    
    _divesList = [NSArray array];
    [SWEB getDivesList:self.userID];
    
    _divesList = [SDIVE getDives];
    _initialDivesList = _divesList.copy;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(divesListReceived:)
                                                 name:kDivesListLoadNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = NO;
    self.tableView.contentOffset = CGPointMake(0, kCellHeight);
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _divesList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *commonCell = nil;
    
    SDiveTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DiveCell" forIndexPath:indexPath];
    [cell setupDiveCell:_divesList[indexPath.row]];
    commonCell = cell;
    
    return commonCell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        SDive *dive = _divesList[indexPath.row];
        
        NSMutableArray *mutableDivesList = [_divesList mutableCopy];
        [mutableDivesList removeObject:dive];
        _divesList = [NSArray arrayWithArray:mutableDivesList];
        [self.tableView reloadData];
        
        [SWEB deleteDive:dive];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Detemine if it's in editing mode
    if (self.tableView.editing) {
        return UITableViewCellEditingStyleNone;
    }
    
    return UITableViewCellEditingStyleDelete;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIToolbar *bkgToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, kCellHeight + 1)];

    UIButton *addDiveButton = [[UIButton alloc] initWithFrame:bkgToolbar.frame];
    addDiveButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
    [addDiveButton setTitle:NSLocalizedString(@"Add Dive", @"") forState:UIControlStateNormal];
    [addDiveButton addTarget:self action:@selector(addNewDiveAction) forControlEvents:UIControlEventTouchUpInside];
    [addDiveButton setTitleColor:[UIColor colorWithRed:0 green:0.478431 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    
    UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(0, kCellHeight, self.tableView.frame.size.width, 1)];
    separatorView.backgroundColor = [UIColor colorWithRed:224/255.0 green:224/255.0 blue:224/255.0 alpha:1.0];
    
    UIView *headerView = [[UIView alloc] initWithFrame:bkgToolbar.frame];
    [headerView addSubview:bkgToolbar];
    [headerView addSubview:addDiveButton];
    [headerView addSubview:separatorView];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kCellHeight + 1;
}

#pragma mark - Additional actions

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([searchText isEqualToString:@""]) {
        _divesList = _initialDivesList;
    } else {
        _divesList = [_initialDivesList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(name contains[cd] %@)", searchText]];
    }
    
    [self.tableView reloadData];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    self.tableView.allowsMultipleSelectionDuringEditing = editing;
    [self.tableView reloadData];
}

- (void)addNewDiveAction {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter dive name", "")
                                                        message:@""
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", "")
                                              otherButtonTitles:NSLocalizedString(@"Add", ""), nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.keyboardType = UIKeyboardTypeEmailAddress;
    textField.textAlignment = NSTextAlignmentCenter;
    textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    textField.placeholder = @"dive name";
    
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        UITextField *alertTextField = [alertView textFieldAtIndex:0];
        
        [SWEB addDive:alertTextField.text];
    }
}

#pragma mark - NSNotification methods

- (void)divesListReceived:(NSNotification *)notification {
    _divesList = [SDIVE getDives];
    _initialDivesList = _divesList.copy;
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
}

#pragma mark - UIRefreshControl handler

- (void)handleRefresh:(id)sender {
    [SWEB getDivesList:self.userID];
}

@end
