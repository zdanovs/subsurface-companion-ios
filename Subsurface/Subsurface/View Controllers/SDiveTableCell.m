//
//  SDiveTableCell.m
//  Subsurface
//
//  Created by Andrey Zhdanov on 24/05/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//

#import "SDiveTableCell.h"

@interface SDiveTableCell ()

@property (weak, nonatomic) IBOutlet UILabel *diveNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *diveDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *diveTimeLabel;

@end

@implementation SDiveTableCell

- (void)setupDiveCell:(NSDictionary *)diveDictionary {
    _diveNameLabel.text = diveDictionary[@"name"];
    _diveDateLabel.text = diveDictionary[@"date"];
    _diveTimeLabel.text = diveDictionary[@"time"];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
