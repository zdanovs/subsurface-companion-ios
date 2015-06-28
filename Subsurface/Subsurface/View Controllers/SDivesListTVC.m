//
//  SDivesListTVC.m
//  Subsurface
//
//  Created by Andrey Zhdanov on 24/05/14.
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

#import "SDivesListTVC.h"
#import "SDiveTableCell.h"
#import "SDiveDetailsVC.h"
#import "SCoreDiveService.h"

#define kCellHeight     54.0f
#define kHeaderHeight   45.0f

#define kChooseDiveOptionAlertTag   1
#define kAddNewDiveAlertTag         2

@interface SDivesListTVC ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *uploadDivesButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteDivesButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *allSelectDeselectButton;

@property NSArray   *divesList;
@property NSArray   *initialDivesList;
@property BOOL      vcAlreadyLoaded;

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(divesListReceived:)
                                                 name:kDivesListLoadNotification
                                               object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(wrongUserID:)
												 name:kWrongUserID
											   object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBarHidden = NO;
    self.tableView.contentOffset = CGPointMake(0, kHeaderHeight);
    
    [self.tableView reloadData];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL shouldSync = [[userDefaults objectForKey:kPreferencesSyncKey] boolValue];
    if (shouldSync && !self.vcAlreadyLoaded) {
        [self.refreshControl beginRefreshing];
        self.tableView.contentOffset = CGPointMake(0, -self.refreshControl.frame.size.height);
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL shouldSync = [[userDefaults objectForKey:kPreferencesSyncKey] boolValue];
    
    if (shouldSync && !self.vcAlreadyLoaded) {
        dispatch_queue_t modDateQueue = dispatch_queue_create("SyncDives Queue",NULL);
        dispatch_async(modDateQueue, ^{
            if ([SWEB internetIsAvailable:NSLocalizedString(@"Unable to perform auto-sync", "")]) {
                NSString *userID = [userDefaults objectForKey:kUserIdKey];
                [SWEB syncDives:userID];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.refreshControl endRefreshing];
            });
        });
    }
    
    self.vcAlreadyLoaded = YES;
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
    [self updateSelectAllButton];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self updateBottomToolbarButtonsState];
    [self updateSelectAllButton];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        SDive *dive = _divesList[indexPath.row];
        
        NSMutableArray *mutableDivesList = [_divesList mutableCopy];
        [mutableDivesList removeObject:dive];
        _divesList = [NSArray arrayWithArray:mutableDivesList];
        [self.tableView reloadData];
        
        [SWEB deleteDive:dive fully:YES];
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
    UIButton *addDiveButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, kHeaderHeight)];
    addDiveButton.showsTouchWhenHighlighted = YES;
    addDiveButton.backgroundColor = [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.9];
    addDiveButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
    [addDiveButton setTitle:NSLocalizedString(@"Add Dive", @"") forState:UIControlStateNormal];
    [addDiveButton addTarget:self action:@selector(chooseNewDiveOption) forControlEvents:UIControlEventTouchUpInside];
    [addDiveButton setTitleColor:[UIColor colorWithRed:0 green:122/255.0 blue:255/255.0 alpha:1.0] forState:UIControlStateNormal];
    
    return addDiveButton;
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

- (void)wrongUserID:(NSNotification *)notification {
	UIAlertView *wrongIDAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", "")
														   message:NSLocalizedString(@"Wrong user ID please try again", "")
														  delegate:self
												 cancelButtonTitle:NSLocalizedString(@"Ok", "")
												 otherButtonTitles: nil];
	[wrongIDAlert show];
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UIRefreshControl handler

- (void)handleRefresh:(id)sender {
    if ([SWEB internetIsAvailable:NSLocalizedString(@"Unable to refresh", "")]) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *userID = [userDefaults objectForKey:kUserIdKey];
        [SWEB syncDives:userID];
    } else {
        [self.refreshControl endRefreshing];
    }
}

#pragma mark - UIButtons actions

- (IBAction)uploadDivesButtonAction:(id)sender {
    if ([SWEB internetIsAvailable:NSLocalizedString(@"Unable to upload", "")]) {
        NSArray *selectedDives = [self getSelectedDives];
        
        for (SDive *dive in selectedDives) {
            [SWEB uploadDive:dive fully:YES];
        }
        
        [self setEditing:NO animated:YES];
        [self.tableView reloadData];
    }
}

- (IBAction)deleteDivesButtonAction:(id)sender {
    NSArray *selectedDives = [self getSelectedDives];
    
    NSMutableArray *mutableDivesList = self.divesList.mutableCopy;
    [mutableDivesList removeObjectsInArray:selectedDives];
    self.divesList = mutableDivesList.copy;
    
    for (SDive *dive in selectedDives) {
        [SWEB deleteDive:dive fully:YES];
    }
    
    [self.tableView deleteRowsAtIndexPaths:[self.tableView indexPathsForSelectedRows] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self setEditing:NO animated:YES];
}

- (IBAction)allSelectDeselectButtonAction:(id)sender {
    BOOL allDivesAreSelected = [self getSelectedDives].count == self.divesList.count;
    
    for (int i = 0; i < self.divesList.count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
        
        if (allDivesAreSelected) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
        } else {
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
    
    [self updateBottomToolbarButtonsState];
    [self updateSelectAllButton];
}

- (void)chooseNewDiveOption {
    BOOL serviceIsEnabled = [[[NSUserDefaults standardUserDefaults] objectForKey:kLocationServiceEnabledKey] boolValue];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add new dive", "")
                                                        message:nil
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", "")
                                              otherButtonTitles:nil];
    
    if (serviceIsEnabled) {
        [alertView addButtonWithTitle:NSLocalizedString(@"Add Manually", "")];
        [alertView setMessage:NSLocalizedString(@"Location service is already enabled, you can add only manually", "")];
    } else {
        [alertView setMessage:NSLocalizedString(@"How would you like to add new dive?", "")];
        [alertView addButtonWithTitle:NSLocalizedString(@"Manually", "")];
        [alertView addButtonWithTitle:NSLocalizedString(@"Automatically", "")];
    }
    
    alertView.tag = kChooseDiveOptionAlertTag;
    [alertView show];
}

- (void)addNewDiveAction {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter dive name", "")
                                                        message:@""
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", "")
                                              otherButtonTitles:NSLocalizedString(@"Add", ""), nil];
    alertView.tag = kAddNewDiveAlertTag;
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.keyboardType = UIKeyboardTypeEmailAddress;
    textField.textAlignment = NSTextAlignmentCenter;
    textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    textField.placeholder = NSLocalizedString(@"Dive name", @"");
    
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kChooseDiveOptionAlertTag) {
        if (buttonIndex == 1) {
            [self addNewDiveAction];
        } else if (buttonIndex == 2) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kLocationServiceStartNotification object:nil];
        }
    }
    else if (alertView.tag == kAddNewDiveAlertTag) {
        if (buttonIndex == 1) {
            UITextField *alertTextField = [alertView textFieldAtIndex:0];
            [SWEB addDive:alertTextField.text];
        }
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

- (void)updateSelectAllButton {
    BOOL allDivesAreSelected = [self getSelectedDives].count == self.divesList.count;
    self.allSelectDeselectButton.title = allDivesAreSelected ? NSLocalizedString(@"Deselect All", "") : NSLocalizedString(@"Select All", "");
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

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    return !self.tableView.editing;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"LoadDiveDetails"]) {
        SDiveTableCell *cell = (SDiveTableCell *)sender;
        
        SDiveDetailsVC *vc = [segue destinationViewController];
        vc.dive = cell.dive;
    }
}

#pragma mark - Status bar appear

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end
