//
//  SDiveDetailsVC.m
//  Subsurface
//
//  Created by Andrey Zhdanov on 15/06/14.
//  Copyright (c) 2014 Subsurface. All rights reserved.
//

#import "SDiveDetailsVC.h"
#import "SDive.h"

#define kScaleFactor    7
#define kCircleRadius   50

@interface SDiveDetailsVC ()

@property (weak, nonatomic) IBOutlet UILabel *diveNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *diveDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *diveTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *diveLatitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *diveLongitudeLabel;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIImageView *circleBackgroundImageView;
@property (weak, nonatomic) IBOutlet UIView *tapAnimationView;

@property NSArray *viewsToToggle;

@end

@implementation SDiveDetailsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.viewsToToggle = @[self.diveNameLabel, self.diveDateLabel, self.diveLatitudeLabel, self.diveLongitudeLabel];
    
    self.diveNameLabel.text = self.dive.name;
    self.diveDateLabel.text = [self.dive getDateString];
    self.diveTimeLabel.text = [self.dive getTimeString];
    
    self.diveLatitudeLabel.text = [NSString stringWithFormat:@"%@", self.dive.latitude];
    self.diveLongitudeLabel.text = [NSString stringWithFormat:@"%@", self.dive.longitude];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(animateMapAppear)];
    [self.tapAnimationView addGestureRecognizer:tapRecognizer];
    
    [self adjustMapAppear];
}

- (void)adjustMapAppear {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(self.dive.latitude.floatValue, self.dive.longitude.floatValue);
    
    // Add pin to map
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = coordinate;
    annotation.title = self.dive.name;
    annotation.subtitle = self.diveDateLabel.text;
    [self.mapView addAnnotation:annotation];
    
    // Show location in center of screen
    MKCoordinateSpan span = MKCoordinateSpanMake(0.05, 0.05);
    MKCoordinateRegion region = {coordinate, span};
    [self.mapView setRegion:region];
    
    // Move map to fit in circle
    coordinate.latitude += self.mapView.region.span.latitudeDelta * 0.22;
    [self.mapView setCenterCoordinate:coordinate animated:YES];
}

- (void)animateMapAppear {
    [UIView animateWithDuration:1.0f
                     animations:^{
                         self.circleBackgroundImageView.transform = CGAffineTransformMakeScale(kScaleFactor, kScaleFactor);
                         self.circleBackgroundImageView.center = CGPointMake(kCircleRadius * kScaleFactor / 2, -kCircleRadius * kScaleFactor);
                         
                         for (UIView *view in self.viewsToToggle) {
                             view.alpha = 0.0f;
                         }
                     } completion:^(BOOL finished){
                         for (UIView *view in self.viewsToToggle) {
                             view.hidden = YES;
                         }
                         
                         self.circleBackgroundImageView.hidden = YES;
                         self.tapAnimationView.hidden = YES;
                     }];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
//    self.tableView.allowsMultipleSelectionDuringEditing = editing;
//    [self.tableView reloadData];
//    
//    [self.navigationController setToolbarHidden:!editing animated:YES];
//    [self updateBottomToolbarButtonsState];
}

@end
