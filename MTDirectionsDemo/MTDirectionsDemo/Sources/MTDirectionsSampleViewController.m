#import "MTDirectionsSampleViewController.h"
// Color Picker from https://github.com/hayashi311/Color-Picker-for-iOS
#import "HRColorPickerViewController.h"
#import <QuartzCore/QuartzCore.h>


@interface MTDirectionsSampleViewController () <MKMapViewDelegate, UITextFieldDelegate, HRColorPickerViewControllerDelegate>

@property (nonatomic, strong) MTDMapView *mapView;
@property (nonatomic, strong) UIColor *overlayColor;
@property (nonatomic, strong) MKPointAnnotation *fromAnnotation;
@property (nonatomic, strong) MKPointAnnotation *toAnnotation;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;

@property (nonatomic, strong) UIBarButtonItem *searchItem;
@property (nonatomic, strong) UIBarButtonItem *routeItem;
@property (nonatomic, strong) UIBarButtonItem *cancelItem;

@property (nonatomic, strong) UIView *routeBackgroundView;
@property (nonatomic, strong) UITextField *fromControl;
@property (nonatomic, strong) UITextField *toControl;
@property (nonatomic, strong) UILabel *distanceControl;
@property (nonatomic, strong) UIButton *colorChooserControl;
@property (nonatomic, strong) UIPopoverController *colorPopoverController;

@property (nonatomic, readonly, getter = isSearchUIVisible) BOOL searchUIVisible;
@property (nonatomic, readonly) MTDDirectionsRouteType routeType;

- (void)handleSearchItemPress:(id)sender;
- (void)handleRouteItemPress:(id)sender;
- (void)handleCancelItemPress:(id)sender;
- (void)handleColorChooserPress:(id)sender;

- (void)hideRouteView;
- (void)performSearch;

- (void)showLoadingIndicator;
- (void)hideLoadingIndicator;

@end


@implementation MTDirectionsSampleViewController

@synthesize mapView = _mapView;
@synthesize overlayColor = _overlayColor;
@synthesize fromAnnotation = _fromAnnotation;
@synthesize toAnnotation = _toAnnotation;
@synthesize segmentedControl = _segmentedControl;
@synthesize searchItem = _searchItem;
@synthesize routeItem = _routeItem;
@synthesize cancelItem = _cancelItem;
@synthesize routeBackgroundView = _routeBackgroundView;
@synthesize fromControl = _fromControl;
@synthesize toControl = _toControl;
@synthesize distanceControl = _distanceControl;
@synthesize colorChooserControl = _colorChooserControl;
@synthesize colorPopoverController = _colorPopoverController;

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

+ (id)viewController {
    return [[self alloc] initWithNibName:nil bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.title = @"MTDirectionsKit";
        _overlayColor = [UIColor colorWithRed:0.f green:0.25f blue:1.f alpha:1.f];
        
        MTDDirectionsSetLogLevel(MTDLogLevelVerbose);
        MTDDirectionsSetActiveAPI(MTDDirectionsAPIGoogle);
    }
    
    return self;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIViewController
////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad {
    [super viewDidLoad];
    
	self.mapView = [[MTDMapView alloc] initWithFrame:self.view.bounds];
    self.mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.mapView.delegate = self;
    self.mapView.region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(51.459596, -0.973277),
                                                 MKCoordinateSpanMake(0.026846, 0.032959));
    [self.view addSubview:self.mapView];
    
    self.distanceControl = [[UILabel alloc] initWithFrame:CGRectMake(0.f, self.view.bounds.size.height - 35.f, self.view.bounds.size.width, 35.f)];
    self.distanceControl.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    self.distanceControl.backgroundColor = [UIColor colorWithWhite:0.2f alpha:0.6f];
    self.distanceControl.font = [UIFont boldSystemFontOfSize:14.f];
    self.distanceControl.textColor = [UIColor whiteColor];
    self.distanceControl.textAlignment = UITextAlignmentCenter;
    self.distanceControl.shadowColor = [UIColor blackColor];
    self.distanceControl.shadowOffset = CGSizeMake(0.f, 1.f);
    self.distanceControl.text = @"Try MTDirectionsKit, it's great!";
    [self.view addSubview:self.distanceControl];
    
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:
                                                                       [UIImage imageNamed:@"pedestrian"],
                                                                       [UIImage imageNamed:@"bicycle"],
                                                                       [UIImage imageNamed:@"car"], nil]];
    self.segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    self.segmentedControl.selectedSegmentIndex = 2;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.segmentedControl.tintColor = [UIColor lightGrayColor];
    }
    
    self.searchItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch
                                                                    target:self
                                                                    action:@selector(handleSearchItemPress:)];
    self.navigationItem.leftBarButtonItem = self.searchItem;
    
    self.routeItem = [[UIBarButtonItem alloc] initWithTitle:@"Route" 
                                                      style:UIBarButtonItemStyleDone
                                                     target:self 
                                                     action:@selector(handleRouteItemPress:)];
    
    self.cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" 
                                                       style:UIBarButtonItemStyleBordered
                                                      target:self 
                                                      action:@selector(handleCancelItemPress:)];
    
    self.routeBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.f, -75.f, self.view.bounds.size.width, 75.f)];
    self.routeBackgroundView.backgroundColor = [UIColor colorWithRed:119.f/255.f green:141.f/255.f blue:172.f/255.f alpha:1.f];
    self.routeBackgroundView.alpha = 0.f;
    [self.view addSubview:self.routeBackgroundView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 0.f, 50.f, 20.f)];
    
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor grayColor];
    label.textAlignment = UITextAlignmentRight;
    label.text = @"Start:";
    
    self.colorChooserControl = [UIButton buttonWithType:UIButtonTypeCustom];
    self.colorChooserControl.backgroundColor = [UIColor blueColor];
    self.colorChooserControl.layer.borderColor = [UIColor grayColor].CGColor;
    self.colorChooserControl.layer.borderWidth = 1.f;
    self.colorChooserControl.layer.cornerRadius = 8.f;
    self.colorChooserControl.frame = CGRectMake(self.routeBackgroundView.frame.size.width - 45.f, 5.f, 
                                                40.f, self.routeBackgroundView.frame.size.height - 10.f);
    [self.colorChooserControl addTarget:self action:@selector(handleColorChooserPress:) forControlEvents:UIControlEventTouchUpInside];
    [self.routeBackgroundView addSubview:self.colorChooserControl];
    
    self.fromControl = [[UITextField alloc] initWithFrame:CGRectMake(5.f, 5.f,
                                                                     self.routeBackgroundView.bounds.size.width-self.colorChooserControl.bounds.size.width - 15.f, 30.f)];
    self.fromControl.borderStyle = UITextBorderStyleRoundedRect;
    self.fromControl.leftViewMode = UITextFieldViewModeAlways;
    self.fromControl.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    label.font = self.fromControl.font;
    self.fromControl.leftView = label;
    self.fromControl.returnKeyType = UIReturnKeyNext;
    self.fromControl.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.fromControl.delegate = self;
    self.fromControl.text = @"Güssing, Österreich";
    self.fromControl.placeholder = @"Address or Lat/Lng";
    [self.routeBackgroundView addSubview:self.fromControl];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(0.f, 0.f, 50.f, 20.f)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor grayColor];
    label.textAlignment = UITextAlignmentRight;
    label.font = self.fromControl.font;
    label.text = @"End:";
    
    self.toControl = [[UITextField alloc] initWithFrame:CGRectMake(5.f, self.fromControl.frame.origin.y + self.fromControl.frame.size.height + 5.f,
                                                                   self.routeBackgroundView.bounds.size.width-self.colorChooserControl.bounds.size.width - 15.f, 30.f)];
    self.toControl.borderStyle = UITextBorderStyleRoundedRect;
    self.toControl.leftViewMode = UITextFieldViewModeAlways;
    self.toControl.leftView = label;
    self.toControl.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.toControl.returnKeyType = UIReturnKeyRoute;
    self.toControl.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.toControl.delegate = self;
    self.toControl.text = @"Wien";
    self.toControl.placeholder = @"Address or Lat/Lng";
    [self.routeBackgroundView addSubview:self.toControl];
    
    CLLocationCoordinate2D from = CLLocationCoordinate2DMake(51.4554, -0.9742); // Reading
    CLLocationCoordinate2D to = CLLocationCoordinate2DMake(51.38713, -1.0316);  // NSConference
    CLLocationCoordinate2D intermediateGoal1 = CLLocationCoordinate2DMake(51.3765, -1.003); // Beech Hill
    CLLocationCoordinate2D intermediateGoal2 = CLLocationCoordinate2DMake(51.4388, -0.9409); // University
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        [self.mapView loadDirectionsFrom:[MTDWaypoint waypointWithCoordinate:from]
                                      to:[MTDWaypoint waypointWithCoordinate:to]
                       intermediateGoals:[NSArray arrayWithObjects:
                                          [MTDWaypoint waypointWithCoordinate:intermediateGoal1],
                                          [MTDWaypoint waypointWithCoordinate:intermediateGoal2],
                                          nil]
                               routeType:MTDDirectionsRouteTypeFastestDriving
                    zoomToShowDirections:YES];
    });
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    self.mapView.delegate = nil;
    self.mapView = nil;
    self.fromAnnotation = nil;
    self.toAnnotation = nil;
    self.searchItem = nil;
    self.routeItem = nil;
    self.cancelItem = nil;
    self.navigationItem.leftBarButtonItem = nil;
    self.segmentedControl = nil;
    self.routeBackgroundView = nil;
    self.fromControl = nil;
    self.toControl = nil;
    self.distanceControl = nil;
    self.colorChooserControl = nil;
    self.colorPopoverController = nil;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - MTDDirectionsDelegate
////////////////////////////////////////////////////////////////////////

- (void)mapView:(MTDMapView *)mapView willStartLoadingDirectionsFrom:(MTDWaypoint *)from to:(MTDWaypoint *)to routeType:(MTDDirectionsRouteType)routeType {
    NSLog(@"MapView %@ willStartLoadingDirectionsFrom:%@ to:%@ routeType:%d",
          mapView,
          from,
          to,
          routeType);
    
    [self showLoadingIndicator];
}

- (MTDDirectionsOverlay *)mapView:(MTDMapView *)mapView didFinishLoadingDirectionsOverlay:(MTDDirectionsOverlay *)directionsOverlay {
    NSLog(@"MapView %@ didFinishLoadingDirectionsOverlay: %@ (fromAddress:%@, toAddress:%@)",
          mapView, directionsOverlay, directionsOverlay.fromAddress, directionsOverlay.toAddress);
    
    self.distanceControl.text = [NSString stringWithFormat:@"Distance: %@, Time: %@", 
                                 [directionsOverlay.distance description],
                                 MTDGetFormattedTime(directionsOverlay.timeInSeconds)];
    
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    self.fromAnnotation = [[MKPointAnnotation alloc] init];
    self.fromAnnotation.coordinate = directionsOverlay.fromCoordinate;
    
    self.toAnnotation = [[MKPointAnnotation alloc] init];
    self.toAnnotation.coordinate = directionsOverlay.toCoordinate;
    
    [self.mapView addAnnotation:self.fromAnnotation];
    [self.mapView addAnnotation:self.toAnnotation];
    
    [self hideLoadingIndicator];
    
    return directionsOverlay;
}

- (void)mapView:(MTDMapView *)mapView didFailLoadingDirectionsOverlayWithError:(NSError *)error {
    NSLog(@"MapView %@ didFailLoadingDirectionsOverlayWithError: %@", mapView, error);
    
    self.distanceControl.text = [error.userInfo objectForKey:MTDDirectionsKitErrorMessageKey];
    [self.mapView removeAnnotations:self.mapView.annotations];
    self.fromAnnotation = nil;
    self.toAnnotation = nil;
    
    [self hideLoadingIndicator];
}

- (UIColor *)mapView:(MTDMapView *)mapView colorForDirectionsOverlay:(MTDDirectionsOverlay *)directionsOverlay {
    NSLog(@"MapView %@ colorForDirectionsOverlay: %@", mapView, directionsOverlay);
    
    return self.overlayColor;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - MKMapViewDelegate
////////////////////////////////////////////////////////////////////////

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    MKPinAnnotationView *pin = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"MTDirectionsKitAnnotation"];
    
    if (pin == nil) {
        pin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MTDirectionsKitAnnotation"];
    } else {
        pin.annotation = annotation;
    }
    
    pin.draggable = YES;
    pin.animatesDrop = YES;
    
    if (annotation == self.fromAnnotation) {
        pin.pinColor = MKPinAnnotationColorGreen;
    } else {
        pin.pinColor = MKPinAnnotationColorPurple;
    }
    
    return pin;
}


- (void)mapView:(MKMapView *)mapView
 annotationView:(MKAnnotationView *)annotationView
didChangeDragState:(MKAnnotationViewDragState)newState 
   fromOldState:(MKAnnotationViewDragState)oldState {
    
    if(newState == MKAnnotationViewDragStateEnding) {
        [self.mapView loadDirectionsFrom:self.fromAnnotation.coordinate
                                      to:self.toAnnotation.coordinate
                               routeType:self.routeType
                    zoomToShowDirections:NO];
        
        self.fromControl.text = [NSString stringWithFormat:@"%f/%f", 
                                 self.fromAnnotation.coordinate.latitude,
                                 self.fromAnnotation.coordinate.longitude];
        self.toControl.text = [NSString stringWithFormat:@"%f/%f", 
                               self.toAnnotation.coordinate.latitude,
                               self.toAnnotation.coordinate.longitude];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UITextFieldDelegate
////////////////////////////////////////////////////////////////////////

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.fromControl) {
        [self.toControl becomeFirstResponder];
    } else {
        [self performSearch];
    }
    
    return NO;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - HRColorPickerViewControllerDelegate
////////////////////////////////////////////////////////////////////////

- (void)setSelectedColor:(UIColor *)color {
    self.overlayColor = color;
    self.mapView.directionsOverlayView.overlayColor = color;
    self.colorChooserControl.backgroundColor = color;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (BOOL)isSearchUIVisible {
    return self.navigationItem.titleView == self.segmentedControl;
}

- (MTDDirectionsRouteType)routeType {
    if (self.segmentedControl.selectedSegmentIndex == 0) {
        return MTDDirectionsRouteTypePedestrian;
    } else if (self.segmentedControl.selectedSegmentIndex == 1) {
        return MTDDirectionsRouteTypeBicycle;
    } else {
        return MTDDirectionsRouteTypeFastestDriving;
    }
}

- (void)handleSearchItemPress:(id)sender {
    self.navigationItem.titleView = self.segmentedControl;
    [self.navigationItem setLeftBarButtonItem:self.cancelItem animated:YES];
    [self.navigationItem setRightBarButtonItem:self.routeItem animated:YES];
    
    CGRect frame = self.routeBackgroundView.frame;
    frame.origin.y = - frame.size.height;
    self.routeBackgroundView.frame = frame;
    frame.origin.y = 0.f;
    
    [self.fromControl becomeFirstResponder];
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.routeBackgroundView.frame = frame;
                         self.routeBackgroundView.alpha = 1.f;
                     }];
}

- (void)handleCancelItemPress:(id)sender {
    self.fromControl.text = @"";
    self.toControl.text = @"";
    
    [self hideRouteView];
}

- (void)handleRouteItemPress:(id)sender {
    [self performSearch];
}

- (void)handleColorChooserPress:(id)sender {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        HRColorPickerViewController *colorPickerViewController = [HRColorPickerViewController cancelableColorPickerViewControllerWithColor:self.overlayColor];
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:colorPickerViewController];
        
        colorPickerViewController.delegate = self;
        [self presentModalViewController:navigationController animated:YES];
    } else {
        HRColorPickerViewController *colorPickerViewController = [HRColorPickerViewController colorPickerViewControllerWithColor:self.overlayColor];
        
        colorPickerViewController.delegate = self;
        
        self.colorPopoverController = [[UIPopoverController alloc] initWithContentViewController:colorPickerViewController];
        self.colorPopoverController.popoverContentSize = CGSizeMake(320.f, 416.f);
        [self.colorPopoverController presentPopoverFromRect:self.colorChooserControl.frame
                                                     inView:self.view
                                   permittedArrowDirections:UIPopoverArrowDirectionUp
                                                   animated:YES];
    }
}

- (void)hideRouteView {
    self.navigationItem.titleView = nil;
    [self.navigationItem setLeftBarButtonItem:self.searchItem animated:YES];
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
    
    CGRect frame = self.routeBackgroundView.frame;
    frame.origin.y = - frame.size.height;
    
    [self.view endEditing:YES];
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.routeBackgroundView.frame = frame;
                         self.routeBackgroundView.alpha = 0.f;
                     }];
}

- (void)performSearch {
    NSString *from = self.fromControl.text;
    NSString *to = self.toControl.text;
    NSArray *fromComponents = [[from stringByReplacingOccurrencesOfString:@" " withString:@""] componentsSeparatedByString:@"/"];
    NSArray *toComponents = [[to stringByReplacingOccurrencesOfString:@" " withString:@""] componentsSeparatedByString:@"/"];
    
    if (fromComponents.count == 2 && toComponents.count == 2) {
        CLLocationCoordinate2D fromCoordinate = CLLocationCoordinate2DMake([[fromComponents objectAtIndex:0] doubleValue], [[fromComponents objectAtIndex:1] doubleValue]);
        CLLocationCoordinate2D toCoordinate = CLLocationCoordinate2DMake([[toComponents objectAtIndex:0] doubleValue], [[toComponents objectAtIndex:1] doubleValue]);
        
        [self.mapView loadDirectionsFrom:fromCoordinate
                                      to:toCoordinate
                               routeType:self.routeType
                    zoomToShowDirections:YES];
    } else if (fromComponents.count < 2 && toComponents.count < 2) {
        [self.mapView loadDirectionsFromAddress:from
                                      toAddress:to
                                      routeType:self.routeType
                           zoomToShowDirections:YES];
    } else {
        self.distanceControl.text = @"Invalid Input";
    }
    
    [self hideRouteView];
}

- (void)showLoadingIndicator {
    [self hideLoadingIndicator];
    
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 24.f, 26.f)];
    
    activityView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    activityView.autoresizingMask = UIViewAutoresizingNone;
    activityView.frame = CGRectMake(0.f, 2.f, 20.f, 20.f);
    [backgroundView addSubview:activityView];
    
    UIBarButtonItem *activityItem = [[UIBarButtonItem alloc] initWithCustomView:backgroundView];
    self.navigationItem.rightBarButtonItem = activityItem;
    
    [activityView startAnimating];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)hideLoadingIndicator {
    self.navigationItem.rightBarButtonItem = nil;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

@end
