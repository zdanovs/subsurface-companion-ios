//
//  SDivesListTVC.m
//  Subsurface
//
//  Created by Andrey Zhdanov on 24/05/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//

#import "SDivesListTVC.h"
#import "SDiveTableCell.h"

@interface SDivesListTVC ()

@property NSArray *divesList;
@property NSArray *initialDivesList;

@end

@implementation SDivesListTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = self.refreshControl;
    [self.refreshControl beginRefreshing];
    
    _divesList = [NSArray array];
    [SWEB getDivesList:self.userID];
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
    return _divesList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SDiveTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DiveCell" forIndexPath:indexPath];
    
    [cell setupDiveCell:_divesList[indexPath.row]];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSDictionary *dive = _divesList[indexPath.row];
        
        NSMutableArray *mutableDivesList = [_divesList mutableCopy];
        [mutableDivesList removeObject:dive];
        _divesList = [NSArray arrayWithArray:mutableDivesList];
        [self.tableView reloadData];
        
        [SWEB deleteDive:dive];
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
 */

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if ([searchText isEqualToString:@""]) {
        _divesList = _initialDivesList;
    } else {
        _divesList = [_initialDivesList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(name contains[cd] %@)", searchText]];
    }
    
    [self.tableView reloadData];
}

#pragma mark - NSNotification methods

- (void)divesListReceived:(NSNotification *)notification {
    _divesList = notification.object;
    _initialDivesList = _divesList.copy;
    [self.refreshControl endRefreshing];
    [self.tableView reloadData];
}

#pragma mark - UIRefreshControl handler

- (void)handleRefresh:(id)sender {
    [SWEB getDivesList:self.userID];
}

@end
