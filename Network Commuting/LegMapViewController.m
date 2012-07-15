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
#import "twitterViewController.h"
#import "RestKit/RKJSONParserJSONKit.h"
#import <CoreImage/CoreImageDefines.h>

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
@synthesize twitterCount;

NSString *legID;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[self navigationItem] setTitle:@"Nimbler"];
        
        backButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(navigateBack:)]; 
        forwardButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(navigateForward:)]; 
        bbiArray = [NSArray arrayWithObjects:forwardButton, backButton, nil];
        self.navigationItem.rightBarButtonItems = bbiArray;
    }
    return self;
}

- (void)setItinerary:(Itinerary *)itin itineraryNumber:(int)num
{
    @try {
        itinerary = itin;
        itineraryNumber = num;
        // Add start and endpoint annotation
    }
    @catch (NSNull *exception) {
        NSLog(@"exception at set itinerary and itineraryNumber: %@", exception);
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    @try {
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
        for (int i=0; i < [[itinerary legDescriptionToLegMapArray] count]; i++) {
            if ([[itinerary legDescriptionToLegMapArray] objectAtIndex:i] == [NSNull null]) {
                [polyLineArray addObject:[NSNull null]];
            }
            else {
            Leg* l = [[itinerary legDescriptionToLegMapArray] objectAtIndex:i];
            MKPolyline *polyLine = [[l polylineEncodedString] polyline];
            [polyLineArray addObject:polyLine];
            [mapView addOverlay:polyLine];
            
            MKPointAnnotation* dotPoint = [[MKPointAnnotation alloc] init];
            [dotPoint setCoordinate:[[l polylineEncodedString] endCoord]];
            [mapView addAnnotation:dotPoint];
            }
        }
        NSLog(@"ViewWillAppear, polyLineArray count = %d",[polyLineArray count]);
        
        [self setMapViewRegion];   // update the mapView region to correspond to the numItinerary item
        [self setDirectionsText];  // update the directions text accordingly
        [mapView setShowsUserLocation:YES];  // track user location
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        int tweetConut = [[prefs objectForKey:TWEET_COUNT] intValue];
        [twitterCount removeFromSuperview];
            twitterCount = [[CustomBadge alloc] init];
            twitterCount = [CustomBadge customBadgeWithString:[NSString stringWithFormat:@"%d",tweetConut]];
            [twitterCount setFrame:CGRectMake(60, 372, twitterCount.frame.size.width, twitterCount.frame.size.height)];        
            if (tweetConut == 0) {
                [twitterCount setHidden:YES];
            } else {
                [self.view addSubview:twitterCount];
                [twitterCount setHidden:NO];
            }
    }
    @catch (NSException *exception) {
        NSLog(@"exception at viewWillAppear in LegMapViewController: %@", exception);
    }
}

- (void)setMapViewRegion {

    @try {
        if ([polyLineArray objectAtIndex:itineraryNumber] == [NSNull null]) {
            // If an added startpoint or endpoint, set a 200m x 200m box around the point
            if (itineraryNumber == 0) { // startpoint
                [mapView setRegion:MKCoordinateRegionMakeWithDistance([startPoint coordinate],200, 200)]; 
            }
            else { // endpoint
                [mapView setRegion:MKCoordinateRegionMakeWithDistance([endPoint coordinate],200, 200)]; 
            }
        }
        else { 
            // if inineraryNumber is pointing to a leg, then set the bound around the polyline
            MKMapRect mpRect = [[polyLineArray objectAtIndex:itineraryNumber] boundingMapRect];
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
    @catch (NSException *exception) {
        NSLog(@"exception at setMapViewRegion: %@", exception);
    }
}

- (void)setDirectionsText 
{
    @try {
        NSString* titleText = [[itinerary legDescriptionTitleSortedArray] objectAtIndex:itineraryNumber];
        NSString* subtitleText = [[itinerary legDescriptionSubtitleSortedArray] objectAtIndex:itineraryNumber];
        if (itineraryNumber == 0) { // if first row, 
            [backButton setEnabled:false];
        }
        else if (itineraryNumber == [[itinerary legDescriptionTitleSortedArray] count]) { 
            //Disable to see next leg view
            [forwardButton setEnabled:false];
        }
        
        // if this is a itineraryNumber with an actual leg...
        if ([[itinerary legDescriptionToLegMapArray] objectAtIndex:itineraryNumber] != [NSNull null])
        {
            Leg *leg = [[itinerary legDescriptionToLegMapArray] objectAtIndex:itineraryNumber];

            legID = [leg legId];
            
            if([leg arrivalTime] > 0) {
                UIImage *imgForArrivalTime;
                if([leg.arrivalFlag intValue] == ON_TIME) {
                    imgForArrivalTime = [UIImage imageNamed:@"img_ontime.png"];
                    RealArrivalTime.text =[NSString stringWithFormat:@"onTime"];
                }  else if([leg.arrivalFlag intValue] == DELAYED) {
                    imgForArrivalTime = [UIImage imageNamed:@"img_delay.png"] ;
                    RealArrivalTime.text =[NSString stringWithFormat:@"Delay:%@m",leg.timeDiffInMins];
                } else if([leg.arrivalFlag intValue] == EARLY) {
                    imgForArrivalTime = [UIImage imageNamed:@"img_early.png"] ;
                    RealArrivalTime.text =[NSString stringWithFormat:@"Early:%@m",leg.timeDiffInMins];
                } else if([leg.arrivalFlag intValue] == EARLIER) {
                    imgForArrivalTime = [UIImage imageNamed:@"img_earlier.png"] ;
                    RealArrivalTime.text =[NSString stringWithFormat:@"Earlier:%@m",leg.timeDiffInMins];
                } 
                [imgForTimeInterval setImage:imgForArrivalTime];
                NSLog(@"stop-------------");
            } else {
                [imgForTimeInterval setImage:nil];
                RealArrivalTime.text =NULL_STRING;
            }

        }
        [directionsTitle setText:titleText];
        [directionsDetails setText:subtitleText];
    }
    @catch (NSException *exception) {
        NSLog(@"exception at setDirectionsText in LegMapView: %@", exception);
    }
}

// Callback for when user presses the navigate back button on the right navbar
- (IBAction)navigateBack:(id)sender {
    // Go back to the previous step
    @try {
        RealArrivalTime.text = NULL_STRING;
        [imgForTimeInterval setImage:nil];
        if (itineraryNumber > 0) {
            itineraryNumber--;
        }
        [self refreshLegOverlay:itineraryNumber+1];  // refreshes the previous itinerary number
        [self refreshLegOverlay:itineraryNumber];   // refreshes the new itinerary number
        [self setMapViewRegion];  // redefine the bounding box
        [self setDirectionsText];
        [backButton setEnabled:TRUE];
        [forwardButton setEnabled:TRUE];
        if(itineraryNumber == 0){
            //self.navigationItem.rightBarButtonItems = nil;
            //self.navigationItem.rightBarButtonItem = For;
            [backButton setEnabled:false];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception at previous leg: %@", exception);
    }
}

// Callback for when user presses the navigate forward button on the right navbar
- (IBAction)navigateForward:(id)sender {
    @try {
        RealArrivalTime.text = NULL_STRING;
        [imgForTimeInterval setImage:nil];
        // Go forward to the next step
        if (itineraryNumber < [[itinerary legDescriptionTitleSortedArray] count] - 1) {
            itineraryNumber++;
        }
        [self refreshLegOverlay:itineraryNumber-1];  // refreshes the last itinerary number
        [self refreshLegOverlay:itineraryNumber];   // refreshes the new itinerary number
        [self setMapViewRegion];  // redefine the bounding box
        [self setDirectionsText];
        [backButton setEnabled:TRUE];
        [forwardButton setEnabled:TRUE];
        if(itineraryNumber == [[itinerary legDescriptionToLegMapArray] count] - 1){       
            //self.navigationItem.rightBarButtonItem = backButton;
            [forwardButton setEnabled:false];
        } 
    }
    @catch (NSException *exception) {
        NSLog(@"exception at next leg: %@", exception);
    }
}


// Removes and re-inserts the polyline overlay for the specified iNumber (could be itineraryNumber)
- (void)refreshLegOverlay:(int)iNumber
{
    @try {
        if ([polyLineArray objectAtIndex:iNumber] != [NSNull null]) {  
            // only refresh if there is a corresponding polyline
            [mapView removeOverlay:[polyLineArray objectAtIndex:iNumber]];
            [mapView addOverlay:[polyLineArray objectAtIndex:iNumber]];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"exception at refresh at overlay in legMapView: %@",exception);
    }
}

- (IBAction)feedbackButtonPressed:(id)sender forEvent:(UIEvent *)event
{
    @try {
        [TestFlight openFeedbackView];
        FeedBackReqParam *fbParam = [[FeedBackReqParam alloc] initWithParam:@"FbParameter" source:[NSNumber numberWithInt:FB_SOURCE_LEG] uniqueId:legID date:nil fromAddress:nil toAddress:nil];
        FeedBackForm *legMapVC = [[FeedBackForm alloc] initWithFeedBack:@"FeedBackForm" fbParam:fbParam bundle:nil];   
        [[self navigationController] pushViewController:legMapVC animated:YES];
    }
    @catch (NSException *exception) {
        NSLog(@"exception at navigating in feedback from LegMapView: %@", exception);
    }
}



// Callback for providing the overlay view
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay 
{
    @try {
        if ([overlay isKindOfClass:[MKPolyline class]]) {
            MKPolylineView *aView = [[MKPolylineView alloc] initWithPolyline:(MKPolyline*)overlay];
            // aView.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
            aView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.4];
            aView.lineWidth = 5;
            
            // Determine if this overlay is the one in focus.  If so, make it darker
            for (int i=0; i<[polyLineArray count]; i++) {
                if (([polyLineArray objectAtIndex:i] == overlay)) {
                    if (i == itineraryNumber) {
                        Leg *leg = [[itinerary legDescriptionToLegMapArray] objectAtIndex:(itineraryNumber)];
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
    @catch (NSException *exception) {
        NSLog(@"exception at map overlay in LegMapView: %@", exception);
    }
}

/* Implemented by Sitanshu Joshi
 To show Direction at  
 */

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}
-(IBAction)twitterSearch:(id)sender forEvent:(UIEvent *)event
{
    @try {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        [[RKClient sharedClient]  get:@"advisories/all" delegate:self];
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

- (void)viewDidLoad{
    [super viewDidLoad];        
}

- (void)viewDidUnload{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)ReloadLegMapWithNewData
{    
    @try {
        [self setDirectionsText];
    }
    @catch (NSException *exception) {
        NSLog(@"exception at reload textDirection and image: %@", exception);
    }
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {  
    @try {
        if ([request isGET]) {       
            RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
            id  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];                
            twitterViewController *twit = [[twitterViewController alloc] init];
            [twit setTwitterLiveData:res];
            [[self navigationController] pushViewController:twit animated:YES];     
        } 
        
    }  @catch (NSException *exception) {
        NSLog( @"Exception while getting unique IDs from TP Server response: %@", exception);
    } 
}


// Callback for providing any annotation views
- (MKAnnotationView *)mapView:(MKMapView *)mv viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]]){
        return nil;
    }       
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


@end