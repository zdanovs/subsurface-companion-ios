//
//  SDiveDetailsVC.m
//  Subsurface
//
//  Created by Andrey Zhdanov on 15/06/14.
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

#import "SDiveDetailsVC.h"
#import "SCoreDiveService.h"
#import "SWebService.h"
#import "SDive.h"

#define kScaleFactor    7
#define kCircleRadius   50

@interface SDiveDetailsVC ()

@property (weak, nonatomic) IBOutlet UIView  *diveInfoContainer;
@property (weak, nonatomic) IBOutlet UILabel *diveNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *diveDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *diveTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *diveLatitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *diveLongitudeLabel;

@property (weak, nonatomic) IBOutlet UIView      *editableInfoContainer;
@property (weak, nonatomic) IBOutlet UIImageView *editableNameUnderline;
@property (weak, nonatomic) IBOutlet UITextField *editableNameLabel;
@property (weak, nonatomic) IBOutlet UITextField *editableDateLabel;
@property (weak, nonatomic) IBOutlet UITextField *editableTimeLabel;
@property (weak, nonatomic) IBOutlet UIView      *coordinatesContainer;
@property (weak, nonatomic) IBOutlet UITextField *editableLatitudeLabel;
@property (weak, nonatomic) IBOutlet UITextField *editableLongitudeLabel;

@property (weak, nonatomic) IBOutlet MKMapView   *mapView;
@property (weak, nonatomic) IBOutlet UIImageView *circleBackgroundImageView;
@property (weak, nonatomic) IBOutlet UIView      *tapAnimationView;

@property CLLocationCoordinate2D coordinate;
@property NSSet *initialState;

@end

@implementation SDiveDetailsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self customBackButton];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.initialState =  [NSSet setWithArray:@[self.dive.name, self.dive.date, self.dive.latitude, self.dive.longitude]];
    
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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self adjustMapAppear];
}

- (void)adjustMapAppear {
    self.coordinate = CLLocationCoordinate2DMake(self.dive.latitude.floatValue, self.dive.longitude.floatValue);
    
    // Add pin to map
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = self.coordinate;
    annotation.title = self.dive.name;
    annotation.subtitle = self.diveDateLabel.text;
    [self.mapView addAnnotation:annotation];
    
    [self adjustPinPosition];
}

- (void)adjustPinPosition {
    // Show location in center of screen
    MKCoordinateSpan span = MKCoordinateSpanMake(0.05, 0.05);
    MKCoordinateRegion region = {self.coordinate, span};
    [self.mapView setRegion:region];
    
    // Move map to fit in circle
    CLLocationCoordinate2D moveCoord = self.coordinate;
    moveCoord.latitude += self.mapView.region.span.latitudeDelta * 0.22;
    [self.mapView setCenterCoordinate:moveCoord animated:YES];
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
                         
                         CGRect frame = self.coordinatesContainer.frame;
                         frame.origin.y = show ? 64 : 240;
                         self.coordinatesContainer.frame = frame;
                     } completion:^(BOOL finished){
                         self.tapAnimationView.hidden = show;
                         
                         if (!show) {
                             [self adjustPinPosition];
                         }
                     }];
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item {
    [self checkChangesInFields];
    
    return NO;
}

- (void)customBackButton {
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [leftButton addTarget:self action:@selector(checkChangesInFields) forControlEvents:UIControlEventTouchUpInside];
    [leftButton setImage:[UIImage imageNamed:@"icon-back.png"] forState:UIControlStateNormal];
    [leftButton setTitle:NSLocalizedString(@"Dives List", @"") forState:UIControlStateNormal];
    leftButton.tintColor = [UIColor colorWithRed:0 green:0.478431 blue:1.0 alpha:1.0];
    
    UIView *leftButtonView = [[UIView alloc]initWithFrame:CGRectMake(-13, 0, 100, 50)];
    leftButton.frame = leftButtonView.frame;
    [leftButtonView addSubview:leftButton];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:leftButtonView];
}

- (void)checkChangesInFields {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    
    NSString *newDiveName = self.editableNameLabel.text;
    NSNumber *newLatitude = [NSNumber numberWithFloat:self.coordinate.latitude];
    NSNumber *newLongitude = [NSNumber numberWithFloat:self.coordinate.longitude];
    NSDate *newDate = [dateFormatter dateFromString:[NSString stringWithFormat:@"%@ %@", self.editableDateLabel.text, self.editableTimeLabel.text]];
    
    NSSet *newState = [NSSet setWithArray:@[newDiveName, newDate, newLatitude, newLongitude]];
    BOOL equal = [self.initialState isEqualToSet:newState];
    
    if (!equal) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Save changes?", "")
                                                            message:NSLocalizedString(@"You have edited dive data", "")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Discard", "")
                                                  otherButtonTitles:NSLocalizedString(@"Save", ""), nil];
        [alertView show];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        
        NSString *newDiveName = self.editableNameLabel.text;
        NSNumber *newLatitude = [NSNumber numberWithFloat:self.coordinate.latitude];
        NSNumber *newLongitude = [NSNumber numberWithFloat:self.coordinate.longitude];
        NSDate *newDate = [dateFormatter dateFromString:[NSString stringWithFormat:@"%@ %@", self.editableDateLabel.text, self.editableTimeLabel.text]];
        
        [SWEB deleteDive:self.dive fully:NO];
        
        self.dive.name = newDiveName;
        self.dive.date = newDate;
        self.dive.latitude = newLatitude;
        self.dive.longitude = newLongitude;
        [SDIVE saveState];
        
        [SWEB uploadDive:self.dive fully:NO];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
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

#pragma mark - MKMapViewDelegate methods

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    static NSString *reuseId = @"pin";
    MKPinAnnotationView *pav = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseId];
    if (pav == nil) {
        pav = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseId];
        pav.draggable = YES;
        pav.canShowCallout = YES;
    } else {
        pav.annotation = annotation;
    }
    
    return pav;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    
    if (newState == MKAnnotationViewDragStateEnding) {
        self.coordinate = annotationView.annotation.coordinate;
        
        self.diveLatitudeLabel.text = [NSString stringWithFormat:@"%f", self.coordinate.latitude];
        self.diveLongitudeLabel.text = [NSString stringWithFormat:@"%f", self.coordinate.longitude];
        self.editableLatitudeLabel.text = self.diveLatitudeLabel.text;
        self.editableLongitudeLabel.text = self.diveLongitudeLabel.text;
    }
}

@end
