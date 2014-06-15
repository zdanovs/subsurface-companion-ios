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

@property (weak, nonatomic) IBOutlet UIView *diveInfoContainer;
@property (weak, nonatomic) IBOutlet UILabel *diveNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *diveDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *diveTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *diveLatitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *diveLongitudeLabel;

@property (weak, nonatomic) IBOutlet UIView *editableInfoContainer;
@property (weak, nonatomic) IBOutlet UIImageView *editableNameUnderline;
@property (weak, nonatomic) IBOutlet UITextField *editableNameLabel;
@property (weak, nonatomic) IBOutlet UITextField *editableDateLabel;
@property (weak, nonatomic) IBOutlet UITextField *editableTimeLabel;
@property (weak, nonatomic) IBOutlet UITextField *editableLatitudeLabel;
@property (weak, nonatomic) IBOutlet UITextField *editableLongitudeLabel;

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
    
    self.editableNameLabel.text = self.diveNameLabel.text;
    self.editableDateLabel.text = self.diveDateLabel.text;
    self.editableTimeLabel.text = self.diveTimeLabel.text;
    self.editableLatitudeLabel.text = self.diveLatitudeLabel.text;
    self.editableLongitudeLabel.text = self.diveLongitudeLabel.text;
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showMap)];
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

- (void)showMap {
    [self animateMapAppear:YES];
}

- (void)closeMap {
    [self animateMapAppear:NO];
}

- (void)animateMapAppear:(BOOL)show {
    UIBarButtonItem *closeMapButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close Map", "")
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(closeMap)];
    [self.navigationItem setRightBarButtonItem:show ? closeMapButton : self.editButtonItem animated:YES];
    
    [UIView animateWithDuration:1.0f
                     animations:^{
                         CGFloat scaleFactor = show ? kScaleFactor : 1.0f;
                         self.diveInfoContainer.alpha = show ? 0.0f : 1.0f;
                         self.circleBackgroundImageView.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
                         
                         CGPoint scalePoint = show ? CGPointMake(kCircleRadius * scaleFactor / 2, -kCircleRadius * scaleFactor) : CGPointMake(160, 316);
                         self.circleBackgroundImageView.center = scalePoint;
                     } completion:^(BOOL finished){
                         self.tapAnimationView.hidden = show;
                     }];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    self.diveInfoContainer.hidden = editing;
    self.editableInfoContainer.hidden = !editing;
    
    if (editing) {
        self.editableNameLabel.text = self.diveNameLabel.text;
        self.editableDateLabel.text = self.diveDateLabel.text;
        self.editableTimeLabel.text = self.diveTimeLabel.text;
        self.editableLatitudeLabel.text = self.diveLatitudeLabel.text;
        self.editableLongitudeLabel.text = self.diveLongitudeLabel.text;
        
        [self.editableNameLabel becomeFirstResponder];
    } else {
        self.diveNameLabel.text = self.editableNameLabel.text;
        self.diveDateLabel.text = self.editableDateLabel.text;
        self.diveTimeLabel.text = self.editableTimeLabel.text;
        self.diveLatitudeLabel.text = self.editableLatitudeLabel.text;
        self.editableLongitudeLabel.text = self.editableLongitudeLabel.text;
        
        [self.view endEditing:YES];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
    [self setEditing:NO animated:YES];
}

@end
