//
//  LegMapViewController.m
//  Network Commuting
//
//  Created by John Canfield on 3/23/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "LegMapViewController.h"
#import "TestFlightSDK1/TestFlight.h"
#import "MyAnnotation.h"
#import "Step.h"
#import "RootMap.h"
#import "TwitterSearch.h"

@interface LegMapViewController()
// Utility routine for setting the region on the MapView based on the itineraryNumber
- (void)setMapViewRegion;
- (void)setDirectionsText;
- (void)refreshLegOverlay:(int)number;
@end

@implementation LegMapViewController

@synthesize itinerary;
@synthesize itineraryNumber;
@synthesize mapView;
@synthesize directionsView;
@synthesize directionsTitle;
@synthesize directionsDetails;
@synthesize feedbackButton;

NSString *legID;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[self navigationItem] setTitle:@"Nimbler"];
        
        // create the container to hold forward and back buttons
        /*
         UIView* container = [[UIView alloc] init];
        UIButton* backBBI = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [backBBI setTitle:@"Bak" forState:UIControlStateNormal];
        [backBBI addTarget:self action:@selector(navigateBack:) forControlEvents:UIControlEventTouchDown];
        // [container addSubview:backBBI];
        
        UIButton* forwardBBI = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [forwardBBI setTitle:@"For" forState:UIControlStateNormal];
        [forwardBBI addTarget:self action:@selector(navigateForward:) forControlEvents:UIControlEventTouchDown];
        // [container addSubview:forwardBBI];
        
        UILabel* label = [[UILabel alloc] init];
        [label setText:@"Howdy!"];
        [container addSubview:label];
        // Now add the container as the right BarButtonItem

        UIBarButtonItem* bbi = [[UIBarButtonItem alloc] initWithCustomView:container];
         */

        Bak = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(navigateBack:)]; 
        
        For = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(navigateForward:)]; 
        
       bbiArray = [NSArray arrayWithObjects:For, Bak, nil];
        self.navigationItem.rightBarButtonItems = bbiArray;

    }
    return self;
}

- (void)setItinerary:(Itinerary *)itin itineraryNumber:(int)num;
{
    itinerary = itin;
    itineraryNumber = num;
    
    // Add start and endpoint annotation
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSArray *sortedLegs = [itinerary sortedLegs];

    // Take startpoint as the beginning of the first leg's polyline, 
    // and endpoint form the last leg's polyline
    startPoint = [[MKPointAnnotation alloc] init];
    [startPoint setCoordinate:[[[sortedLegs objectAtIndex:0] polylineEncodedString] startCoord]];
    [mapView addAnnotation:startPoint];
    endPoint = [[MKPointAnnotation alloc] init];
    [endPoint setCoordinate:[[[sortedLegs objectAtIndex:([sortedLegs count]-1)] polylineEncodedString] endCoord]];
    [mapView addAnnotation:endPoint];

        
    // Add the overlays and dot AnnotationViews for paths to the mapView
    polyLineArray = [NSMutableArray array];
    for (int i=0; i < [sortedLegs count]; i++) {
        Leg* l = [sortedLegs objectAtIndex:i];
        MKPolyline *polyLine = [[l polylineEncodedString] polyline];
        [polyLineArray addObject:polyLine];
        [mapView addOverlay:polyLine];
        
        MKPointAnnotation* dotPoint = [[MKPointAnnotation alloc] init];
        [dotPoint setCoordinate:[[l polylineEncodedString] endCoord]];
        [mapView addAnnotation:dotPoint];
    }
    NSLog(@"ViewWillAppear, polyLineArray count = %d",[polyLineArray count]);
    
    [self setMapViewRegion];   // update the mapView region to correspond to the numItinerary item
    [self setDirectionsText];  // update the directions text accordingly
    [mapView setShowsUserLocation:YES];  // track user location
}

- (void)setMapViewRegion {
    if (itineraryNumber == 0) {  // if the startpoint set region in a 200m x 200m box around it
        [mapView setRegion:MKCoordinateRegionMakeWithDistance([startPoint coordinate],200, 200)]; 
    }
    else if (itineraryNumber == [[itinerary sortedLegs] count] + 1) {
        [mapView setRegion:MKCoordinateRegionMakeWithDistance([endPoint coordinate],200, 200)]; 
    }
    else { 
        // if inineraryNumber is pointing to a leg, then set the bound around the polyline
        MKMapRect mpRect = [[polyLineArray objectAtIndex:(itineraryNumber-1)] boundingMapRect];
        MKCoordinateRegion mpRegion = MKCoordinateRegionForMapRect(mpRect);
        // Move the center down by 15% of span so that route is not obscured by directions text
        mpRegion.center.latitude = mpRegion.center.latitude + mpRegion.span.latitudeDelta*0.20;
        // zoom out the map by 15% (lat) and 20% (long)
        mpRegion.span.latitudeDelta = mpRegion.span.latitudeDelta * 1.2; 
        mpRegion.span.longitudeDelta = mpRegion.span.longitudeDelta * 1.15;
        // Create a 100m x 100m coord region around the center, and choose that if bigger
        MKCoordinateRegion minRegion = MKCoordinateRegionMakeWithDistance(mpRegion.center, 100.0, 100.0);
        if ((minRegion.span.latitudeDelta > mpRegion.span.latitudeDelta) &&
            (minRegion.span.longitudeDelta > mpRegion.span.longitudeDelta)) {
            mpRegion = minRegion;  // if minRegion is larger, replace mpRegion with it
        }
        
        [mapView setRegion:mpRegion];
    }
}

- (void)setDirectionsText 
{
    NSString* titleText;
    NSString* subTitle;
    if (itineraryNumber == 0) { // if first row, put in start point
        titleText = [NSString stringWithFormat:@"Start at %@", [[itinerary from] name]];
       //Disable to see previous leg view
        [Bak setEnabled:false];
    }
    else if (itineraryNumber == [[itinerary sortedLegs] count] + 1) { // if last row, put in end point
        titleText = [NSString stringWithFormat:@"End at %@", [[itinerary to] name]];
         //Disable to see next leg view
        [For setEnabled:false];
    }
    else {  // otherwise, it is one of the legs
        Leg *leg = [[itinerary sortedLegs] objectAtIndex:(itineraryNumber-1)];
        titleText = [leg directionsTitleText];
        subTitle = [leg directionsDetailText];
        legID = [leg legId];
        if ([leg isTrain]) {
            NSString *train = [[titleText componentsSeparatedByString:@"("] objectAtIndex:1];
            NSString *train1 = [[train componentsSeparatedByString:@")"] objectAtIndex:0];
            train1 = [train1 stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
            NSLog(@"It is a train %@",train1 );
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject:train1 forKey:@"train"];
        }
        
    // It calls when MODe of leg is WaLK.
      //  [self walk];
    }
    
    [directionsTitle setText:titleText];
    [directionsDetails setText:subTitle];
}

// Callback for when user presses the navigate back button on the right navbar
- (IBAction)navigateBack:(id)sender {
    // Go back to the previous step
    if (itineraryNumber > 0) {
        itineraryNumber--;
    }
    [self refreshLegOverlay:itineraryNumber+1];  // refreshes the previous itinerary number
    [self refreshLegOverlay:itineraryNumber];   // refreshes the new itinerary number
    [self setMapViewRegion];  // redefine the bounding box
    [self setDirectionsText];
     [Bak setEnabled:TRUE];
    [For setEnabled:TRUE];
    if(itineraryNumber == 0){
        //self.navigationItem.rightBarButtonItems = nil;
        //self.navigationItem.rightBarButtonItem = For;
        [Bak setEnabled:false];
    }
    
}

// Callback for when user presses the navigate forward button on the right navbar
- (IBAction)navigateForward:(id)sender {
    NSArray *sortedLegs = [itinerary sortedLegs];
    // Go forward to the next step
    if (itineraryNumber <= [sortedLegs count]) {
        itineraryNumber++;
    }
    [self refreshLegOverlay:itineraryNumber-1];  // refreshes the last itinerary number
    [self refreshLegOverlay:itineraryNumber];   // refreshes the new itinerary number
    [self setMapViewRegion];  // redefine the bounding box
    [self setDirectionsText];
    [Bak setEnabled:TRUE];
    [For setEnabled:TRUE];
    if(itineraryNumber == [[itinerary sortedLegs] count] + 1){       
        //self.navigationItem.rightBarButtonItem = Bak;
        [For setEnabled:false];
    }

}

- (IBAction)navigateStart:(id)sender {  
    NSArray *sortedLegs = [itinerary sortedLegs];  
    if (itineraryNumber <= [sortedLegs count]) {
        itineraryNumber++;
    }
    [self refreshLegOverlay:itineraryNumber-1];  // refreshes the last itinerary number
   [self refreshLegOverlay:itineraryNumber];   // refreshes the new itinerary number
    [self customMap];  // redefine the bounding box    
    
//    rootMap *l = [[rootMap alloc] initWithNibName:nil bundle:nil ];
//    [l setItinerarys:itinerary itineraryNumber:2];
//    [[self navigationController] pushViewController:l animated:YES];
  
}

//Testing for ZoomOut Map 
-(void)customMap
{
    if (itineraryNumber == 0) {  // if the startpoint set region in a 200m x 200m box around it
        [mapView setRegion:MKCoordinateRegionMakeWithDistance([startPoint coordinate],4000, 4000)]; 
    }
    else if (itineraryNumber == [[itinerary sortedLegs] count] + 1) {
        [mapView setRegion:MKCoordinateRegionMakeWithDistance([endPoint coordinate],4000, 4000)]; 
    }
    else { 
        // if inineraryNumber is pointing to a leg, then set the bound around the polyline
        MKMapRect mpRect = [[polyLineArray objectAtIndex:(itineraryNumber-1)] boundingMapRect];
        MKCoordinateRegion mpRegion = MKCoordinateRegionForMapRect(mpRect);
        // Move the center down by 15% of span so that route is not obscured by directions text
        mpRegion.center.latitude = mpRegion.center.latitude + mpRegion.span.latitudeDelta*0.08;
        // zoom out the map by 10% (lat) and 20% (long)
        mpRegion.span.latitudeDelta = mpRegion.span.latitudeDelta * 1.1; 
        mpRegion.span.longitudeDelta = mpRegion.span.longitudeDelta * 1.0;
        // Create a 100m x 100m coord region around the center, and choose that if bigger
        MKCoordinateRegion minRegion = MKCoordinateRegionMakeWithDistance(mpRegion.center, 4000.0, 4000.0);
        if ((minRegion.span.latitudeDelta > mpRegion.span.latitudeDelta) &&
            (minRegion.span.longitudeDelta > mpRegion.span.longitudeDelta)) {
            mpRegion = minRegion;  // if minRegion is larger, replace mpRegion with it
        }
       // [mapView removeAnnotation:myAnnotation1];
        
        [mapView setRegion:mpRegion];
    }
}

// Removes and re-inserts the polyline overlay for the specified iNumber (could be itineraryNumber)
- (void)refreshLegOverlay:(int)iNumber
{
    int i = iNumber-1; 
    if (i>=0 && i<[polyLineArray count]) {  // only refresh if there is a corresponding polyline
        [mapView removeOverlay:[polyLineArray objectAtIndex:i]];
        [mapView addOverlay:[polyLineArray objectAtIndex:i]];
    }
}

- (IBAction)feedbackButtonPressed:(id)sender forEvent:(UIEvent *)event
{
    [TestFlight openFeedbackView];
    FeedBackReqParam *fbParam = [[FeedBackReqParam alloc] initWithParam:@"FbParameter" source:FB_SOURCE_LEG uniqueId:legID date:nil fromAddress:nil toAddress:nil];
    FeedBackForm *legMapVC = [[FeedBackForm alloc] initWithFeedBack:@"FeedBackForm" fbParam:fbParam bundle:nil];   
    [[self navigationController] pushViewController:legMapVC animated:YES];

}

// Callback for providing any annotation views
- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    // Handle point annotations
    if ([annotation isKindOfClass:[MKPointAnnotation class]])
    {
        // if startpoint or endpoint, then use MKPinAnnotationView
        if (annotation == startPoint || annotation == endPoint) {
            // Try to dequeue an existing pin view first.
            MKPinAnnotationView* pinView = (MKPinAnnotationView*)[mv dequeueReusableAnnotationViewWithIdentifier:@"MyPinAnnotationView"];
            
            if (!pinView)
            {
                // If an existing pin view was not available, create one.
                pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:@"MyPinAnnotation"];
                pinView.animatesDrop = NO;
                pinView.canShowCallout = NO;
            }
            else
                pinView.annotation = annotation;
            
            if (annotation == startPoint) {
                pinView.pinColor = MKPinAnnotationColorGreen;
            } 
            else {
                pinView.pinColor = MKPinAnnotationColorRed;
            }
            return pinView;
        }
        // Otherwise, use the dot view controller
        else {
            MKAnnotationView* dotView = (MKAnnotationView*)[mv dequeueReusableAnnotationViewWithIdentifier:@"MyDotAnnotationView"];
            
            if (!dotView)
            {
                // If an existing pin view was not available, create one.
                dotView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:@"MyDotAnnotation"];
                dotView.canShowCallout = NO;
                if (!dotImage) {
                    // TODO add @2X image for retina screens
                    NSString* imageName = [[NSBundle mainBundle] pathForResource:@"mapDot" ofType:@"png"];
                    dotImage = [UIImage imageWithContentsOfFile:imageName];
                }
                if (dotImage) {
                    [dotView setImage:dotImage];
                }
            }
            else
                dotView.annotation = annotation;
            
            return dotView;
            
        }
    }
    return nil;
}

// Callback for providing the overlay view
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
    
    if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineView *aView = [[MKPolylineView alloc] initWithPolyline:(MKPolyline*)overlay];
        // aView.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
        aView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.4];
        aView.lineWidth = 5;
        
        // Determine if this overlay is the one in focus.  If so, make it darker
        NSLog(@"[polyLineArray count] = %d", [polyLineArray count]);
        if ([polyLineArray count] > 0) {
            NSLog(@"first polyLine = %@, overlay = %@", [polyLineArray objectAtIndex:0], overlay);
        }
        for (int i=0; i<[polyLineArray count]; i++) {
            if (([polyLineArray objectAtIndex:i] == overlay)) {
                if (i == itineraryNumber-1) {
                    Leg *leg = [[itinerary sortedLegs] objectAtIndex:(itineraryNumber-1)];
                    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                    [prefs setObject:@"3" forKey:@"source"];
                    [prefs setObject:[leg legId] forKey:@"uniqueid"];
                    if([leg isWalk]){
                        aView.strokeColor = [[UIColor blackColor] colorWithAlphaComponent:0.7] ;
                        aView.lineWidth = 5;
                        
                    } else if([leg isBus]){
                        aView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
                        aView.lineWidth = 5;
                    } else if([leg isTrain]){                        
                        aView.strokeColor = [[UIColor purpleColor] colorWithAlphaComponent:0.8] ;
                        aView.lineWidth = 5;
                    } else {
                        aView.strokeColor = [[UIColor purpleColor] colorWithAlphaComponent:0.8] ;
                        aView.lineWidth = 5;
                    }
                   
                }
            }
        } 
        
        return aView;
    }
    
    return nil;
}

/* Implemented by Sitanshu Joshi
 To show Direction at  
 */
-(void)walk
{    
    Leg *leg = [[itinerary sortedLegs] objectAtIndex:(itineraryNumber-1)];
    if([leg isWalk]){
        NSArray *sp = [leg sortedSteps];
        NSUInteger c = [sp count];
        
        for (int i=0; i<c; i++) {
            Step *sps = [sp objectAtIndex:i];
 
            NSNumber * lat = [sps startLat];
            NSNumber * log = [sps startLng];
            
            CLLocationCoordinate2D theCoordinate1;
            theCoordinate1.latitude  = [lat doubleValue]; 
            theCoordinate1.longitude =[log doubleValue];            
            myAnnotation1=[[MyAnnotation alloc] init];       
            myAnnotation1.coordinate=theCoordinate1;
            myAnnotation1.title=[sps streetName];
            if([sps relativeDirection] == nil){
                myAnnotation1.subtitle=@"START WALKING";
            } else {
                myAnnotation1.subtitle= [NSString stringWithFormat:@"TURN %@",[sps relativeDirection]];
            }
            [myAnnotation1 setAccessibilityElementsHidden:TRUE];          
            [mapView addAnnotation:myAnnotation1];            
        }
    }
}
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

}
-(IBAction)twitterSearch:(id)sender forEvent:(UIEvent *)event
{

    @try {
        /*
            DE: 42 
         */
//        TwitterSearch *twitter_search = [[TwitterSearch alloc] initWithNibName:@"TwitterSearch" bundle:nil];
//        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
//        NSString *trainRoute = [prefs objectForKey:@"train"];
//        [[self navigationController] pushViewController:twitter_search animated:YES];
//        trainRoute = [TWITTER_SERARCH_URL stringByReplacingOccurrencesOfString:@"TRAIN" withString:trainRoute];
//        [twitter_search loadRequest:trainRoute];
        
        TwitterSearch *twitter_search = [[TwitterSearch alloc] initWithNibName:@"TwitterSearch" bundle:nil];
        [[self navigationController] pushViewController:twitter_search animated:YES];
        [twitter_search loadRequest:CALTRAIN_TWITTER_URL];
    }
    @catch (NSException *exception) {
        NSLog(@" twitter print : %@", exception);
    }
 
    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


@end
