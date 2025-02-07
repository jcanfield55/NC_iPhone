//
//  GtfsParser.h
//  Nimbler Caltrain
//
//  Created by macmini on 07/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <RestKit/Restkit.h>
#import <RestKit/CoreData.h>
#import <Restkit/RKJSONParserJSONKit.h>
#import "Plan.h"
#import "Leg.h"
#import "PlanRequestParameters.h"
#import "GtfsCalendar.h"
#import "GtfsRoutes.h"
#import "GtfsTrips.h"
#import "GtfsStop.h"

@interface GtfsParser : NSObject<RKRequestDelegate>{
    NSManagedObjectContext *managedObjectContext;
}
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) RKClient *rkTpClient;
@property (strong, nonatomic) NSString *strAgenciesURL;
@property (strong, nonatomic) NSString *strCalendarDatesURL;
@property (strong, nonatomic) NSString *strCalendarURL;
@property (strong, nonatomic) NSString *strRoutesURL;
@property (strong, nonatomic) NSString *strStopsURL;
@property (strong, nonatomic) NSString *strTripsURL;
@property (strong, nonatomic) NSString *strStopTimesURL;
@property (nonatomic) BOOL loadedInitialData;  // True if Agency data request was made and data is now loaded all the way through routes
@property (nonatomic,strong) NSDictionary *tripsDictionary;
@property (nonatomic,strong) NSDictionary *stopsDictionary;
@property (nonatomic, strong) NSMutableDictionary *dictServerCallSoFar; // Contain count of how many times server is call so far for each gtfs data like GtfsAgency,GtfsCalendar,GtfsCalendarDates etc.if it is more than 3 then we will not request the server.

@property (nonatomic) BOOL isParticularTripRequest;
@property (nonatomic, strong) Leg *temporaryLeg;
@property (nonatomic, strong) Itinerary *temporaryItinerary;
@property (nonatomic, strong) NSArray *legsArray;
@property (nonatomic, strong) NSDictionary *legsDictionary;
@property (nonatomic, strong) NSArray *itinerariesArray;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc rkTpClient:(RKClient *)rkClient;

// Parse the Gtfs Agency Data and store to database.
- (void) parseAndStoreGtfsAgencyData:(NSDictionary *)dictFileData;

// Parse the Gtfs CalendarDates Data and store to database.
- (void) parseAndStoreGtfsCalendarDatesData:(NSDictionary *)dictFileData;

// Parse the Gtfs Calendar Data and store to database.
- (void) parseAndStoreGtfsCalendarData:(NSDictionary *)dictFileData;

// Parse the Gtfs Routes Data and store to database.
- (void) parseAndStoreGtfsRoutesData:(NSDictionary *)dictFileData;

// Parse the Gtfs Stops Data and store to database.
- (void) parseAndStoreGtfsStopsData:(NSDictionary *)dictFileData;

// Parse the Gtfs Trips Data and store to database.
- (void) parseAndStoreGtfsTripsData:(NSDictionary *)dictFileData RequestUrl:(NSString *)strRequestUrl;

-(void)requestAgencyDataFromServer;
-(void)requestCalendarDatesDataFromServer;
-(void)requestCalendarDatafromServer;
-(void)requestRoutesDatafromServer;
-(void)requestStopsDataFromServer;
-(void)requestTripsDatafromServer:(NSString *)strRequestString;
- (void)requestStopTimesDataFromServer:(NSMutableString *)strRequestString;

// Generate The StopTimes Request Comma Separated string like agencyID_tripID
- (void)generateStopTimesRequestStringUsingTripIds:(NSArray *)tripIds agencyIds:(NSArray *)agencyIds;

// Makes a request to the server for any GTFS Trips and StopTimes data not already in the database
// If there is data needed, planStore will eventually be called back when the data is loaded for plan refresh
- (void)generateGtfsTripsRequestStringUsingPlan:(Plan *)plan;

// This method get the serviceId based on tripId.
// Then get the calendar data for particular serviceID.
// the check for the request date comes after service start date and comes befor enddate.
// then check service is enabled on request day if yes then return yes otherwise return no.
- (BOOL) isServiceEnableForStopTimes:(GtfsStopTimes *)stopTimes RequestDate:(NSDate *)requestDate;

// first get stoptimes from StopTimes Table based on stopId
// Then make a pair of StopTimes if both stoptimes have same tripId then check for the stopSequence and the departure time is greater than request trip time and also check if service is enabled for that stopTimes if yes the add both stopTimes as To/From StopTimes pair.
// timeInterval is the amount of time to pull the stoptimes for (in seconds)
- (NSMutableArray *)getStopTimes:(NSString *)strToStopID
                   strFromStopID:(NSString *)strFromStopID
                       startDate:(NSDate *)startDate
                    timeInterval:(NSTimeInterval)timeInterval
                          TripId:(NSString *)tripId;

- (NSArray *) findNearestStopTimeFromStopTimeArray:(NSArray *)arrStopTimes Itinerary:(Itinerary *)itinerary;

// TODO:- Need to add flag that determine flag is generated from realtime data or scheduled data.
// generate new leg from prediction data.
- (Leg *) generateLegFromPrediction:(NSDictionary *)prediction newItinerary:(Itinerary *)newItinerary Leg:(Leg *)leg Context:(NSManagedObjectContext *)context ISExtraPrediction:(BOOL)isExtraPrediction;

// Adjust itinerary first and last leg start/end time if it is unscheduled.
- (void) adjustItineraryAndLegsTimes:(Itinerary *)itinerary Context:(NSManagedObjectContext *)context;

// Generate new leg with all parameters from old leg
- (void) generateNewLegFromOldLeg:(Leg *)leg Context:(NSManagedObjectContext *)context Itinerary:(Itinerary *)itinerary;

// Generate itineraries from realtime data.
- (void) generateItinerariesFromPrediction:(Plan *)plan Itinerary:(Itinerary *)itinerary Prediction:(NSMutableDictionary *)dictPredictions TripDate:(NSDate *)tripDate DepartOrArrive:(DepartOrArrive)departOrArrive Context:(NSManagedObjectContext *)context;

- (void) generateItinerariesFromRealTime:(Plan *)plan TripDate:(NSDate *)tripDate DepartOrArrive:(DepartOrArrive)departOrArrive Context:(NSManagedObjectContext *)context;

// Generates Gtfs itineraries in plan based on the pattern of itinerary
// tripDate is the original tripDate.  fromTimeOnly and toTimeOnly is the range of start-times that should be generated
// Generated itineraries will be associated with Plan and will be optimal for that pattern
// Returns request chunk with new itineraries, or nil if no new itineraries created
- (PlanRequestChunk *)generateItineraryFromItineraryPattern:(Itinerary *)itinerary
                                          tripDate:(NSDate *)tripDate
                                      fromTimeOnly:(NSDate *)fromTimeOnly
                                        toTimeOnly:(NSDate *)toTimeOnly
                                              Plan:(Plan *)plan
                                           Context:(NSManagedObjectContext *)context;

// Remove all stopTimes and Trips Data from DB when new updates are available.
- (void) removeAllTripsAndStopTimesData;

// This methods are used in requesting and storing trips data into seed DB.
- (void) requestTripsDataForCreatingSeedDB:(NSMutableString *)strRequestString;
- (void)generateTripsRequestForSeedDB:(NSArray *)routeIds agencyIds:(NSArray *)agencyIds;

// GtfsParsingStatusMethods
-(BOOL)hasGtfsDownloadRequestBeenSubmittedForAgencyName:(NSString *)agencyName
                                                routeId:(NSString *)routeId;
-(BOOL)isGtfsDataAvailableForAgencyName:(NSString *)agencyName
                                routeId:(NSString *)routeId;
-(void)setGtfsRequestSubmittedForAgencyName:(NSString *)agencyName
                                    routeId:(NSString *)routeId
                                       plan:(Plan *)plan;

// For all the plans in requestingPlans, will call the plan's "prepareSortedItineraries" method
// once all the needed data is available
-(void)setGtfsDataAvailableForAgencyName:(NSString *)agencyName
                                 routeId:(NSString *)routeId
                                 context:(NSManagedObjectContext *) context;

// return the intermediate stops between from and to stops
// - (NSArray *) returnIntermediateStopForLeg:(Leg *)leg Itinerary:(Itinerary *)itinerary;

// return the stoptimes array based on from and to stopid and leg start time.
- (NSArray *) getStopTimesBasedOnStopIdAndnearestTime:(NSArray *)stopTime FromStopId:(NSString *)fromStopId;

// Fetch trips from tripsDictionary if available otherwise fetch all trips from database and set it to tripsDictionary and then get trips from tripsDictionary.
- (GtfsTrips *) fetchTripsFromTripId:(NSString *)tripId context:(NSManagedObjectContext *)context;

// Fetch stops from stopsDictionary if available otherwise fetch all stops from database and set it to stopsDictionary and then get stops from stopsDictionary.
- (GtfsStop *) fetchStopsFromStopId:(NSString *)stopId;

- (void) requestStopTimesDataForParticularTripFromServer:(Itinerary *)itinerary;
@end

