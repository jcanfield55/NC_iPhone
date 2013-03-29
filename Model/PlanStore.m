//
//  PlanStore.m
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/19/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "PlanStore.h"
#import "UtilityFunctions.h"
#import "Logging.h"
#import <RestKit/Restkit.h>
#import <RestKit/CoreData.h>
#import <Restkit/RKJSONParserJSONKit.h>
#import "nc_AppDelegate.h"
#import "GtfsStopTimes.h"
#import "GtfsStop.h"
#import "GtfsParsingStatus.h"
#import "RealTimeManager.h"
#import "RouteExcludeSettings.h"
#import "UserPreferance.h"

@interface PlanStore()
{
    // Variables for internal use
    NSString *planURLResource; // URL resource sent to planner
    NSDateFormatter* dateFormatter; // date formatter for OTP requests
    NSDateFormatter* timeFormatter; // time formatter for OTP requests
    NSMutableDictionary* parametersByPlanURLResource; // Key is the planURLResource, object = request parameters
    NSMutableDictionary* latestParametersForPlanIdDictionary;  // Get latest parameters indexed by the planId
}

@end

@implementation PlanStore

@synthesize managedObjectModel;
@synthesize managedObjectContext;
@synthesize rkPlanMgr;
@synthesize plansWaitingForGtfsData;

// Designated initializer
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc rkPlanMgr:(RKObjectManager *)rkP
{
    self = [super init];
    if (self) {
        managedObjectContext = moc;
        managedObjectModel = [[moc persistentStoreCoordinator] managedObjectModel];
        rkPlanMgr = rkP;
        parametersByPlanURLResource = [[NSMutableDictionary alloc] initWithCapacity:10];
        latestParametersForPlanIdDictionary = [NSMutableDictionary dictionaryWithCapacity:20];
        plansWaitingForGtfsData = [NSMutableSet setWithCapacity:10];
    }
    return self;
}

// Requests a plan with the given parameters
// Will get plan from the cache if available and will call OTP if not
// Will call back the newPlanAvailable method on toFromVC when the first plan is available
// Will continue to call OTP iteratively to obtain other itineraries up to the designated max # and time
// After returning the first itinerary, it will call the newPlanAvailable method on routeOptionsVC each
// time it has an update
- (void)requestPlanWithParameters:(PlanRequestParameters *)parameters
{
    @try {
        // Check if we have a stored plan that we can use
        NSArray* matchingPlanArray = [self fetchPlansWithToLocation:[parameters toLocation]
                                                       fromLocation:[parameters fromLocation]];
        
        if (matchingPlanArray && [matchingPlanArray count]>0) {
            Plan* matchingPlan = [matchingPlanArray objectAtIndex:0]; // Take the first matching plan
            [matchingPlan updateExcludeSettingsArray];   // Update with latest excludeSettings
            if ([matchingPlan prepareSortedItinerariesWithMatchesForDate:[parameters originalTripDate]
                                                          departOrArrive:[parameters departOrArrive]
                                                    routeExcludeSettings:[parameters routeExcludeSettings]
                                                 generateGtfsItineraries:NO
                                                   removeNonOptimalItins:YES]) {
                PlanRequestStatus reqStatus;
                MoreItineraryStatus moreItinStatus = [self requestMoreItinerariesIfNeeded:matchingPlan parameters:parameters];
                if (matchingPlan.sortedItineraries.count == 0) {
                    logEvent(FLURRY_ROUTE_NOT_IN_CACHE,
                             FLURRY_FROM_SELECTED_ADDRESS, [parameters.fromLocation shortFormattedAddress],
                             FLURRY_TO_SELECTED_ADDRESS, [parameters.toLocation shortFormattedAddress],
                             nil, nil, nil, nil);
                    if (moreItinStatus != NO_MORE_ITINERARIES_REQUESTED) {
                        return;  // Do not callback toFromVC, but rather wait for results from OTP
                    } else {
                        reqStatus = PLAN_EXCLUDED_TO_ZERO_RESULTS; // Go to RouteOptions and let users adjust excludes
                    }
                } else {
                    NIMLOG_EVENT1(@"Matches found in plan cache");
                    logEvent(FLURRY_ROUTE_FROM_CACHE,
                             FLURRY_FROM_SELECTED_ADDRESS, [parameters.fromLocation shortFormattedAddress],
                             FLURRY_TO_SELECTED_ADDRESS, [parameters.toLocation shortFormattedAddress],
                             nil, nil, nil, nil);
                    reqStatus = PLAN_STATUS_OK;
                }
                ToFromViewController* toFromVC = [[nc_AppDelegate sharedInstance] toFromViewController];
                if(toFromVC.timerGettingRealDataByItinerary != nil){
                    [toFromVC.timerGettingRealDataByItinerary invalidate];
                    toFromVC.timerGettingRealDataByItinerary = nil;
                }
                
                // Callback to planDestination with new plan
                [parameters.planDestination newPlanAvailable:matchingPlan
                                                  fromObject:self
                                                      status:reqStatus
                                            RequestParameter:parameters];

                return;
            }
        }
        // if no appropriate plan in cache, request one from OTP
        logEvent(FLURRY_ROUTE_NOT_IN_CACHE,
                 FLURRY_FROM_SELECTED_ADDRESS, [parameters.fromLocation shortFormattedAddress],
                 FLURRY_TO_SELECTED_ADDRESS, [parameters.toLocation shortFormattedAddress],
                 nil, nil, nil, nil);

        
        NSArray *exclArray = [RouteExcludeSettings arrayWithNoExcludesExceptExcludeBike:[parameters.routeExcludeSettings settingForKey:BIKE_BUTTON]];
        [self requestPlanFromOtpWithParameters:parameters
                      routeExcludeSettingArray:exclArray];
    }
    @catch (NSException *exception) {
        logException(@"PlanStore->requestPlanWithParameters:", @"", exception);
    }
}

// Requests for a new plan from OTP using parameters
// If exclSettingArray is nil, will not exclude any routes in the OTP request
// To exclude routes, set exclSettingArray to an array of RouteExcludeSetting objects as returned by RouteExcludeSettings -> excludeSettingsForPlan
-(void)requestPlanFromOtpWithParameters:(PlanRequestParameters *)parameters
               routeExcludeSettingArray:(NSArray *)exclSettingArray
{
    [nc_AppDelegate sharedInstance].receivedReply = NO;
    [nc_AppDelegate sharedInstance].receivedError = NO;
    @try {
        // Create the date formatters we will use to output the date & time
        if (!dateFormatter) {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"MM/dd/yyyy"];
        }
        if (!timeFormatter) {
            timeFormatter = [[NSDateFormatter alloc] init];
            [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
            [timeFormatter setDateStyle:NSDateFormatterNoStyle];
        }
        NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
        [params setObject:[[NSUserDefaults standardUserDefaults]objectForKey:DEVICE_TOKEN] forKey:DEVICE_TOKEN];
        
        if([[parameters fromLocation] latLngPairStr]){
            [params setObject:[[parameters fromLocation] latLngPairStr] forKey:FROM_PLACE];
        }
        if([[parameters toLocation] latLngPairStr]){
            [params setObject:[[parameters toLocation] latLngPairStr]   forKey:TO_PLACE];
        }
        if([dateFormatter stringFromDate:[parameters thisRequestTripDate]]){
            [params setObject:[dateFormatter stringFromDate:[parameters thisRequestTripDate]] forKey:REQUEST_TRIP_DATE];
        }
        if([timeFormatter stringFromDate:[parameters thisRequestTripDate]]){
            [params setObject:[timeFormatter stringFromDate:[parameters thisRequestTripDate]] forKey:REQUEST_TRIP_TIME];
        }
        
        [params setObject:(([parameters departOrArrive] == ARRIVE) ? @"true" : @"false") forKey:ARRIVE_BY];

        if([NSNumber numberWithInt:[parameters maxWalkDistance]]){
            [params setObject:[NSNumber numberWithInt:[parameters maxWalkDistance]] forKey:MAX_WALK_DISTANCE];
        }
        if([[NSUserDefaults standardUserDefaults]objectForKey:DEVICE_CFUUID]){
            [params setObject:[[NSUserDefaults standardUserDefaults]objectForKey:DEVICE_CFUUID] forKey:DEVICE_ID];
        }
        if(parameters.formattedAddressTO){
            [params setObject:parameters.formattedAddressTO forKey:FORMATTED_ADDRESS_TO];
        }
        if(parameters.formattedAddressFROM){
            [params setObject:parameters.formattedAddressFROM forKey:FORMATTED_ADDRESS_FROM];
        }
        if(parameters.latitudeFROM){
            [params setObject:parameters.latitudeFROM forKey:LATITUDE_FROM];
        }
        if(parameters.longitudeFROM){
            [params setObject:parameters.longitudeFROM forKey:LONGITUDE_FROM];
        }
        if(parameters.latitudeTO){
            [params setObject:parameters.latitudeTO forKey:LATITUDE_TO];
        }
        if(parameters.longitudeTO){
            [params setObject:parameters.longitudeTO forKey:LONGITUDE_TO];
        }
        if(parameters.fromType){
            [params setObject:parameters.fromType forKey:FROM_TYPE];
        }
        if(parameters.toType){
            [params setObject:parameters.toType forKey:TO_TYPE];
        }
        if(parameters.rawAddressFROM){
            [params setObject:parameters.rawAddressFROM forKey:RAW_ADDRESS_FROM];
        }
        if(parameters.timeFROM){
            [params setObject:parameters.timeFROM forKey:TIME_FROM];
        }
        if(parameters.rawAddressTO){
            [params setObject:parameters.rawAddressTO forKey:RAW_ADDRESS_TO];
        }
        if(parameters.timeTO){
            [params setObject:parameters.timeTO forKey:TIME_TO];
        }
        if([nc_AppDelegate sharedInstance].isTestPlan){
            [params setObject:@"false" forKey:SAVE_PLAN];
        }
        // Set Bike Mode parameters if needed
        if (parameters.routeExcludeSettings && 
            [parameters.routeExcludeSettings settingForKey:BIKE_BUTTON]==SETTING_INCLUDE_ROUTE) {
            [params setObject:REQUEST_TRANSIT_MODE_TRANSIT_BIKE forKey:REQUEST_TRANSIT_MODE];
            UserPreferance* userPrefs = [UserPreferance userPreferance];
            [params setObject:[NSString stringWithFormat:@"%f", userPrefs.bikeTriangleQuick]
                       forKey:REQUEST_BIKE_TRIANGLE_QUICK];
            [params setObject:[NSString stringWithFormat:@"%f", userPrefs.bikeTriangleFlat]
                       forKey:REQUEST_BIKE_TRIANGLE_FLAT];
            float bikeRemainder = 1.0 - [[params objectForKey:REQUEST_BIKE_TRIANGLE_QUICK] floatValue] - [[params objectForKey:REQUEST_BIKE_TRIANGLE_FLAT] floatValue];
            [params setObject:[NSString stringWithFormat:@"%f", bikeRemainder]    // use bikeRemainder so we exactly add up to 1.0
                       forKey:REQUEST_BIKE_TRIANGLE_BIKE_FRIENDLY];
            [params setObject:@"TRIANGLE" forKey:@"optimize"];
            int maxDistance = (int)(userPrefs.bikeDistance*1609.544);
            [params setObject:[NSNumber numberWithInt:maxDistance] forKey:MAX_WALK_DISTANCE];
        } else {
            [params setObject:REQUEST_TRANSIT_MODE_TRANSIT forKey:REQUEST_TRANSIT_MODE];
        }
        NSString *strAgencies = [parameters.routeExcludeSettings bannedAgencyStringForSettingArray:exclSettingArray];
        NSString *strAgenciesWithMode = [parameters.routeExcludeSettings bannedAgencyByModeStringForSettingArray:exclSettingArray];

        NIMLOG_US202(@"Calling OTP at: %@, exclusions = %@,%@",parameters.thisRequestTripDate, strAgencies, strAgenciesWithMode);
        if(strAgencies && strAgencies.length > 0){
            [params setObject:strAgencies forKey:BANNED_AGENCIES];
        }
        if(strAgenciesWithMode && strAgenciesWithMode.length > 0){
            [params setObject:strAgenciesWithMode forKey:BANNED_AGENCIES_WITH_MODE];
        }
        [params setObject:@"true" forKey:SHOW_INTERMEDIATE_STOPS];
        parameters.otpExcludeAgencyString = strAgencies;
        parameters.otpExcludeAgencyByModeString = strAgenciesWithMode;
        
        [params setObject:[[nc_AppDelegate sharedInstance] getAppTypeFromBundleId] forKey:APPLICATION_TYPE];
        // Build the parameters into a resource string
        parameters.serverCallsSoFar = parameters.serverCallsSoFar + 1;
        // TODO handle changes to maxWalkDistance with plan caching
        NSString *requestID = generateRandomString();
        
        // Append The requestID to the URL.
        // Now we set that String as key of our  parametersByPlanURLResource Dictionary.
        // Now when we receive response or we receive an error we can get our planRequestParamater by key [objectloader resourcePath].
        
        NIMLOG_DEBUG1(@"Submitted Request ID=%@",requestID);
         NSString *strPlanGenerateURL = [NSString stringWithFormat:@"%@?id=%@",PLAN_GENERATE_URL,requestID];
        
        [parametersByPlanURLResource setObject:parameters forKey:strPlanGenerateURL];
        Plan *plan;
        RKParams *requestParameter = [RKParams paramsWithDictionary:params];
        [rkPlanMgr postObject:plan delegate:self block:^(RKObjectLoader *loader){
            loader.resourcePath = strPlanGenerateURL;
            loader.params = requestParameter;
            loader.method = RKRequestMethodPOST;
        }];
    }
    @catch (NSException *exception) {
        logException(@"PlanStore->requestPlanFromOTPWithParameters", @"", exception);
    }
}

// Delegate methods for when the RestKit has results from the Planner
- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray *)objects{
    [nc_AppDelegate sharedInstance].receivedReply = YES;
    PlanRequestParameters* planRequestParameters;
    @try {
        RKJSONParserJSONKit* rkParser = [RKJSONParserJSONKit new];
        NSDictionary *tempResponseDictionary = [rkParser objectFromString:[[objectLoader response] bodyAsString] error:nil];
        if([[tempResponseDictionary objectForKey:RESPONSE_CODE] intValue] == RESPONSE_SUCCESSFULL){
            if([tempResponseDictionary objectForKey:OTP_ERROR_STATUS]){
                if ([nc_AppDelegate sharedInstance].isToFromView) {
                    // only show error if on To & From View Controller, otherwise do nothing
                    UIAlertView *alertView = [[UIAlertView alloc] init];
                    [alertView setDelegate:self];
                    [alertView setTitle:APP_TITLE];
                    [alertView setMessage:ROUTE_NOT_POSSIBLE_MSG];
                    [alertView addButtonWithTitle:OK_BUTTON_TITLE];
                    [alertView show];
                    logEvent(FLURRY_ROUTE_OTHER_ERROR,
                             FLURRY_RK_RESPONSE_ERROR, [tempResponseDictionary objectForKey:OTP_ERROR_STATUS],
                             nil, nil, nil, nil, nil, nil);
                    ToFromViewController* toFromVC = [[nc_AppDelegate sharedInstance] toFromViewController];
                    [toFromVC.activityIndicator stopAnimating];
                    [toFromVC.view setUserInteractionEnabled:YES];
                }
            }
            else{
                Plan *plan = [objects objectAtIndex:0];
                if([nc_AppDelegate sharedInstance].isTestPlan){
                    [nc_AppDelegate sharedInstance].testPlan = plan;
                }
                NSString *strResourcePath = [objectLoader resourcePath];
                if (strResourcePath && [strResourcePath length]>0) {
                    planRequestParameters = [parametersByPlanURLResource objectForKey:strResourcePath];
                    [parametersByPlanURLResource removeObjectForKey:strResourcePath]; // Clear out entry from dictionary now we are done with it
                } else {
                    [NSException raise:@"PlanStore->didLoadObjects failed to retrieve plan parameters" format:@"strResourcePath: %@", strResourcePath];
                }
                // Request GTFS schedule data as needed
                [[nc_AppDelegate sharedInstance].gtfsParser generateGtfsTripsRequestStringUsingPlan:plan];
                
                // Set to & from location with special handling of CurrentLocation
                Location *toLoc = [planRequestParameters toLocation];
                if ([toLoc isCurrentLocation] && [toLoc isReverseGeoValid]) {
                    plan.toLocation = [toLoc reverseGeoLocation];
                } else {
                    plan.toLocation = toLoc;
                }
                Location* fromLoc = [planRequestParameters fromLocation];
                if ([fromLoc isCurrentLocation] && [fromLoc isReverseGeoValid]) {
                    plan.fromLocation = [fromLoc reverseGeoLocation];
                } else {
                    plan.fromLocation = fromLoc;
                }
                [plan initializeNewPlanFromOTPWithRequestDate:[planRequestParameters thisRequestTripDate]
                                                          departOrArrive:[planRequestParameters departOrArrive]
                                                     routeExcludeSettings:planRequestParameters.routeExcludeSettingsUsedForOTPCall];
                // Make sure that we still have itineraries (ie it wasn't just overnight itineraries)
                // Part of the DE161 fix
                if ([[plan itineraries] count] == 0) {
                    NIMLOG_EVENT1(@"Plan with just overnight itinerary deleted");
                    [managedObjectContext deleteObject:plan];
                    saveContext(managedObjectContext);
                    if (planRequestParameters.isDestinationToFromVC) {
                        [planRequestParameters.planDestination newPlanAvailable:nil
                                                                     fromObject:self
                                                                         status:PLAN_NOT_AVAILABLE_THAT_TIME
                                                               RequestParameter:planRequestParameters];
                        logEvent(FLURRY_ROUTE_NOT_AVAILABLE_THAT_TIME,
                                 FLURRY_NEW_DATE, [NSString stringWithFormat:@"%@",[planRequestParameters thisRequestTripDate]],
                                 nil, nil, nil, nil, nil, nil);
    
                    } // else if routeOptions destination, do nothing
                    return;
                }
                [plan setLegsId];
                saveContext(managedObjectContext);  // Save location and request chunk changes
                plan = [self consolidateWithMatchingPlans:plan]; // Consolidate plans & save context
                
                // Add plans to the list for having outstanding gtfsParsingRequests if applicable
                if (plan.planId && planRequestParameters) {
                    [latestParametersForPlanIdDictionary setObject:planRequestParameters forKey:plan.planId];
                    if (plan.gtfsParsingRequests.count > 0) {
                        [plansWaitingForGtfsData addObject:plan];
                    }
                }
                // Now format the itineraries of the consolidated plan
                // get Unique Itinerary from Plan.
                if ([plan prepareSortedItinerariesWithMatchesForDate:[planRequestParameters originalTripDate]
                                                      departOrArrive:[planRequestParameters departOrArrive]
                                                routeExcludeSettings:[RouteExcludeSettings latestUserSettings] // use latest settings in case something changed
                                             generateGtfsItineraries:NO
                                               removeNonOptimalItins:YES]) {
                    
                    MoreItineraryStatus moreItinStatus = [self requestMoreItinerariesIfNeeded:plan parameters:planRequestParameters];
                    PlanRequestStatus reqStatus = PLAN_STATUS_OK;
                    if ([[plan sortedItineraries] count] == 0) {
                        if (moreItinStatus == MORE_ITINERARIES_REQUESTED_DIFFERENT_EXCLUDES) {
                            NIMLOG_US202(@"0 sorted itineraries, waiting for next OTP request");
                            return;  // Do not call back to planDestination -- keep waiting for OTP
                        } else {
                            reqStatus = PLAN_EXCLUDED_TO_ZERO_RESULTS;  // Show zero results on RouteOptions page
                        }
                    } else {
                        reqStatus = PLAN_STATUS_OK;
                    }
                    // Call-back the appropriate VC with the new plan
                    [planRequestParameters.planDestination newPlanAvailable:plan
                                                                 fromObject:self
                                                                     status:reqStatus
                                                           RequestParameter:planRequestParameters];

                } else { // no matching sorted itineraries.  DE189 fix
                    if (planRequestParameters.isDestinationToFromVC) {
                        [planRequestParameters.planDestination newPlanAvailable:nil
                                                                     fromObject:self
                                                                         status:PLAN_NOT_AVAILABLE_THAT_TIME
                                                               RequestParameter:planRequestParameters];
                        logEvent(FLURRY_ROUTE_NO_MATCHING_ITINERARIES, nil, nil, nil, nil, nil, nil, nil, nil);
                    } // else if routeOptions destination, do nothing
                }
            }
        }
    }
    @catch (NSException *exception) {
        if (planRequestParameters && planRequestParameters.isDestinationToFromVC) {
            [planRequestParameters.planDestination newPlanAvailable:nil
                                                         fromObject:self
                                                             status:PLAN_GENERIC_EXCEPTION
                                                   RequestParameter:planRequestParameters];
            logException(@"PlanStore->objectLoader", @"Original request from ToFromVC", exception);
        } else {
            logException(@"PlanStore->objectLoader", @"Follow-up request to RouteOptionsVC", exception);
        }
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error
{
    [nc_AppDelegate sharedInstance].receivedError = YES;
    if([nc_AppDelegate sharedInstance].isTestPlan){
        [nc_AppDelegate sharedInstance].testPlan = nil;
    }
    NIMLOG_ERR1(@"Error received from RKObjectManager: %@", error);
    PlanRequestStatus status;
    NIMLOG_EVENT1(@"Plan RKError objectLoader params: %@", [objectLoader params]);
    if ([[error localizedDescription] rangeOfString:@"client is unable to contact the resource"].location != NSNotFound) {
        logEvent(FLURRY_ROUTE_NO_NETWORK,
                 FLURRY_RK_RESPONSE_ERROR, [error localizedDescription],
                 nil, nil, nil, nil, nil, nil);
        status = PLAN_NO_NETWORK;
    } else {
        logEvent(FLURRY_ROUTE_OTHER_ERROR,
                 FLURRY_RK_RESPONSE_ERROR, [error localizedDescription],
                 nil, nil, nil, nil, nil, nil);

        status = PLAN_GENERIC_EXCEPTION;
    }
    NSString* resourcePath = [objectLoader resourcePath];
    
    PlanRequestParameters* parameters = [parametersByPlanURLResource objectForKey:resourcePath];
    if (!parameters) {
        NIMLOG_ERR1(@"RKObjectManager failure with no retrievable parameters.  Error: %@", error);
    } else {
        if (parameters.isDestinationToFromVC) {
            NIMLOG_ERR1(@"Error received from RKObjectManager on first call by ToFromViewController: %@", error);
            [parameters.planDestination newPlanAvailable:nil
                                              fromObject:self
                                                  status:status
                                        RequestParameter:parameters];
        }
        else { // if target is RouteOptions, do not call routeOptions and do not alert user.  This was a backup request only
            NIMLOG_ERR1(@"Error received from RKObjectManager on subsequent call RouteOptionsViewController: %@", error);
        }
    }
}


// Checks if more itineraries are needed for this plan, and if so requests them from the server
-(MoreItineraryStatus)requestMoreItinerariesIfNeeded:(Plan *)plan parameters:(PlanRequestParameters *)requestParams0
{
    if (requestParams0.serverCallsSoFar >= PLAN_MAX_SERVER_CALLS_PER_REQUEST) {
        return NO_MORE_ITINERARIES_REQUESTED; // Return if we have already made the max number of calls
    }
    if ([plan haveOnlyUnscheduledItineraries]) {
        return NO_MORE_ITINERARIES_REQUESTED; // DE186 fix, do not request more itineraries if we currently are have walk-only or bike-only itinerary
    }
    
    PlanRequestParameters* params = [PlanRequestParameters copyOfPlanRequestParameters:requestParams0];
    
    params.routeExcludeSettings = [RouteExcludeSettings latestUserSettings];  // use the latest settings in case something has changed
    params.routeExcludeSettingsUsedForOTPCall = [RouteExcludeSettings excludeSettingsWithSettingArray:[plan excludeSettingsArray]];
    
    // Find out how far the matching OTP itineraries go with extremely large limits
    NSDate* otpRequestDate = [plan nextOtpServerDateToCallFor:params.originalTripDate
                                               departOrArrive:params.departOrArrive
                                         routeExcludeSettings:params.routeExcludeSettingsUsedForOTPCall
                             planBufferSecondsBeforeItinerary:PLAN_BUFFER_SECONDS_BEFORE_ITINERARY
                                  planMaxTimeForResultsToShow:(100*60*60)];
    
    NSTimeInterval bufferSeconds;
    if ([otpRequestDate isEqualToDate:requestParams0.originalTripDate]) {
        bufferSeconds = 0;  // do not add any buffer if we are starting from the original Request date
    } else {
        bufferSeconds = PLAN_NEXT_REQUEST_TIME_INTERVAL_SECONDS;
    }
    
    BOOL areRouteExcludeSettingsDifferent = true;
    if ([params.routeExcludeSettingsUsedForOTPCall isEquivalentTo:requestParams0.routeExcludeSettingsUsedForOTPCall]) {
        areRouteExcludeSettingsDifferent = false;
    } 
    if (areRouteExcludeSettingsDifferent) { // if the settings are different, cancel out the incrementing of serverCallsSoFar
        requestParams0.serverCallsSoFar = requestParams0.serverCallsSoFar - 1;
    }
    MoreItineraryStatus moreItinStatus = NO_MORE_ITINERARIES_REQUESTED;
    if (params.departOrArrive == DEPART &&
        [otpRequestDate timeIntervalSinceDate:requestParams0.originalTripDate] < PLAN_MAX_TIME_FOR_RESULTS_TO_SHOW) {
        params.thisRequestTripDate = [otpRequestDate dateByAddingTimeInterval:bufferSeconds];
        [self requestPlanFromOtpWithParameters:params routeExcludeSettingArray:[plan excludeSettingsArray]];
        moreItinStatus = (areRouteExcludeSettingsDifferent ? MORE_ITINERARIES_REQUESTED_DIFFERENT_EXCLUDES : MORE_ITINERARIES_REQUESTED_SAME_EXCLUDES);
    } else if (params.departOrArrive == ARRIVE &&
               [otpRequestDate timeIntervalSinceDate:requestParams0.originalTripDate] > -PLAN_MAX_TIME_FOR_RESULTS_TO_SHOW){
        params.thisRequestTripDate = [otpRequestDate dateByAddingTimeInterval:(-bufferSeconds)];
        [self requestPlanFromOtpWithParameters:params routeExcludeSettingArray:[plan excludeSettingsArray]];
        moreItinStatus = (areRouteExcludeSettingsDifferent ? MORE_ITINERARIES_REQUESTED_DIFFERENT_EXCLUDES : MORE_ITINERARIES_REQUESTED_SAME_EXCLUDES);
    }
    return moreItinStatus;
}


// Called when there is an update of gtfsData
// Checks whether any plans with outstanding gtfsParsingRequests now have all the data they need.
// If so, updates those plans (using prepareSortedItinaries) and calls their planDestination
- (void)updatePlansWithNewGtfsDataIfNeeded
{
    NSSet* plansToCheck = [NSSet setWithSet:plansWaitingForGtfsData];
    for (Plan* requestingPlan in plansToCheck) {
        PlanRequestParameters* params = [latestParametersForPlanIdDictionary objectForKey:requestingPlan.planId];
        if (params) {
            // See if all of the outstanding data requests are now available
            BOOL isAllGtfsDataAvailable = true;
            for (GtfsParsingStatus* otherStatus in [requestingPlan gtfsParsingRequests]) {
                if (![otherStatus isGtfsDataAvailable]) { // if any of the requested data unavailable
                    isAllGtfsDataAvailable = false;
                    break;
                }
            }
            if (isAllGtfsDataAvailable) {
                // If all needed gtfs data available, update prepareSortedItineraries and callback the planDestination
                [requestingPlan setGtfsParsingRequests:[NSSet set]];  // clear outstanding requests
                [plansWaitingForGtfsData removeObject:requestingPlan]; // remove from list
                [requestingPlan prepareSortedItinerariesWithMatchesForDate:params.originalTripDate
                                                            departOrArrive:params.departOrArrive
                                                      routeExcludeSettings:params.routeExcludeSettings
                                                   generateGtfsItineraries:NO
                                                     removeNonOptimalItins:YES];
                if (requestingPlan.sortedItineraries.count > 0) {
                    [params.planDestination newPlanAvailable:requestingPlan
                                                  fromObject:self
                                                      status:PLAN_STATUS_OK
                                            RequestParameter:params];
                }
            }
        }
    }
}

// Fetches array of plans going to the same to & from Location from the cache
// Normally will return just one plan, but could return more if the plans have not been consolidated
// Plans are sorted starting with the latest (most current) plan first
- (NSArray *)fetchPlansWithToLocation:(Location *)toLocation fromLocation:(Location *)fromLocation
{
    if (!fromLocation || !toLocation || fromLocation==toLocation) {
        return nil;
    }
    Location* fromAddrLoc;   // a fromLocation which is an specific location (not current location)
    Location* fromCurrentLoc;  // fromLocation which is equal to currentLocation
    Location* toAddrLoc;
    Location* toCurrentLoc;
    
    if ([fromLocation isCurrentLocation]) {
        fromCurrentLoc = fromLocation;
        if ([fromLocation isReverseGeoValid]) {
            fromAddrLoc = [fromLocation reverseGeoLocation]; // if there is a reverseGeo, use that too
        }
    }
    else {  // fromLocation is not current location
        fromAddrLoc = fromLocation;
    }
    
    if ([toLocation isCurrentLocation]) {
        toCurrentLoc = toLocation;
        if ([toLocation isReverseGeoValid]) {
            fromAddrLoc = [toLocation reverseGeoLocation]; // if there is a reverseGeo, use that too
        }
    }
    else {  // toLocation is not current location
        toAddrLoc = toLocation;
    }
    
    @try {
        // Fetch and compare for specific addresses
        NSArray* result1 = [NSArray array];
        if (fromAddrLoc && toAddrLoc) {
            NSDictionary* fetchParameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                             [fromAddrLoc formattedAddress],@"FROM_FORMATTED_ADDRESS",
                                             [toAddrLoc formattedAddress], @"TO_FORMATTED_ADDRESS", nil];
            NSFetchRequest* request = [managedObjectModel
                                       fetchRequestFromTemplateWithName:@"PlansByToAndFromLocations"
                                       substitutionVariables:fetchParameters];
            NSSortDescriptor *sd1 = [NSSortDescriptor sortDescriptorWithKey:PLAN_LAST_UPDATED_FROM_SERVER_KEY
                                                                  ascending:NO]; // Later plan first
            [request setSortDescriptors:[NSArray arrayWithObject:sd1]];
            NSError *error;
            result1 = [managedObjectContext executeFetchRequest:request error:&error];
            if (!result1) {
                [NSException raise:@"Matching plan fetch failed" format:@"Reason: %@", [error localizedDescription]];
            }
        }
        
        // Also fetch and compare results for Current Location if needed
        NSMutableArray* result2 = [NSMutableArray arrayWithCapacity:1];
        if (fromCurrentLoc || toCurrentLoc) {
            Location* fromQueryLoc = (fromCurrentLoc ? fromCurrentLoc : fromAddrLoc);
            Location* toQueryLoc = (toCurrentLoc ? toCurrentLoc : toAddrLoc);
            if (fromQueryLoc && toQueryLoc) {
                NSDictionary* fetchParameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                                 [fromQueryLoc formattedAddress],@"FROM_FORMATTED_ADDRESS",
                                                 [toQueryLoc formattedAddress], @"TO_FORMATTED_ADDRESS", nil];
                NSFetchRequest* request = [managedObjectModel
                                           fetchRequestFromTemplateWithName:@"PlansByToAndFromLocations"
                                           substitutionVariables:fetchParameters];
                NSSortDescriptor *sd1 = [NSSortDescriptor sortDescriptorWithKey:PLAN_LAST_UPDATED_FROM_SERVER_KEY
                                                                      ascending:NO]; // Later plan first
                [request setSortDescriptors:[NSArray arrayWithObject:sd1]];
                NSError *error;
                NSArray* result2temp = [managedObjectContext executeFetchRequest:request error:&error];
                if (!result2temp) {
                    [NSException raise:@"Matching plan fetch failed" format:@"Reason: %@", [error localizedDescription]];
                }
                // Now check if the results are within the time threshold
                for (Plan* CLPlan in result2temp) {
                    if ([[CLPlan lastUpdatedFromServer] timeIntervalSinceNow] <
                        -(REVERSE_GEO_PLAN_FETCH_TIME_THRESHOLD)) {
                        // If the plan is older than the thresold, then delete it from Core data
                        [[self managedObjectContext] deleteObject:CLPlan];
                    }
                    else { // if within the threshold, add it to the result
                        [result2 addObject:CLPlan];
                    }
                }
            }
            
        }
        return [result1 arrayByAddingObjectsFromArray:result2];  // Return the array of matches (could be empty)
    }
    @catch (NSException *exception) {
        logException(@"PlanStore -> fetchPlansWithToLocation",
                     [NSString stringWithFormat:@"fromAddrLoc = '%@', fromCurrentLoc = '%@', toAddrLoc = '%@', toCurrentLoc = '%@'",
                      (fromAddrLoc ? [fromAddrLoc formattedAddress] : @"null"),
                      (fromCurrentLoc ? [fromCurrentLoc formattedAddress] : @"null"),
                      (toAddrLoc ? [toAddrLoc formattedAddress] : @"null"),
                      (toCurrentLoc ? [toCurrentLoc formattedAddress] : @"null")],
                     exception);
        return [NSArray array]; // Return empty array
    }
}


// Takes a new plan and consolidates it with other plans going to the same to & from locations.
// Assumes that plan0 is a newly retrieved Plan (and thus is newer than any of its matching plans)
// Returns the consolidated plan
- (Plan *)consolidateWithMatchingPlans:(Plan *)plan0
{
    NSArray *matches = [self fetchPlansWithToLocation:[plan0 toLocation]
                                         fromLocation:[plan0 fromLocation]];
    if (!matches || [matches count]==0) {
        return plan0;
    }
    else {
        Plan* consolidatedPlan = nil;
        for (int i=0; i<[matches count]; i++) {
            Plan* plan1 = [matches objectAtIndex:i];
            if (plan0 != plan1) {  // if this is actually a different object
                if (!consolidatedPlan) {
                    // Since matches is sorted most recent to oldest, the first plan in matches that is
                    // not identical to plan0 is the plan we want to consolidate into
                    consolidatedPlan = plan1;
                    
                    // consolidate from plan0 into consolidatedPlan, delete plan0
                    [consolidatedPlan consolidateIntoSelfPlan:plan0];
                }
                else {
                    // if there are yet other plan1's beyond consolidatedPlan, then consolidate them into consolidatePlan
                    [consolidatedPlan consolidateIntoSelfPlan:plan1];
                }
            }
        }
        if (consolidatedPlan) {
            return consolidatedPlan;
        } else {
            return plan0;  // return plan0 if no different matches were found
        }
    }
}

// US-161 Implementation
// Implementation Of Clearing PlanCache
// Get  All PlanRequestChunk and delete them when max walk distance change.
// Get All  Plan and delete plan excepting current plan. 

- (void)clearCache{
    @try {
        Plan *plan = [[[[nc_AppDelegate sharedInstance] toFromViewController] routeOptionsVC] plan];
        NSString *strPlanID = [plan planId];
        
        NSError *error;
        NSManagedObjectContext * context = [self managedObjectContext];
        NSFetchRequest * fetchPlanRequestChunk = [[NSFetchRequest alloc] init];
       NSFetchRequest * fetchPlan = [[NSFetchRequest alloc] init];
        
        [fetchPlanRequestChunk setEntity:[NSEntityDescription entityForName:@"PlanRequestChunk" inManagedObjectContext:context]];
        [fetchPlan setEntity:[NSEntityDescription entityForName:@"Plan" inManagedObjectContext:context]];
        
        NSArray * arrayPlanRequestChunk = [context executeFetchRequest:fetchPlanRequestChunk error:nil];
        NSArray * arrayPlan = [context executeFetchRequest:fetchPlan error:nil];
       
        for (id planRequestChunks in arrayPlanRequestChunk){
            [context deleteObject:planRequestChunks];
        }
        
        for (id plans in arrayPlan){
            if(![strPlanID isEqualToString:[plans planId]]){
                [context deleteObject:plans];
            }
        }
        [context save:&error];
        if(error){
            logError(@"PlanStore --> clearCache", [NSString stringWithFormat:@"Error While Clearing Cache:%@",error]);
        }
    }
    @catch (NSException *exception) {
        logException(@"PlanStore -> clearCache", @"", exception);
    }
}
@end