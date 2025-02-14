//
//  ToFromViewController.m
//  Nimbler World, Inc.
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "ToFromViewController.h"
#import "Locations.h"
#import "LocationFromGoogle.h"
#import "UtilityFunctions.h"
#import "RouteOptionsViewController.h"
#import "Leg.h"
#import "PlanStore.h"
#import "Itinerary.h"
#import <RestKit/RKJSONParserJSONKit.h>
#import "FeedBackForm.h"
#import "twitterViewController.h"
#import "SettingInfoViewController.h"
#import "nc_AppDelegate.h"
#import "UIConstants.h"
#import "TEXTConstant.h"
#import "UserPreferance.h"
#import "Logging.h"
#import "RealTimeManager.h"
#import "StationListElement.h"
#import "RouteExcludeSetting.h"
#import "LocationPickerViewController.h"
#import "NimblerApplication.h"


@interface ToFromViewController()
{
    // Variables for internal use
    NSDateFormatter *tripDateFormatter;  // Formatter for showing the trip date / time
    NSString *planURLResource; // URL resource sent to planner
    NSMutableArray *planRequestHistory; // Array of all the past plan request parameter histories in sequential order (most recent one last)
    CGFloat toTableHeight;   // Current height of the toTable (US123 implementation)
    CGFloat fromTableHeight;  // Current height of the fromTable
    BOOL toGeocodeRequestOutstanding;  // true if there is an outstanding To geocode request
    BOOL fromGeocodeRequestOutstanding;  //true if there is an outstanding From geocode request
    NSDate* lastReverseGeoReqTime; 
    BOOL savetrip;
    double startButtonClickTime;
    float durationOfResponseTime;
    NSTimer* activityTimer;
    UIBarButtonItem *barButtonSwap;  // Swap left bar button (for when in NO_EDIT mode)
    UIBarButtonItem *barButtonCancel; // Cancel left bar button (for when in EDIT mode)
    NSStringDrawingContext *drawingContext;  // Drawing context for attributed strings
}

// Internal methods
- (BOOL)getPlan;
- (void)stopActivityIndicator;
- (void)startActivityIndicator;
-(void)segmentChange;
- (void)selectCurrentDate;
- (void)selectDate;
- (void)reverseGeocodeCurrentLocationIfNeeded;

@end


@implementation ToFromViewController

@synthesize toTableVC;
@synthesize fromTableVC;
@synthesize routeButton;
@synthesize rkGeoMgr;
@synthesize rkPlanMgr;
@synthesize rkSavePlanMgr;
@synthesize locations;
@synthesize planStore;
@synthesize fromLocation;
@synthesize toLocation;
@synthesize currentLocation;
@synthesize isCurrentLocationMode;
@synthesize departOrArrive;
@synthesize tripDate;
@synthesize tripDateLastChangedByUser;
@synthesize isTripDateCurrentTime;
@synthesize editMode;
@synthesize supportedRegion;
@synthesize isContinueGetRealTimeData;
@synthesize continueGetTime;
@synthesize timerGettingRealDataByItinerary;
@synthesize activityIndicator;
@synthesize strLiveDataURL;
@synthesize routeOptionsVC;
@synthesize datePicker,toolBar,departArriveSelector,date,btnDone,btnNow;
@synthesize plan;
@synthesize stations;
@synthesize planRequestParameters;
@synthesize locationPickerVC;
@synthesize mainToFromView,PicketSelectView,fromView,toView,txtFromView,txtToView,btnSwap,btnCureentLoc,imgViewMainToFromBG,imgViewFromBG,imgViewToBG,btnPicker,lblTxtDepartArrive,viewMode,lblTxtFrom,lblTxtTo;
@synthesize managedObjectContext;


NSString *currentLoc;
NSUserDefaults *prefs;
UIImage *imageDetailDisclosure;
#pragma mark view Lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    @try {
        if (self) {
            prefs  = [NSUserDefaults standardUserDefaults];
            planRequestHistory = [NSMutableArray array]; // Initialize this array
            departOrArrive = DEPART;
            toGeocodeRequestOutstanding = FALSE;
            fromGeocodeRequestOutstanding = FALSE;
            supportedRegion = [[SupportedRegion alloc] initWithDefault];
            
            editMode = NO_EDIT;
            
            // Initialize the trip date formatter for display
            tripDateFormatter = [[NSDateFormatter alloc] init];
            [tripDateFormatter setDoesRelativeDateFormatting:YES];
            [tripDateFormatter setTimeStyle:NSDateFormatterShortStyle];
            [tripDateFormatter setDateStyle:NSDateFormatterMediumStyle];
            
            // Accessibility Label For UI Automation.
            barButtonCancel.accessibilityLabel = CANCEL_BUTTON;
            drawingContext = [[NSStringDrawingContext alloc] init];
            drawingContext.minimumScaleFactor = 0.0;  // Specifies no scaling
        }
        imageDetailDisclosure = [UIImage imageNamed:@"img_DetailDesclosure.png"];
    }
    @catch (NSException *exception) {
        logException(@"ToFromViewController->initWithNibName", @"", exception);
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    // Initialize the to & from tables
    
    toTableVC = [[ToFromTableViewController alloc] initWithNibName:@"ToFromTableViewController" bundle:nil];
    [toTableVC setupIsFrom:FALSE toFromVC:self locations:locations];
    
    fromTableVC = [[ToFromTableViewController alloc] initWithNibName:@"ToFromTableViewController" bundle:nil];
    [fromTableVC setupIsFrom:TRUE toFromVC:self locations: locations];
    
    // Update the toTableVC and fromTableVC with the stations if it has not already
    [toTableVC setStations:self.stations];
    [fromTableVC setStations:self.stations];
    
    if([[[UIDevice currentDevice] systemVersion] intValue] >= 7){
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    [self.btnPicker setTitle:@"Now" forState:UIControlStateNormal];
    NSString *strFromFormattedAddress;
    if([locations selectedFromLocation].locationName){
       strFromFormattedAddress = [locations selectedFromLocation].locationName;
    }
    else if([[[locations selectedFromLocation] shortFormattedAddress] length]>0){
        strFromFormattedAddress = [[locations selectedFromLocation] shortFormattedAddress];
    }else{
        strFromFormattedAddress = [[NSUserDefaults standardUserDefaults] objectForKey:LAST_FROM_LOCATION];
        NSArray *matchingLocations = [locations locationsWithFormattedAddress:strFromFormattedAddress];
        if([matchingLocations count] > 0){
            strFromFormattedAddress = ((Location *)[matchingLocations objectAtIndex:0]).shortFormattedAddress;
        }
    }
    if(!strFromFormattedAddress){
        strFromFormattedAddress = @"";
    }
    if([strFromFormattedAddress isEqualToString:@"Current Location"]){
        [btnCureentLoc setSelected:YES];
        [btnCureentLoc setUserInteractionEnabled:NO];
    }
    [self.txtFromView setText:strFromFormattedAddress];
    
    
    NSString *strToFormattedAddress;
    if([locations selectedToLocation].locationName){
       strToFormattedAddress = [locations selectedToLocation].locationName;
    }
    else if([[[locations selectedToLocation] shortFormattedAddress] length]>0){
        strToFormattedAddress = [[locations selectedToLocation] shortFormattedAddress];
    }else{
        strToFormattedAddress = [[NSUserDefaults standardUserDefaults] objectForKey:LAST_TO_LOCATION];
        NSArray *matchingLocations = [locations locationsWithFormattedAddress:strToFormattedAddress];
        if([matchingLocations count] > 0){
            strToFormattedAddress = ((Location *)[matchingLocations objectAtIndex:0]).shortFormattedAddress;
        }
    }if(!strToFormattedAddress){
        strToFormattedAddress = @"";
    }
    
    [self.txtToView setText:strToFormattedAddress];
    
    // Added To solve the crash related to ios 4.3
    if([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
        [self.navigationController.navigationBar setBackgroundImage:returnNavigationBarBackgroundImage() forBarMetrics:UIBarMetricsDefault];
    }
    else {
        [self.navigationController.navigationBar insertSubview:[[UIImageView alloc]initWithImage:returnNavigationBarBackgroundImage()] aboveSubview:self.navigationController.navigationBar];
    }
    UIImage *imgTitle;
        imgTitle = [UIImage imageNamed:@"nimbler.png"];
    self.navigationItem.titleView = [[UIImageView alloc]  initWithImage:imgTitle];

    if(editMode == NO_EDIT){
        self.navigationItem.leftBarButtonItem = barButtonSwap;
    } else{
        self.navigationItem.leftBarButtonItem = barButtonCancel;
    }
    
    routeButton.layer.cornerRadius = CORNER_RADIUS_SMALL;
    [continueGetTime invalidate];
    continueGetTime = nil;
    [routeOptionsVC.timerGettingRealDataByItinerary invalidate];
    routeOptionsVC.timerGettingRealDataByItinerary = nil;
    
    NSArray *array = [NSArray arrayWithObjects:DATE_PICKER_DEPART,DATE_PICKER_ARRIVE, nil];
    departArriveSelector = [[UISegmentedControl alloc] initWithItems:array];
    
    // Accessibility Label For UI Automation.
    departArriveSelector.accessibilityLabel = DEPART_OR_ARRIVE_SEGMENT_BUTTON;
    
    departArriveSelector.selectedSegmentIndex = 1;
    [departArriveSelector addTarget:self action:@selector(segmentChange) forControlEvents:UIControlEventValueChanged];
    
    btnDone = [[UIBarButtonItem alloc] initWithTitle:DATE_PICKER_DONE style:UIBarButtonItemStyleBordered target:self action:@selector(selectDate)];
    
    // Accessibility Label For UI Automation.
    btnDone.accessibilityLabel = DONE_BUTTON;
    
    btnNow = [[UIBarButtonItem alloc] initWithTitle:DATE_PICKER_NOW style:UIBarButtonItemStyleBordered target:self action:@selector(selectCurrentDate)];
    
    // Accessibility Label For UI Automation.
    btnNow.accessibilityLabel = NOW_BUTTON;
    
    // Do any additional setup after loading the view from its nib.
    
    UIButton *btnAdvisories = [[UIButton alloc] initWithFrame:CGRectMake(0,0,ADVISORY_BUTTON_WIDTH,
                                                                         ADVISORY_BUTTON_HEIGHT)];
    [btnAdvisories addTarget:self.navigationController.parentViewController action:@selector(revealToggle:) forControlEvents:UIControlEventTouchUpInside];
    [btnAdvisories setBackgroundImage:[UIImage imageNamed:@"notificationicon6.png"] forState:UIControlStateNormal];
    
    UIBarButtonItem *btnBarAdvisories = [[UIBarButtonItem alloc] initWithCustomView:btnAdvisories];
    self.navigationItem.leftBarButtonItem = btnBarAdvisories;
}

- (void) revealtoggle{
    [self.navigationController.parentViewController performSelector:@selector(revealToggle:) withObject:nil afterDelay:0.0];
}
- (void)setSupportedRegion:(SupportedRegion *)supportedReg0
{
    supportedRegion = supportedReg0;
    [toTableVC setSupportedRegion:supportedReg0];
    [fromTableVC setSupportedRegion:supportedReg0];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    self.routeButton = nil;
}

- (void)dealloc{
    self.routeButton = nil;
}
// Added To Handle Orientation issue in ios-6

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (NSUInteger) supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL) shouldAutorotate {
    return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if(![[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_TRANSIT_MODE]){
        [[NSUserDefaults standardUserDefaults] setObject:MODE_ENABLE forKey:DEFAULT_TRANSIT_MODE];
    }
    if(![[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_CAR_MODE]){
        [[NSUserDefaults standardUserDefaults] setObject:MODE_ENABLE forKey:DEFAULT_CAR_MODE];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    //Mode
    UIButton *btnMode;
    btnMode = (UIButton *)[self.viewMode viewWithTag:[BIKE_MODE_Tag intValue]];
    if([[[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_BIKE_MODE] isEqualToString:MODE_ENABLE]){
        [btnMode setSelected:YES];
    }
    else{
        [btnMode setSelected:NO];
    }
    btnMode = (UIButton *)[self.viewMode viewWithTag:[TRANSIT_MODE_Tag intValue]];
    if([[[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_TRANSIT_MODE] isEqualToString:MODE_ENABLE]){
        [btnMode setSelected:YES];
    }
    else{
        [btnMode setSelected:NO];
    }

    btnMode = (UIButton *)[self.viewMode viewWithTag:[CAR_MODE_Tag intValue]];
    if([[[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_CAR_MODE] isEqualToString:MODE_ENABLE]){
        [btnMode setSelected:YES];
    }
    else{
        [btnMode setSelected:NO];
    }
    
    if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:WMATA_BUNDLE_IDENTIFIER]){
        btnMode = (UIButton *)[self.viewMode viewWithTag:[BIKE_SHARE_MODE_Tag intValue]];
        [btnMode setHidden:NO];
        if(![[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_SHARE_MODE]){
            [[NSUserDefaults standardUserDefaults] setObject:MODE_ENABLE forKey:DEFAULT_SHARE_MODE];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [btnMode setSelected:YES];
        }
        else{
            if([[[NSUserDefaults standardUserDefaults] objectForKey:DEFAULT_SHARE_MODE] isEqualToString:MODE_ENABLE]){
                [btnMode setSelected:YES];
            }
            else{
                [btnMode setSelected:NO];
            }
        }
    }
    [self.navigationController.navigationBar setHidden:NO];
    NSArray *itinerariesArray = [nc_AppDelegate sharedInstance].gtfsParser.itinerariesArray;
    NSArray *fromToStopId = [nc_AppDelegate sharedInstance].planStore.fromToStopID;
    if(itinerariesArray){
        [nc_AppDelegate sharedInstance].gtfsParser.itinerariesArray = nil;
    }
    if(fromToStopId){
        [nc_AppDelegate sharedInstance].planStore.fromToStopID = nil;
    }
    if(routeOptionsVC.timerGettingRealDataByItinerary != nil){
        [routeOptionsVC.timerGettingRealDataByItinerary invalidate];
        routeOptionsVC.timerGettingRealDataByItinerary = nil;
    }
    NIMLOG_PERF1(@"Entered ToFromView viewWillAppear");
    [nc_AppDelegate sharedInstance].isToFromView = YES;
    
    @try {

        logEvent(FLURRY_TOFROMVC_APPEAR, nil, nil, nil, nil, nil, nil, nil, nil);
        
        isContinueGetRealTimeData = NO;
        [continueGetTime invalidate];
        continueGetTime = nil;
        [self updateTripDate];  // update tripDate if needed
        NIMLOG_PERF1(@"Ready to setFBParameterForGeneral");
        [self setFBParameterForGeneral];
        NIMLOG_PERF1(@"Ready to reload tables");
        
        [[nc_AppDelegate sharedInstance].window bringSubviewToFront:[nc_AppDelegate sharedInstance].twitterCount];
        [[nc_AppDelegate sharedInstance].twitterCount setHidden:NO];
    }
    @catch (NSException *exception) {
        logException(@"ToFromViewController->viewWillAppear", @"", exception);
    }
    NIMLOG_PERF1(@"Finished ToFromView viewWillAppear");
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [nc_AppDelegate sharedInstance].isToFromView = NO;
    //Part Of US-177 Implementation
    [nc_AppDelegate sharedInstance].toLoc = self.toLocation;
    [nc_AppDelegate sharedInstance].fromLoc = self.fromLocation;
    [[nc_AppDelegate sharedInstance].twitterCount setHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NIMLOG_PERF1(@"Entered ToFromView did appear");
    if (isCurrentLocationMode) {
        [self reverseGeocodeCurrentLocationIfNeeded];
    }
     [[nc_AppDelegate sharedInstance].window bringSubviewToFront:[nc_AppDelegate sharedInstance].twitterCount];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
    logEvent(FLURRY_DID_RECEIVE_MEMORY_WARNING, nil, nil, nil, nil, nil, nil, nil, nil);
}

// Update trip date to the current time if needed
- (void)updateTripDate
{
    NSDate* currentTime = [[NSDate alloc] init];
    if (isTripDateCurrentTime) {
        tripDate = currentTime;  // simply refresh the date 
    }
    if (!tripDate || !tripDateLastChangedByUser) {
        tripDate = currentTime;   // if no date set, or never set by user, use current time
        departOrArrive = DEPART;
        isTripDateCurrentTime = YES;
    }
    else if ([tripDateLastChangedByUser timeIntervalSinceNow] < -(24*3600.0)) {
        // if more than a day since last user update, use the current time
        tripDate = currentTime;  
        departOrArrive = DEPART;
        isTripDateCurrentTime = YES;
    }
    else if ([tripDateLastChangedByUser timeIntervalSinceNow] < -7200.0) { 
        // if tripDate not changed in the last two hours by user, update it if tripDate is in the past
        NSDate* laterDate = [tripDate laterDate:currentTime]; 
        if (laterDate == currentTime) {  // if currentTime is later than tripDate, update to current time
            tripDate = currentTime;
            departOrArrive = DEPART; 
        }
    }
}


#pragma mark set RKObjectManager
// One-time set-up of the RestKit Geocoder Object Manager's mapping
- (void)setRkGeoMgr:(RKObjectManager *)rkGeoMgr0
{
    rkGeoMgr = rkGeoMgr0;  //set the property
    
    
    
    // Add the mapper from Location class to this Object Manager
    [[rkGeoMgr mappingProvider] setMapping:[LocationFromGoogle objectMappingForApi:GOOGLE_GEOCODER] forKeyPath:@"results"];
    
    // Get the Managed Object Context associated with rkGeoMgr0
    managedObjectContext = [[rkGeoMgr objectStore] managedObjectContext];
    
    // Pass rkGeoMgr to the To & From Table View Controllers
    [fromTableVC setRkGeoMgr:rkGeoMgr];
    [toTableVC setRkGeoMgr:rkGeoMgr];
}

// One-time set-up of the RestKit Trip Planner Object Manager's mapping
- (void)setRkPlanMgr:(RKObjectManager *)rkPlanMgr0
{
    rkPlanMgr = rkPlanMgr0;
    // Add the mapper from Plan class to this Object Manager
    [[rkPlanMgr mappingProvider] setMapping:[Plan objectMappingforPlanner:OTP_PLANNER] forKeyPath:@"plan"];
}

- (void)setPlanStore:(PlanStore *)planStore0
{
    planStore = planStore0;
    // Set the objects for callback with planStore
    if (!routeOptionsVC) {
        routeOptionsVC = [[RouteOptionsViewController alloc] initWithNibName:nil bundle:nil];
    }
    [routeOptionsVC setPlanStore:planStore0];
}

#pragma mark ToFromEdit mode Delegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView{

    if(editMode == FROM_EDIT){  // This code can sometime be hit after coming back from LocationPicker.  Needs work
        [self.fromTableVC.btnEdit setSelected:NO];
        [self.fromTableVC editButtonClicked:self.fromTableVC.btnEdit];
    }
    if(editMode == TO_EDIT){ // This code can sometime be hit after coming back from LocationPicker.  Needs work

        [self.toTableVC.btnEdit setSelected:NO];
        [self.toTableVC editButtonClicked:self.toTableVC.btnEdit];
    }
    if(datePicker){
        [datePicker removeFromSuperview];
        datePicker = nil;
    }
    if(toolBar){
        [toolBar removeFromSuperview];
        toolBar = nil;
    }
    [btnPicker setUserInteractionEnabled:YES];
    [self.txtFromView setTextColor:[UIColor blackColor]];
    [self.txtToView setTextColor:[UIColor blackColor]];
    [[nc_AppDelegate sharedInstance].twitterCount setHidden:YES];
    if(editMode==FROM_EDIT || editMode==TO_EDIT){
        return YES;
    }
    textView.text = @"";
    if(textView==self.txtFromView){
        fromTableVC.isFrom=true;
        [self setEditMode:FROM_EDIT];
        editMode = FROM_EDIT;
        
    }
    else{
        toTableVC.isFrom=false;
        [self setEditMode:TO_EDIT];
        editMode = TO_EDIT;
        
    }
    return NO;
}
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if([text isEqualToString:@"\n"]) {

        // Not clear if we still need this method based on latest design (John C, 9/24/2014)
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    [self.txtFromView setTextColor:[UIColor NIMBLER_RED_FONT_COLOR]];
    [self.txtToView setTextColor:[UIColor NIMBLER_RED_FONT_COLOR]];
}

- (void)setEditMode:(ToFromEditMode)newEditMode
{
    // Change TOFROMVIEW FRAMES accordingly EDIT MODE
    
    if(newEditMode == FROM_EDIT){
        [[self navigationController] pushViewController:fromTableVC animated:NO];
    }
    else if (newEditMode == TO_EDIT){
        [[self navigationController] pushViewController:toTableVC animated:NO];
    }
    else if (newEditMode == NO_EDIT){
        [self setToFromViewOnNoEditMode];
        editMode = NO_EDIT;
    }
    
}

- (void) setToFromViewOnNoEditMode{
    
    if(editMode == FROM_EDIT){
        Location *selectedFromLocation = [locations selectedFromLocation];
        NSString *strFromFormattedAddress;
        if(selectedFromLocation.locationName){
            strFromFormattedAddress = [selectedFromLocation locationName];
        }
        else if([selectedFromLocation.userUpdatedLocation boolValue]){
            strFromFormattedAddress = [selectedFromLocation formattedAddress];
        }
        else{
            strFromFormattedAddress = [selectedFromLocation shortFormattedAddress];
        }
        
        if(![strFromFormattedAddress length]>0){
            strFromFormattedAddress = [[NSUserDefaults standardUserDefaults] objectForKey:LAST_FROM_LOCATION];
            NSArray *matchingLocations = [locations locationsWithFormattedAddress:strFromFormattedAddress];
            if([matchingLocations count] > 0){
                strFromFormattedAddress = ((Location *)[matchingLocations objectAtIndex:0]).shortFormattedAddress;
            }
        }
        if(!strFromFormattedAddress){
            strFromFormattedAddress = @"";
        }
        [self.txtFromView setText:strFromFormattedAddress];
        
        Location *selectedToLocation = [locations selectedToLocation];
        NSString *strToFormattedAddress;
        if(selectedToLocation.locationName){
            strToFormattedAddress = [selectedToLocation locationName];
        }
        else if([selectedToLocation.userUpdatedLocation boolValue]){
            strToFormattedAddress = [selectedToLocation formattedAddress];
        }
        else{
            strToFormattedAddress = [selectedToLocation shortFormattedAddress];
        }
        if(![strToFormattedAddress length]>0){
            strToFormattedAddress = [[NSUserDefaults standardUserDefaults] objectForKey:LAST_FROM_LOCATION];
            NSArray *matchingLocations = [locations locationsWithFormattedAddress:strToFormattedAddress];
            if([matchingLocations count] > 0){
                strToFormattedAddress = ((Location *)[matchingLocations objectAtIndex:0]).shortFormattedAddress;
            }
        }
        if(!strToFormattedAddress){
            strToFormattedAddress = @"";
        }
        [self.txtToView setText:strToFormattedAddress];
        [self.txtFromView resignFirstResponder];
    }
    else if (editMode == TO_EDIT){
        Location *selectedFromLocation = [locations selectedFromLocation];
        NSString *strFromFormattedAddress;
        if(selectedFromLocation.locationName){
            strFromFormattedAddress = [selectedFromLocation locationName];
        }
        else if([selectedFromLocation.userUpdatedLocation boolValue]){
            strFromFormattedAddress = [selectedFromLocation formattedAddress];
        }
        else{
            strFromFormattedAddress = [selectedFromLocation shortFormattedAddress];
        }
        if(![strFromFormattedAddress length]>0){
            strFromFormattedAddress = [[NSUserDefaults standardUserDefaults] objectForKey:LAST_FROM_LOCATION];
            NSArray *matchingLocations = [locations locationsWithFormattedAddress:strFromFormattedAddress];
            if([matchingLocations count] > 0){
                strFromFormattedAddress = ((Location *)[matchingLocations objectAtIndex:0]).shortFormattedAddress;
            }
        }
        if(!strFromFormattedAddress){
            strFromFormattedAddress = @"";
        }
        [self.txtFromView setText:strFromFormattedAddress];
        
        Location *selectedToLocation = [locations selectedToLocation];
        NSString *strToFormattedAddress;
        if(selectedToLocation.locationName){
            strToFormattedAddress = [selectedToLocation locationName];
        }
        else if([selectedToLocation.userUpdatedLocation boolValue]){
            strToFormattedAddress = [selectedToLocation formattedAddress];
        }
        else{
            strToFormattedAddress = [selectedToLocation shortFormattedAddress];
        }
        if(![strToFormattedAddress length]>0){
            strToFormattedAddress = [[NSUserDefaults standardUserDefaults] objectForKey:LAST_FROM_LOCATION];
            NSArray *matchingLocations = [locations locationsWithFormattedAddress:strToFormattedAddress];
            if([matchingLocations count] > 0){
                strToFormattedAddress = ((Location *)[matchingLocations objectAtIndex:0]).shortFormattedAddress;
            }
        }
        if(!strToFormattedAddress){
            strToFormattedAddress = @"";
        }
        [self.txtToView setText:strToFormattedAddress];
        [self.txtToView resignFirstResponder];
    }
}

#pragma mark Loacation methods
- (void)setLocations:(Locations *)l
{
    locations = l;
    // Now also update the to & from Table View Controllers with the locations object
    [toTableVC setLocations:l];
    [fromTableVC setLocations:l];
}

- (void)setStations:(Stations *)s
{
    stations = s;
    // Now also update the to & from Table View Controllers with the locations object
    [toTableVC setStations:s];
    [fromTableVC setStations:s];
}

// Method to change isCurrentLocationMode.
// When isCurrentLocationMode = true, then a larger To table is shown, and only one row containing "Current Location" is showed in the from field
// When isCurrentLocationMode = false, then equal sized To and From tables are shown (traditional display)
- (void)setIsCurrentLocationMode:(BOOL) newCLMode
{
    if (isCurrentLocationMode != newCLMode) { // Only do something if there is a change
        isCurrentLocationMode = newCLMode;
        activityIndicator = nil;  // Nullify because activityIndicator changes per CLMode
        if (newCLMode && (fromLocation != currentLocation)) {  
            // DE55 fix: make sure that currentLocation is selected if this method called by nc_AppDelegate
            [fromTableVC initializeCurrentLocation:currentLocation]; 
        }
        // Adjust the toTable & fromTable heights
//        [self setToFromHeightForTable:toTable Height:[self tableHeightFor:toTable]];
//        [self setToFromHeightForTable:fromTable Height:[self tableHeightFor:fromTable]];

        if (editMode != FROM_EDIT) {
            // DE59 fix -- only update table if not in FROM_EDIT mode
        }
        if (newCLMode) {
            [self reverseGeocodeCurrentLocationIfNeeded];
        }
    }
}

// ToFromTableViewController callbacks 
// (for when user has selected or entered a new location)
// Callback from ToFromTableViewController to update a new user entered/selected location

- (void)updateToFromLocation:(id)sender isFrom:(BOOL)isFrom location:(Location *)loc; {
    [self.txtFromView setTextColor:[UIColor NIMBLER_RED_FONT_COLOR]];
    [self.txtToView setTextColor:[UIColor NIMBLER_RED_FONT_COLOR]];
    
    if (isFrom) {
        fromLocation = loc;
        [self setFBParameterForGeneral];
        if (currentLocation && loc == currentLocation && !isCurrentLocationMode) { // Part of DE194 fix
            [self setIsCurrentLocationMode:TRUE];
        }
        else if (loc != currentLocation && isCurrentLocationMode) {
            [self setIsCurrentLocationMode:FALSE];
        }
        if(fromLocation.locationName){
           [self.txtFromView setText:[fromLocation locationName]];
        }
        else if(fromLocation.userUpdatedLocation){
            [self.txtFromView setText:[fromLocation formattedAddress]];
        }
        else{
            [self.txtFromView setText:[fromLocation shortFormattedAddress]];
        }
        [self setToFromTextViewScrollPosition:true];
        
    } 
    else {
        toLocation = loc;
        [self setFBParameterForGeneral];
        if (loc == currentLocation) {  // if current location chosen for toLocation
            [self reverseGeocodeCurrentLocationIfNeeded];
        }
        if(toLocation.locationName){
            [self.txtToView setText:[toLocation locationName]];
        }
        else if(toLocation.userUpdatedLocation){
            [self.txtToView setText:[toLocation formattedAddress]];
        }
        else{
            [self.txtToView setText:[toLocation shortFormattedAddress]];
        }
        
        [self setToFromTextViewScrollPosition:false];
    }
    if([fromLocation.formattedAddress isEqualToString:@"Current Location"]){
        [self.btnCureentLoc setSelected:YES];
        [self.btnCureentLoc setUserInteractionEnabled:NO];
    }
    else{
        [self.btnCureentLoc setSelected:NO];
        [self.btnCureentLoc setUserInteractionEnabled:YES];
    }
}

-(void) setToFromTextViewScrollPosition:(BOOL)isFrom{
    NSString *strLocation;
    if(isFrom){
        strLocation = self.txtFromView.text;
        
        CGRect stringRect = [strLocation
                             boundingRectWithSize:CGSizeMake(txtFromView.frame.size.width, CGFLOAT_MAX)
                             options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                             attributes:[NSDictionary dictionaryWithObject:txtFromView.font forKey:NSFontAttributeName]
                             context:drawingContext];
        
        if(ceil(stringRect.size.height)>TOFROM_TEXTVIEW_SCROLL_HEIGHT_THRESHOLD){
            CGPoint scrollPoint = self.txtFromView.contentOffset;
            if(scrollPoint.y<TOFROM_TEXTVIEW_SCROLL_MULTILINE_OFFSET){
                scrollPoint.y= scrollPoint.y+TOFROM_TEXTVIEW_SCROLL_MULTILINE_OFFSET;
                [self.txtFromView setContentOffset:scrollPoint animated:NO];
            }
            NIMLOG_AUTOSIZE(@"From Scroll Offset = %f, view width = %f", scrollPoint.y, txtFromView.frame.size.width);
        }
        else{
            self.txtFromView.contentOffset = CGPointZero;
        }
    }
    else{
        strLocation = self.txtToView.text;
        
        CGRect stringRect = [strLocation
                             boundingRectWithSize:CGSizeMake(txtToView.frame.size.width, CGFLOAT_MAX)
                             options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                             attributes:[NSDictionary dictionaryWithObject:txtToView.font forKey:NSFontAttributeName]
                             context:drawingContext];
        
        if(ceil(stringRect.size.height)>TOFROM_TEXTVIEW_SCROLL_HEIGHT_THRESHOLD){
            CGPoint scrollPoint = self.txtToView.contentOffset;
            if(scrollPoint.y<TOFROM_TEXTVIEW_SCROLL_MULTILINE_OFFSET){
                scrollPoint.y= scrollPoint.y+TOFROM_TEXTVIEW_SCROLL_MULTILINE_OFFSET;
                [self.txtToView setContentOffset:scrollPoint animated:NO];
            }
            NIMLOG_AUTOSIZE(@"To Scroll Offset = %f, view width = %f", scrollPoint.y, txtToView.frame.size.width);
        }
        else{
            self.txtToView.contentOffset = CGPointZero;
        }
    }
}

// Callback from ToFromTableViewController to update geocoding status
- (void)updateGeocodeStatus:(BOOL)isGeocodeOutstanding isFrom:(BOOL)isFrom
{
    // update the appropriate geocode status
    if (isFrom) {
        fromGeocodeRequestOutstanding = isGeocodeOutstanding;
    } else {
        toGeocodeRequestOutstanding = isGeocodeOutstanding;
    }
}

-(BOOL)alertUsetForLocationService {
    if (![locations isLocationServiceEnable]) {
        return TRUE;
    }
    return FALSE;
}

#pragma mark Button Press Event
- (IBAction)btnCurrentLocationClicked:(id)sender{
    UIButton *btnLoc = (UIButton *)sender;
    if(btnLoc.selected == NO){
        [btnLoc setSelected:YES];
        [btnCureentLoc setUserInteractionEnabled:NO];
        fromTableVC.isFrom = true;
        [fromTableVC markAndUpdateSelectedLocation:currentLocation];
    }
}
-(IBAction)btnModeClicked:(id)sender{
    UIButton *btnMode = (UIButton *)sender;
    NSString *strMode;
    if(btnMode.selected == YES){
        strMode = MODE_DISABLE;
        [btnMode setSelected:NO];
    }
    else{
        strMode = MODE_ENABLE;
        [btnMode setSelected:YES];
    }
    NSString *bikeName;
    bikeName = returnBikeButtonTitle();
    if([sender tag]==[BIKE_MODE_Tag intValue]){
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@",strMode] forKey:DEFAULT_BIKE_MODE];
        [[NSUserDefaults standardUserDefaults] synchronize];
        btnMode = (UIButton *)[self.viewMode viewWithTag:[BIKE_SHARE_MODE_Tag intValue]];
        if([strMode isEqualToString:MODE_ENABLE]){
            [[RouteExcludeSettings latestUserSettings] changeSettingTo:SETTING_INCLUDE_ROUTE forKey:bikeName];
            if(btnMode.selected == YES){
                [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"0"] forKey:DEFAULT_SHARE_MODE];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [btnMode setSelected:NO];
                [[RouteExcludeSettings latestUserSettings] changeSettingTo:SETTING_EXCLUDE_ROUTE forKey:BIKE_SHARE];
            }
        }
        else{
            [[RouteExcludeSettings latestUserSettings] changeSettingTo:SETTING_EXCLUDE_ROUTE forKey:bikeName];
        }
    }
    else if([sender tag]==[TRANSIT_MODE_Tag intValue]){
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@",strMode] forKey:DEFAULT_TRANSIT_MODE];
        [[NSUserDefaults standardUserDefaults] synchronize];
//        if([strMode isEqualToString:MODE_ENABLE]){
//            for(int i=0;i<[[plan excludeSettingsArray] count];i++){
//                RouteExcludeSetting *routeExcludeSetting = [[plan excludeSettingsArray] objectAtIndex:i];
//                NSString *key = routeExcludeSetting.key;
//                if(![key isEqualToString:bikeName] && ![key isEqualToString:BIKE_SHARE]){
//                    [[RouteExcludeSettings latestUserSettings] changeSettingTo:SETTING_INCLUDE_ROUTE forKey:routeExcludeSetting.key];
//                }
//            }
//        }
//        else{
//            for(int i=0;i<[[plan excludeSettingsArray] count];i++){
//                RouteExcludeSetting *routeExcludeSetting = [[plan excludeSettingsArray] objectAtIndex:i];
//                NSString *key = routeExcludeSetting.key;
//                if(![key isEqualToString:bikeName] && ![key isEqualToString:BIKE_SHARE]){
//                    [[RouteExcludeSettings latestUserSettings] changeSettingTo:SETTING_EXCLUDE_ROUTE forKey:routeExcludeSetting.key];
//                }
//            }
//        }
    }
    else if([sender tag]==[CAR_MODE_Tag intValue]){
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@",strMode] forKey:DEFAULT_CAR_MODE];
        [[NSUserDefaults standardUserDefaults] synchronize];
        if([strMode isEqualToString:MODE_ENABLE]){
            [[RouteExcludeSettings latestUserSettings] changeSettingTo:SETTING_INCLUDE_ROUTE forKey:UBER_EXCLUDE_BUTTON_DISPLAY_NAME];
        }
        else{
            [[RouteExcludeSettings latestUserSettings] changeSettingTo:SETTING_EXCLUDE_ROUTE forKey:UBER_EXCLUDE_BUTTON_DISPLAY_NAME];
        }
    }
    
    if([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:WMATA_BUNDLE_IDENTIFIER]){
        if([sender tag]==[BIKE_SHARE_MODE_Tag intValue]){
            [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@",strMode] forKey:DEFAULT_SHARE_MODE];
            [[NSUserDefaults standardUserDefaults] synchronize];
            btnMode = (UIButton *)[self.viewMode viewWithTag:[BIKE_MODE_Tag intValue]];
            if([strMode isEqualToString:MODE_ENABLE]){
                [[RouteExcludeSettings latestUserSettings] changeSettingTo:SETTING_INCLUDE_ROUTE forKey:BIKE_SHARE];
                if(btnMode.selected == YES){
                    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"0"] forKey:DEFAULT_BIKE_MODE];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    [btnMode setSelected:NO];
                    [[RouteExcludeSettings latestUserSettings] changeSettingTo:SETTING_EXCLUDE_ROUTE forKey:bikeName];
                }
            }
            else{
                [[RouteExcludeSettings latestUserSettings] changeSettingTo:SETTING_EXCLUDE_ROUTE forKey:BIKE_SHARE];
            }
        }

    }
}

// Requesting a plan
- (IBAction)routeButtonPressed:(id)sender forEvent:(UIEvent *)event
{
    @try {
        if ([nc_AppDelegate sharedInstance].isDatePickerOpen) {
            // if datepicker is still open when route button is pressed, use the date in the datePicker
            [self selectDate];
        }
        
        if(datePicker){
            [datePicker removeFromSuperview];
            datePicker = nil;
        }
        if(toolBar){
            [toolBar removeFromSuperview];
            toolBar = nil;
        }
        [btnPicker setUserInteractionEnabled:YES];
        
        NIMLOG_EVENT1(@"Route Button Pressed");
        UIAlertView *alert;
        
        startButtonClickTime = CFAbsoluteTimeGetCurrent();
        
        if ([fromLocation isCurrentLocation]) {
            if ([self alertUsetForLocationService]) {
                NSString* msg;   // DE193 fix
                if([[[UIDevice currentDevice] systemVersion] floatValue] < 6.0) {
                    msg = ALERT_LOCATION_SERVICES_DISABLED_MSG;
                } else {
                    msg = ALERT_LOCATION_SERVICES_DISABLED_MSG_V6;
                }
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ALERT_LOCATION_SERVICES_DISABLED_TITLE message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
                return ;
            }
        }
        // if all the geolocations are here, get a plan.  
        if ([fromLocation formattedAddress] && [toLocation formattedAddress] &&
            !toGeocodeRequestOutstanding && !fromGeocodeRequestOutstanding) {
            if (isTripDateCurrentTime) { // if current time, get the latest before getting plan
                [self updateTripDate];
            }
            
            [self getPlan];
        }
        // if user has not entered/selected fromLocation, send them an alert
        else if (![fromLocation formattedAddress] && !fromGeocodeRequestOutstanding) {
            alert = [[UIAlertView alloc] initWithTitle:@"TripPlanner" message:@"Select a 'From' address" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        // if user has not entered has not entered/selected toLocation, send them an alert
        else if (![toLocation formattedAddress] && !toGeocodeRequestOutstanding) {
            alert = [[UIAlertView alloc] initWithTitle:@"TripPlanner" message:@"Select a destination address" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        // otherwise, just wait for the geocoding and then submit the plan
        else {
            NIMLOG_PERF1(@"look for state");
            alert = [[UIAlertView alloc] initWithTitle:@"TripPlanner" message:@"Please select a location" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
    @catch (NSException *exception) {
        logException(@"ToFromViewController->routeButtonPressed", @"", exception);
    }
}

// Process an event from MapKit URL directions request
- (void)getRouteForMKDirectionsRequest
{
    NIMLOG_EVENT1(@"MapKit URL request");
    startButtonClickTime = CFAbsoluteTimeGetCurrent();
    
    [self setIsTripDateCurrentTime:YES];
    departOrArrive = DEPART;  // DE203 fix
    [self updateTripDate];
    
    logEvent(FLURRY_MAPKIT_DIRECTIONS_REQUEST,
             FLURRY_FROM_SELECTED_ADDRESS, [fromLocation shortFormattedAddress],
             FLURRY_TO_SELECTED_ADDRESS, [toLocation shortFormattedAddress],
             nil, nil, nil, nil);
    
    [self getPlan];
}


#pragma mark Reverse Geocoding

- (void)reverseGeocodeCurrentLocationIfNeeded
{
    if (!lastReverseGeoReqTime || 
        [lastReverseGeoReqTime timeIntervalSinceNow] < -(REVERSE_GEO_TIME_THRESHOLD)) {
        if (currentLocation && ![currentLocation isReverseGeoValid]) {
            // If we do not have a reverseGeoLocation that is within threshold, do another reverse geo
            lastReverseGeoReqTime = [NSDate date];
            GeocodeRequestParameters* geoParams = [[GeocodeRequestParameters alloc] init];
            geoParams.lat = [currentLocation latFloat];
            geoParams.lng = [currentLocation lngFloat];
            geoParams.supportedRegion = [self supportedRegion];
            geoParams.isFrom = true;
            if ([[[UIDevice currentDevice] systemVersion] floatValue] >= IOS_GEOCODE_VER_THRESHOLD) {
                geoParams.apiType = IOS_GEOCODER;
            } else {
                geoParams.apiType = GOOGLE_GEOCODER;
            }
            [locations reverseGeocodeWithParameters:geoParams callBack:self];
        }
    }
}

// Delegate callback from calling Locations --> reverseGeocodeWithParameters (forward Geocodes do not come from toFromViewController)
-(void)newGeocodeResults:(NSArray *)locationArray withStatus:(GeocodeRequestStatus)status parameters:(GeocodeRequestParameters *)parameters
{
    if (status == GEOCODE_STATUS_OK) {
        if ([locationArray count] > 0) { // if we have an reverse geocode object
            
            // Grab the first reverse-geo, which will be the most specific one
            Location* reverseGeoLocation = [locationArray objectAtIndex:0];
            
            // Check if an equivalent Location is already in the locations table
            reverseGeoLocation = [locations consolidateWithMatchingLocations:reverseGeoLocation keepThisLocation:NO];
            
            // Delete all the other objects out of CoreData (DE152 fix)
            for (int i=1; i<[locationArray count]; i++) {  // starting at the instance after i=0
                [[self locations] removeLocation:[locationArray objectAtIndex:i]];
            }
            // Save db context with the new location object
            saveContext(managedObjectContext);
            NIMLOG_EVENT1(@"Reverse Geocode: %@", [reverseGeoLocation formattedAddress]);
            // Update the Current Location with pointer to the Reverse Geo location
            [currentLocation setReverseGeoLocation:reverseGeoLocation];
        }
    }
    // If there is an error for reverse geocoding, do nothing
}

// Call-back from PlanStore requestPlanFromLocation:... method when it has a plan
-(void)newPlanAvailable:(Plan *)newPlan
             fromObject:(id)referringObject
                 status:(PlanRequestStatus)status
       RequestParameter:(PlanRequestParameters *)requestParameter
{
    @try {
        planRequestParameters = requestParameter;
        // If we already on routeOptionsVC, redirect this callback there instead
        UIViewController *currentVC = self.navigationController.visibleViewController;
        if (currentVC == routeOptionsVC || currentVC == routeOptionsVC.routeDetailsVC ||  
            requestParameter.hasGoneToRouteOptions.boolValue) {   // if we have already gone to routeOptionsVC for this request
            [routeOptionsVC newPlanAvailable:plan
                                  fromObject:referringObject  // Treat toFromVC as a passthru
                                      status:status
                            RequestParameter:requestParameter];
            return;
        }
        
        // else, we are not on routeOptionsVC, so handle here
        
        [self stopActivityIndicator];
        durationOfResponseTime = CFAbsoluteTimeGetCurrent() - startButtonClickTime;
        NIMLOG_OBJECT1(@"Plan =%@",newPlan);
        
        if (!routeOptionsVC) {
            routeOptionsVC = [[RouteOptionsViewController alloc] initWithNibName:nil bundle:nil];
        }
        
        if (status == PLAN_STATUS_OK || status == PLAN_EXCLUDED_TO_ZERO_RESULTS) {
            plan = newPlan;
            savetrip = FALSE;
            // DE - 155 Fixed
            if([[plan sortedItineraries] count] != 0 || status == PLAN_EXCLUDED_TO_ZERO_RESULTS) { // if PLAN_EXCLUDED_TO_ZERO_RESULTS, its OK to go to RouteOptions even with 0 sortedItineraries
                
                [requestParameter.hasGoneToRouteOptions setBoolValue:true];
                [routeOptionsVC newPlanAvailable:plan
                                      fromObject:self
                                          status:status
                                RequestParameter:requestParameter];
                
                if (fromLocation == currentLocation) {
                    // Update lastRequestReverseGeoLocation if the current one is valid, DE232 fix
                    if ([currentLocation isReverseGeoValid]) {
                        currentLocation.lastRequestReverseGeoLocation = currentLocation.reverseGeoLocation;
                    } else {
                        currentLocation.lastRequestReverseGeoLocation = nil;
                    }
                    // Part Of DE-236 Fxed
                    [[NSUserDefaults standardUserDefaults] setObject:currentLocation.lastRequestReverseGeoLocation.formattedAddress forKey:LAST_REQUEST_REVERSE_GEO];
                    [[NSUserDefaults standardUserDefaults] synchronize];

                }
                // Push the Route Options View Controller
                if([[[UIDevice currentDevice] systemVersion] intValue] < 5.0){
                    CATransition *animation = [CATransition animation];
                    [animation setDuration:0.3];
                    [animation setType:kCATransitionPush];
                    [animation setSubtype:kCATransitionFromRight];
                    [animation setRemovedOnCompletion:YES];
                    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
                    [[self.navigationController.view layer] addAnimation:animation forKey:nil];
                    [[self navigationController] pushViewController:routeOptionsVC animated:NO];
                }
                else{
                    [[self navigationController] pushViewController:routeOptionsVC animated:YES];
                }
            }
            else{ // plan.sortedItineraries.count == 0 (should not happen for PLAN_STATUS_OK)
                if([nc_AppDelegate sharedInstance].isToFromView){
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_TITLE message:ALERT_TRIP_NOT_AVAILABLE delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_BUTTON_TITLE, nil] ;
                    [alert show];
                }
            }
        }
        else if (status==PLAN_NO_NETWORK) {
            if([nc_AppDelegate sharedInstance].isToFromView){
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:@"Unable to connect to server.  Please try again when you have network connectivity." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alert show];
                savetrip = false;
            }
        }
        else if (status==PLAN_NOT_AVAILABLE_THAT_TIME) {
            if([nc_AppDelegate sharedInstance].isToFromView){
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:@"No trips available for the requested time." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [alert show];
                savetrip = false;
            }
        }
        else { // if (status == PLAN_GENERIC_EXCEPTION)
            if([nc_AppDelegate sharedInstance].isToFromView){
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Trip Planner" message:ALERT_TRIP_NOT_AVAILABLE delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil] ;
                [alert show];
                savetrip = false;
            }
        }
    }
    @catch (NSException *exception) { 
        logException(@"ToFromViewController->newPlanAvailable", @"", exception);
    }
}

- (void) reloadDataWithLocationChanged{
    [locations setAreLocationsChanged:YES];
    // Reload the to/from tables for next time
    // [[self fromTable] reloadData];
    // [[self toTable] reloadData];
}

#pragma mark get Plan Request
// Routine for calling and populating a trip-plan object
- (BOOL)getPlan
{
    // See if there has already been an identical plan request in the last 5 seconds.
    @try {
        NIMLOG_PERF1(@"Plan routine entered");
        BOOL isDuplicatePlan = NO;
        NSString *frForm = [fromLocation formattedAddress];
        NSString *toForm = [toLocation formattedAddress];
        NSDate *cutoffDate = [NSDate dateWithTimeIntervalSinceNow:-5.0];  // 5 seconds before now 
        for (int i=[planRequestHistory count]-1; i>=0; i--) {  // go thru request history backwards
            NSDictionary *d = [planRequestHistory objectAtIndex:i];
            if ([[d objectForKey:@"date"] laterDate:cutoffDate] == cutoffDate) { // if more than 5 seconds ago, stop looking
                break;  
            }
            else if ([[[d objectForKey:@"fromPlace"] formattedAddress] isEqualToString:frForm] &&
                     [[[d objectForKey:@"toPlace"] formattedAddress] isEqualToString:toForm]) {
                isDuplicatePlan = YES;
                break;
            }
        }
        
        if (!isDuplicatePlan)  // if not a recent duplicate request
        {

            [self startActivityIndicator];
            
            // Increment fromFrequency and toFrequency
            [fromLocation incrementFromFrequency];
            [toLocation incrementToFrequency];
            // Update the dateLastUsed
            NSDate* now = [NSDate date];
            [fromLocation setDateLastUsed:now];
            [toLocation setDateLastUsed:now];
            // Save db context with the new location frequencies & dates
            saveContext(managedObjectContext);
            
            if(fromLocation == toLocation ||
               ([fromLocation isCurrentLocation] && [fromLocation isReverseGeoValid] && [fromLocation reverseGeoLocation] == toLocation)) {
                [self stopActivityIndicator];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_TITLE message:@"The To: and From: address are the same location.  Please choose a different destination." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil ];
                [alert show];
                logEvent(FLURRY_ROUTE_TO_FROM_SAME,
                         FLURRY_FROM_SELECTED_ADDRESS, [fromLocation shortFormattedAddress],
                         FLURRY_TO_SELECTED_ADDRESS, [toLocation shortFormattedAddress],
                         nil, nil, nil, nil);
                return true;
            }
            // if using currentLocation, make sure it is in supported region
            if (fromLocation == currentLocation || toLocation == currentLocation) {
                if (![[self supportedRegion] isInRegionLat:[currentLocation latFloat] Lng:[currentLocation lngFloat]]) {
                    [self stopActivityIndicator];
                    NSString *msg = [NSString stringWithFormat:@"Your current location does not appear to be in the %@.  Please choose a different location.",LOCATION_NOTAPPEAR_MSG];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_TITLE message:msg delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil ];
                    [alert show];
                    NSString *supportedRegString = [NSString stringWithFormat:
                                                    @"supportedRegion minLat = %f, minLng = %f, maxLat = %f, maxLng = %f",
                                                    [[supportedRegion minLatitude] floatValue],
                                                    [[supportedRegion minLongitude] floatValue],
                                                    [[supportedRegion maxLatitude] floatValue],
                                                    [[supportedRegion maxLongitude] floatValue]];
                    logEvent(FLURRY_CURRENT_LOCATION_NOT_IN_SUPPORTED_REGION,
                             FLURRY_TOFROM_WHICH_TABLE, (fromLocation == currentLocation ? @"From" : @"To"),
                             FLURRY_LAT, [NSString stringWithFormat:@"%f", [currentLocation latFloat]],
                             FLURRY_LNG, [NSString stringWithFormat:@"%f", [currentLocation lngFloat]],
                             FLURRY_SUPPORTED_REGION_STRING,supportedRegString);
                    NIMLOG_EVENT1(@"Current Location not in supported region\n   currLoc lat = %f\n   currLoc lng = %f\n   supportedRegString = %@",
                                  [currentLocation latFloat], [currentLocation lngFloat] ,supportedRegString);
                    return true;
                }
            }
            logEvent(FLURRY_ROUTE_REQUESTED,
                     FLURRY_FROM_SELECTED_ADDRESS, [fromLocation shortFormattedAddress],
                     FLURRY_TO_SELECTED_ADDRESS, [toLocation shortFormattedAddress],
                     nil, nil, nil, nil);
            
            // add latest plan request to history array
            [planRequestHistory addObject:[NSDictionary dictionaryWithKeysAndObjects:
                                           @"fromPlace", fromLocation, 
                                           @"toPlace", toLocation,
                                           @"date", [NSDate date], nil]];

            // convert miles into meters. 1 mile = 1609.344 meters
            int maxDistance = (int)([[UserPreferance userPreferance] walkDistance]*1609.344);
            
            // Request the plan (callback will come in newPlanAvailable method)
            PlanRequestParameters* parameters = [[PlanRequestParameters alloc] init];
            parameters.fromLocation = fromLocation;
            parameters.toLocation = toLocation;
            parameters.originalTripDate = tripDate;
            parameters.thisRequestTripDate = tripDate;
            parameters.routeExcludeSettings = [RouteExcludeSettings latestUserSettings];
            parameters.departOrArrive = departOrArrive;
            parameters.maxWalkDistance = maxDistance;
            parameters.planDestination = self;
            
            parameters.formattedAddressTO = [toLocation formattedAddress];
            parameters.formattedAddressFROM = [fromLocation formattedAddress];
            parameters.latitudeTO = (NSString *)[toLocation lat];
            parameters.longitudeTO = (NSString *)[toLocation lng];
            parameters.latitudeFROM = (NSString *)[fromLocation lat];
            parameters.longitudeFROM = (NSString *)[fromLocation lng];
            parameters.hasGoneToRouteOptions = [[MutableBoolean alloc] initWithBool:false];
            if([fromLocation isCurrentLocation]) {
                parameters.fromType = REVERSE_GEO_FROM;
                parameters.formattedAddressFROM = currentLoc;
                parameters.latitudeTO = (NSString *)[toLocation lat];
                parameters.longitudeTO = (NSString *)[toLocation lng];
            }else if([toLocation isCurrentLocation]) {
                parameters.toType = REVERSE_GEO_TO;
                parameters.formattedAddressTO = currentLoc;
                parameters.latitudeFROM = (NSString *)[fromLocation lat];
                parameters.longitudeFROM = (NSString *)[fromLocation lng];
            }
            if ([locations isFromGeo]) {
                parameters.fromType = GEO_FROM;
                parameters.rawAddressFROM = [fromLocation formattedAddress];
                parameters.timeFROM = [locations geoRespTimeFrom];
            } else if ([locations isToGeo]) {
                parameters.toType = GEO_TO;
                parameters.rawAddressFROM = [fromLocation formattedAddress] ;
                parameters.timeTO = [locations geoRespTimeTo];
            }
            [nc_AppDelegate sharedInstance].isRouteOptionView = true;
            [planStore requestPlanWithParameters:parameters];
            savetrip = TRUE;
            isContinueGetRealTimeData = NO;
            [self performSelector:@selector(reloadDataWithLocationChanged) withObject:nil afterDelay:0.01];
        }
        return true; 
    }
    @catch (NSException *exception) {
        logException(@"ToFromViewController->getPlan", @"", exception);
    }
}


#pragma mark Indicator Activity to notify user about processing 
-(void)startActivityIndicator
{
    @try {
        self.view.userInteractionEnabled = NO;
        if (!activityIndicator) {
            UIActivityIndicatorViewStyle style;
            BOOL setColorToBlack = NO;
            if ([UIActivityIndicatorView instancesRespondToSelector:@selector(setColor:)]) {
                style = UIActivityIndicatorViewStyleWhiteLarge;
                setColorToBlack = YES;
            }
            else {
                style = UIActivityIndicatorViewStyleGray;
            }
            activityIndicator = [[UIActivityIndicatorView alloc]  
                                 initWithActivityIndicatorStyle:style];
            if (setColorToBlack) {
                [activityIndicator setColor:[UIColor blackColor]];
            }
        }
        activityIndicator.center = CGPointMake(self.view.bounds.size.width / 2,   
                                               (self.view.bounds.size.height/2));
        if (![activityIndicator isAnimating]) {
            [activityIndicator setUserInteractionEnabled:FALSE];
            [activityIndicator startAnimating]; // if not already animating, start
        }
        if (![activityIndicator superview]) {
            [[self view] addSubview:activityIndicator]; // if not already in the view, add it
        }
        // Set up timer to remove activity indicator after 60 seconds
        if (activityTimer && [activityTimer isValid]) {
            [activityTimer invalidate];  // if old activity timer still valid, invalidate it
        }
        [NSTimer scheduledTimerWithTimeInterval:TIMER_STANDARD_REQUEST_DELAY target:self selector: @selector(stopActivityIndicator) userInfo: nil repeats: NO];
    }
    @catch (NSException *exception) {
        logException(@"ToFromViewController->startActivityIndicator", @"", exception);
    }
}

-(void)stopActivityIndicator
{
    self.view.userInteractionEnabled = YES;
    [activityIndicator stopAnimating];
    [activityIndicator removeFromSuperview];
    if (activityTimer && [activityTimer isValid]) {
        [activityTimer invalidate];  // if activity timer still valid, invalidate it
    }
}


//Request responder to push a LocationPickerViewController so the user can pick from the locations in locationList
- (void)callLocationPickerFor:(ToFromTableViewController *)toFromTableVC0 locationList:(NSArray *)locationList0 isFrom:(BOOL)isFrom0 isGeocodeResults:(BOOL)isGeocodeResults0
{
    @try {
        if (!locationPickerVC) {
            locationPickerVC = [[LocationPickerViewController alloc] initWithNibName:nil bundle:nil];
        }
        [locationPickerVC setToFromTableVC:toFromTableVC0];
        [locationPickerVC setLocationArray:locationList0];
        [locationPickerVC setIsFrom:isFrom0];
        [locationPickerVC setIsGeocodeResults:isGeocodeResults0];
        
        // DE-310 Fixed
        // Added Error Handling such that LocationPickerViewController is pushed only once even if user select the StationList multiple times.
        BOOL isAlreadyPushed = NO;
        for(UIViewController *controller in self.navigationController.viewControllers){
            if([controller isKindOfClass:[LocationPickerViewController class]]){
                isAlreadyPushed = YES;
            }
        }
        if(!isAlreadyPushed){
            CATransition *animation = [CATransition animation];
            [animation setDuration:0.3];
            [animation setType:kCATransitionPush];
            [animation setSubtype:kCATransitionFromRight];
            [animation setRemovedOnCompletion:YES];
            [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
            [[self.navigationController.view layer] addAnimation:animation forKey:nil];
            [[self navigationController] pushViewController:locationPickerVC animated:NO];
        }
    }
    @catch (NSException *exception) {
        logException(@"ToFromViewController->callLocationPickerFor", @"", exception);
    }
}

#pragma mark Redirect to IPhone LocationServices Setting 
-(void)alertView: (UIAlertView *)UIAlertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    @try {
        NSString *btnName = [UIAlertView buttonTitleAtIndex:buttonIndex];
        if ([btnName isEqualToString:@"Yes"]) {
            NimblerApplication *sharedApp = (NimblerApplication *)[UIApplication sharedApplication];
            [sharedApp openURLWithoutWebView:[NSURL URLWithString:@"prefs:root=LocationServices"]];
        }    
    }
    @catch (NSException *exception) {
        logException(@"ToFromViewController->clickedButtonAtIndex", @"", exception);
    }
}
#pragma mark get walk distance from User Defaults

-(void)setFBParameterForGeneral
{
    @try {
        NSString *fromLocs = NULL_STRING;    
        NSDateFormatter* dFormat = [[NSDateFormatter alloc] init];
        [dFormat setDateStyle:NSDateFormatterShortStyle];
        [dFormat setTimeStyle:NSDateFormatterMediumStyle];
        if ([fromLocation isCurrentLocation]) {
            if ([fromLocation reverseGeoLocation]) {
                fromLocs = [NSString stringWithFormat:@"Current Location Reverse Geocode: %@",[[fromLocation reverseGeoLocation] formattedAddress]];
                } else {
                    fromLocs = CURRENT_LOCATION;
                }
        } else {
            fromLocs = [fromLocation formattedAddress];
        }
        [nc_AppDelegate sharedInstance].FBSource = [NSNumber numberWithInt:FB_SOURCE_GENERAL];
        [nc_AppDelegate sharedInstance].FBDate = [dFormat stringFromDate:tripDate];
        [nc_AppDelegate sharedInstance].FBToAdd = [toLocation formattedAddress];
        [nc_AppDelegate sharedInstance].FBSFromAdd = fromLocs;
        [nc_AppDelegate sharedInstance].FBUniqueId = nil;
    }
    @catch (NSException *exception) {
        logException(@"ToFromViewController->setFBParametersForGeneral", @"", exception);
    }
}

// US132 implementation
- (IBAction)doSwapLocation:(id)sender
{
     // Part Of DE-236 Fxed
    if([[NSUserDefaults standardUserDefaults] objectForKey:LAST_REQUEST_REVERSE_GEO]){
        NSArray* toLocations = [locations locationsWithFormattedAddress:[[NSUserDefaults standardUserDefaults] objectForKey:LAST_REQUEST_REVERSE_GEO]];
        if([toLocations count] > 0){
            currentLocation.lastRequestReverseGeoLocation = [toLocations objectAtIndex:0];
        }
    }
    //DE-237 Fixed
    // US-243 implementation (removing custom code so we do not treat Current Location differently)
    if(fromLocation == toLocation) {
        // Do nothing if locations are the same
    }
    else {  // do a normal swap
        Location *fromloc = fromLocation;
        Location *toLoc = toLocation;
        // Swap Location (could be nil)
        [toTableVC markAndUpdateSelectedLocation:fromloc];
        [fromTableVC markAndUpdateSelectedLocation:toLoc];
    }
    
    Location *selectedFromLocation = [locations selectedFromLocation];
    NSString *strFromFormattedAddress;
    if(selectedFromLocation.locationName){
      strFromFormattedAddress = [selectedFromLocation locationName];
    }
    else if([selectedFromLocation.userUpdatedLocation boolValue]){
        strFromFormattedAddress = [selectedFromLocation formattedAddress];
    }
    else{
        strFromFormattedAddress = [selectedFromLocation shortFormattedAddress];
    }
    if(![strFromFormattedAddress length]>0){
        strFromFormattedAddress = [[NSUserDefaults standardUserDefaults] objectForKey:LAST_FROM_LOCATION];
        NSArray *matchingLocations = [locations locationsWithFormattedAddress:strFromFormattedAddress];
        if([matchingLocations count] > 0){
            strFromFormattedAddress = ((Location *)[matchingLocations objectAtIndex:0]).shortFormattedAddress;
        }
    }
    if(!strFromFormattedAddress){
        strFromFormattedAddress = @"";
    }
    [self.txtFromView setText:strFromFormattedAddress];
    
    Location *selectedToLocation = [locations selectedToLocation];
    NSString *strToFormattedAddress;
    if(selectedToLocation.locationName){
        strToFormattedAddress = [selectedToLocation locationName];
    }
    else if([selectedToLocation.userUpdatedLocation boolValue]){
        strToFormattedAddress = [selectedToLocation formattedAddress];
    }
    else{
        strToFormattedAddress = [selectedToLocation shortFormattedAddress];
    }
    if(![strToFormattedAddress length]>0){
        strToFormattedAddress = [[NSUserDefaults standardUserDefaults] objectForKey:LAST_TO_LOCATION];
        NSArray *matchingLocations = [locations locationsWithFormattedAddress:strToFormattedAddress];
        if([matchingLocations count] > 0){
            strToFormattedAddress = ((Location *)[matchingLocations objectAtIndex:0]).shortFormattedAddress;
        }
    }
    if(!strToFormattedAddress){
        strToFormattedAddress = @"";
    }
    [self.txtToView setText:strToFormattedAddress];
    logEvent(FLURRY_TOFROM_SWAP_LOCATION,
             FLURRY_TO_SELECTED_ADDRESS, [[self toLocation] shortFormattedAddress],
             FLURRY_FROM_SELECTED_ADDRESS, [[self fromLocation] shortFormattedAddress],
             nil, nil, nil, nil);
}

#pragma mark UIdatePicker functionality

- (void)selectDate {
    [btnPicker setUserInteractionEnabled:YES];
     [self.navigationController.navigationBar setUserInteractionEnabled:YES];
    [nc_AppDelegate sharedInstance].isDatePickerOpen = NO;
    [[nc_AppDelegate sharedInstance].twitterCount setHidden:NO];  // fished out from showTabbar method -- is this really needed, JC 10/5/2014
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:ANIMATION_STANDART_MOTION_SPEED];
    [toolBar setFrame:CGRectMake(0,
                                 self.view.frame.size.height,
                                 self.view.frame.size.width,
                                 DATE_PICKER_TOOLBAR_HEIGHT)];  // move it back off bottom of screen
    [datePicker setFrame:CGRectMake(0,
                                    self.view.frame.size.height + DATE_PICKER_TOOLBAR_HEIGHT,
                                    self.view.frame.size.width,
                                    DATE_PICKER_HEIGHT)];  // move it back off bottom of screen
    [UIView commitAnimations];
    
    
    if (departOrArrive==DEPART) {
        self.lblTxtDepartArrive.text = @"Depart:";
        [self.btnPicker setTitle:[NSString stringWithFormat:@"%@",
                                  [[tripDateFormatter stringFromDate:[datePicker date]] lowercaseString]] forState:UIControlStateNormal];
    } else {
        self.lblTxtDepartArrive.text = @"Arrive:";
        [self.lblTxtDepartArrive setTextAlignment:NSTextAlignmentRight];
        [self.btnPicker setTitle:[NSString stringWithFormat:@"%@",
                                  [[tripDateFormatter stringFromDate:[datePicker date]] lowercaseString]] forState:UIControlStateNormal];
    }
   
    date = [datePicker date];
    [self setTripDate:date];
    [self setTripDateLastChangedByUser:[[NSDate alloc] init]];
    [self setIsTripDateCurrentTime:NO];
    [self setDepartOrArrive:departOrArrive];
    [self updateTripDate];
}

//---------------------------------------------------------------------------

- (void)selectCurrentDate {
    date = [NSDate date];
    [self.navigationController.navigationBar setUserInteractionEnabled:YES];
    [nc_AppDelegate sharedInstance].isDatePickerOpen = NO;
    [btnPicker setUserInteractionEnabled:YES];
    [[nc_AppDelegate sharedInstance].twitterCount setHidden:NO];  // fished out from showTabbar method -- is this really needed, JC 10/5/2014
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:ANIMATION_STANDART_MOTION_SPEED];
    [toolBar setFrame:CGRectMake(0,
                                 self.view.frame.size.height,
                                 self.view.frame.size.width,
                                 DATE_PICKER_TOOLBAR_HEIGHT)];  // move it back off bottom of screen
    [datePicker setFrame:CGRectMake(0,
                                    self.view.frame.size.height + DATE_PICKER_TOOLBAR_HEIGHT,
                                    self.view.frame.size.width,
                                    DATE_PICKER_HEIGHT)];  // move it back off bottom of screen
    [UIView commitAnimations];
    
    isTripDateCurrentTime = TRUE;
    if (isTripDateCurrentTime) {
        [self.btnPicker setTitle:@"Now" forState:UIControlStateNormal];
    }
    [self setTripDateLastChangedByUser:[[NSDate alloc] init]];
    [self setIsTripDateCurrentTime:YES];
    [self setDepartOrArrive:DEPART];  // DE201 fix -- always select Depart if we pick the Now button
    [self updateTripDate];
}

//---------------------------------------------------------------------------

- (IBAction)openPickerView:(id)sender {
    [btnPicker setUserInteractionEnabled:NO];
    
    // Fixed DE-331
    datePicker = nil;
    datePicker = [[UIDatePicker alloc]initWithFrame:CGRectMake(0,
                                                               self.view.frame.size.height + DATE_PICKER_TOOLBAR_HEIGHT,
                                                               self.view.frame.size.width,
                                                               DATE_PICKER_HEIGHT)];  // initially locate it off bottom of screen
    datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    datePicker.minuteInterval = 5;
    [datePicker setBackgroundColor:[self.view backgroundColor]];  // Fix overlap problem for iPhone4 see-through problem
    NIMLOG_AUTOSIZE(@"Background color: %@", [datePicker backgroundColor]);
    
    NSDate *savedDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"todayDate"];
    if(savedDate && [savedDate isEqualToDate:dateOnlyFromDate([NSDate date])]){
        NSDate *selectedDate = date;
        if(selectedDate){
            [datePicker setDate:selectedDate animated:YES];
        }
    }
    else{
        [datePicker setDate:[NSDate date] animated:YES];
        [[NSUserDefaults standardUserDefaults] setObject:dateOnlyFromDate([NSDate date]) forKey:@"todayDate"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [self.view addSubview:datePicker];
    [nc_AppDelegate sharedInstance].isDatePickerOpen = YES;
    toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0,
                                                          self.view.frame.size.height,
                                                          self.view.frame.size.width,
                                                          DATE_PICKER_TOOLBAR_HEIGHT)];  // initially locate it off bottom of screen
    [toolBar setTintColor:[UIColor darkGrayColor]];
    
    if (departOrArrive == DEPART) {
        [departArriveSelector setSelectedSegmentIndex:0];
    } else {
        [departArriveSelector setSelectedSegmentIndex:1];
    }
    UIBarButtonItem *segmentBtn = [[UIBarButtonItem alloc] initWithCustomView:departArriveSelector];
    UIBarButtonItem *flexibaleSpaceBarButton1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *flexibaleSpaceBarButton2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [toolBar setItems:[NSArray arrayWithObjects:btnNow,flexibaleSpaceBarButton1,segmentBtn,flexibaleSpaceBarButton2,btnDone, nil]];
    [self.view bringSubviewToFront:toolBar];
    [self.view bringSubviewToFront:datePicker];

    [self.view addSubview:toolBar];
    [UIView beginAnimations:nil context:nil];  // Animation to bring it onto the screen
    [UIView setAnimationDuration:ANIMATION_STANDART_MOTION_SPEED];
    [toolBar setFrame:CGRectMake(0,
                                 self.view.frame.size.height - DATE_PICKER_TOOLBAR_HEIGHT - DATE_PICKER_HEIGHT - DATE_PICKER_MARGIN_FROM_BOTTOM,
                                 self.view.frame.size.width,
                                 DATE_PICKER_TOOLBAR_HEIGHT)];
    [datePicker setFrame:CGRectMake(0,
                                    self.view.frame.size.height - DATE_PICKER_HEIGHT - DATE_PICKER_MARGIN_FROM_BOTTOM,
                                    self.view.frame.size.width,
                                    DATE_PICKER_HEIGHT)];
    [UIView commitAnimations];
}

// at Segment change 
-(void)segmentChange {
    if ([departArriveSelector selectedSegmentIndex] == 0) {
        departOrArrive = DEPART;
    } else {
        departOrArrive = ARRIVE;
        // Move date to at least one hour from now if not already
        NSDate* nowPlus1hour = [[NSDate alloc] initWithTimeIntervalSinceNow:(60.0*60)];  // 1 hour from now
        if ([date earlierDate:nowPlus1hour] == date) { // if date is earlier than 1 hour from now
            date = nowPlus1hour;
            [datePicker setDate:date animated:YES];
        }
    }
}

#pragma mark Hide and Show Tabbar

@end