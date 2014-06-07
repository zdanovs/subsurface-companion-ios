//
//  SDivesListTVC.m
//  Subsurface
//
//  Created by Andrey Zhdanov on 24/05/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//

#import "SDivesListTVC.h"
#import "SDiveTableCell.h"
#import "SAddDiveTableCell.h"
#import "SCoreDiveService.h"

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
    self.tableView.contentOffset = CGPointMake(0, 44);
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _divesList.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *commonCell = nil;
    
    if (indexPath.row == 0) {
        SAddDiveTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddDiveCell" forIndexPath:indexPath];
        commonCell = cell;
    } else {
        SDiveTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DiveCell" forIndexPath:indexPath];
        [cell setupDiveCell:_divesList[indexPath.row - 1]];
        commonCell = cell;
    }
    
    return commonCell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        SDive *dive = _divesList[indexPath.row - 1];
        
        NSMutableArray *mutableDivesList = [_divesList mutableCopy];
        [mutableDivesList removeObject:dive];
        _divesList = [NSArray arrayWithArray:mutableDivesList];
        [self.tableView reloadData];
        
        [SWEB deleteDive:dive];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Detemine if it's in editing mode
    if (self.tableView.editing) {
        return UITableViewCellEditingStyleNone;
    }
    
    return UITableViewCellEditingStyleDelete;
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
    
    if (editing) {
        // Your code for entering edit mode goes here
    } else {
        // Your code for exiting edit mode goes here
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
