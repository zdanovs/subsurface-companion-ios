//
//  SDiveTableCell.m
//  Subsurface
//
//  Created by Andrey Zhdanov on 24/05/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
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
    _diveNameLabel.text = dive.name;
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm:ss"];
    NSString *dateString = [dateFormat stringFromDate:dive.date];
    NSString *timeString = [timeFormat stringFromDate:dive.date];
    
    _diveDateLabel.text = dateString;
    _diveTimeLabel.text = timeString;
    
    [UIView animateWithDuration:0.5f animations:^{
        self.cloudImageView.alpha = dive.uploaded.boolValue ? 0.6f : 0.0f;
    }];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
