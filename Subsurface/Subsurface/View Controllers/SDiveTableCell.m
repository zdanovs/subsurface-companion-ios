//
//  SDiveTableCell.m
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

#import "SDiveTableCell.h"
#import "SCoreDiveService.h"

@interface SDiveTableCell ()

@property (weak, nonatomic) IBOutlet UILabel *diveNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *diveDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *diveTimeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *cloudImageView;

@end

@implementation SDiveTableCell

- (void)setupDiveCell:(SDive *)dive {
    self.dive = dive;
    
    _diveNameLabel.text = dive.name;
    _diveDateLabel.text = [dive getDateString];
    _diveTimeLabel.text = [dive getTimeString];
    
    [UIView animateWithDuration:0.5f animations:^{
        self.cloudImageView.alpha = dive.uploaded.boolValue ? 0.6f : 0.0f;
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
