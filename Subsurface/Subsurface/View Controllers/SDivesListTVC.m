//
//  SDivesListTVC.m
//  Subsurface
//
//  Created by Andrey Zhdanov on 24/05/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//

#import "SDivesListTVC.h"
#import "SDiveTableCell.h"
#import "SDiveDetailsVC.h"
#import "SCoreDiveService.h"

#define kCellHeight    54.0f
#define kHeaderHeight    45.0f

@interface SDivesListTVC ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *uploadDivesButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteDivesButton;

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
    
    _divesList = [SDIVE getDives];
    _initialDivesList = _divesList.copy;
    
    if (self.divesList.count < 1) {
        [SWEB getDivesList:self.userID];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(divesListReceived:)
                                                 name:kDivesListLoadNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = NO;
    self.tableView.contentOffset = CGPointMake(0, kHeaderHeight);
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self updateBottomToolbarButtonsState];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self updateBottomToolbarButtonsState];
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
    UIToolbar *bkgToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, kHeaderHeight)];

    UIButton *addDiveButton = [[UIButton alloc] initWithFrame:bkgToolbar.frame];
    addDiveButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
    [addDiveButton setTitle:NSLocalizedString(@"Add Dive", @"") forState:UIControlStateNormal];
    [addDiveButton addTarget:self action:@selector(addNewDiveAction) forControlEvents:UIControlEventTouchUpInside];
    [addDiveButton setTitleColor:[UIColor colorWithRed:0 green:0.478431 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    
    UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(0, kHeaderHeight - 1, self.tableView.frame.size.width, 1)];
    separatorView.backgroundColor = [UIColor colorWithRed:224/255.0 green:224/255.0 blue:224/255.0 alpha:1.0];
    
    UIView *headerView = [[UIView alloc] initWithFrame:bkgToolbar.frame];
    [headerView addSubview:bkgToolbar];
    [headerView addSubview:addDiveButton];
    [headerView addSubview:separatorView];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kHeaderHeight;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    self.tableView.allowsMultipleSelectionDuringEditing = editing;
    [self.tableView reloadData];
    
    [self.navigationController setToolbarHidden:!editing animated:YES];
    [self updateBottomToolbarButtonsState];
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

#pragma mark - UIButtons actions

- (IBAction)uploadDivesButtonAction:(id)sender {
    NSArray *selectedDives = [self getSelectedDives];
    
    for (SDive *dive in selectedDives) {
        [SWEB uploadDive:dive];
    }
    
    [self.tableView setEditing:NO animated:YES];
    [self.tableView reloadData];
}

- (IBAction)deleteDivesButtonAction:(id)sender {
    NSArray *selectedDives = [self getSelectedDives];
    
    NSMutableArray *mutableDivesList = self.divesList.mutableCopy;
    [mutableDivesList removeObjectsInArray:selectedDives];
    self.divesList = mutableDivesList.copy;
    
    for (SDive *dive in selectedDives) {
        [SWEB deleteDive:dive];
    }
    
    [self.tableView deleteRowsAtIndexPaths:[self.tableView indexPathsForSelectedRows] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView setEditing:NO animated:YES];
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
    textField.placeholder = @"Dive name";
    
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        UITextField *alertTextField = [alertView textFieldAtIndex:0];
        
        [SWEB addDive:alertTextField.text];
    }
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

- (void)updateBottomToolbarButtonsState {
    self.uploadDivesButton.enabled = [self.tableView indexPathsForSelectedRows].count > 0;
    self.deleteDivesButton.enabled = [self.tableView indexPathsForSelectedRows].count > 0;
}

- (NSArray *)getSelectedDives {
    NSMutableIndexSet *selectedIndexSet = [NSMutableIndexSet indexSet];
    
    NSArray *selectedPaths = [self.tableView indexPathsForSelectedRows];
    for (NSIndexPath *indexPath in selectedPaths) {
        [selectedIndexSet addIndex:indexPath.row];
    }
    
    return [self.divesList objectsAtIndexes:selectedIndexSet];
}

#pragma mark - Preparing Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"LoadDiveDetails"]) {
        SDiveTableCell *cell = (SDiveTableCell *)sender;
        
        SDiveDetailsVC *vc = [segue destinationViewController];
        vc.dive = cell.dive;
    }
}

#pragma mark - Status bar appear
- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

@end
