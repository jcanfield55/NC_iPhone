//
//  Itinerary.h
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/24/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <RestKit/Restkit.h>
#import "PlanPlace.h"
#import "TransitCalendar.h"
#import "enums.h"

@class Leg, Plan, PlanRequestChunk;

// Utility function for sorting sets of itineraries
NSArray *sortedByStartTimeOnly(NSSet* itinerarySet);

@interface Itinerary : NSManagedObject

typedef enum {
    ITINERARIES_DIFFERENT,
    ITINERARIES_IDENTICAL,  // identical per the == operator (i.e. same object, same memory)
    ITINERARIES_SAME,       // different objects but effectively same content
    ITIN0_OBSOLETE,
    ITIN_SELF_OBSOLETE
} ItineraryCompareResult;

//typedef enum {
//    REALTIME_ITINERARY,
//    SCHEDULED_ITINERARY,
//} ItineraryType;

// See this URL for documentation on the elements: http://www.opentripplanner.org/apidoc/data_ns0.html#itinerary
// This URL has example data http://groups.google.com/group/opentripplanner-dev/msg/4535900a5d18e61f?
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSDate   * endTime;  // raw end time from OTP
@property (nonatomic, retain) NSDate *endTimeOnly; // Time only portion of endTime (computed with timeOnlyfromDate function).  Adds/subtracts 1 day if part of overnight request
@property (nonatomic, retain) NSDate * itineraryCreationDate; // Time this itinerary was loaded or last updated
@property (nonatomic, retain) NSDate * startTime;  // raw start time from OTP
@property (nonatomic, retain) NSDate * startTimeOnly;  // Time only portion of StartTime (computed with timeOnlyfromDate function).  Adds / subtracts 1 day if part of overnight request
@property (nonatomic, retain) NSString * itinId;
@property (nonatomic, retain) NSSet* planRequestChunks; // set of PlanRequestChunks this itinerary is part of
@property (nonatomic, retain) NSSet* requestChunksCreatedByThisPattern; // if this is a unique itinerary, this points to the request chunks of gtfsItineraries created off this itinerary's pattern.  Otherwise null.
@property (nonatomic, retain) NSString *itinArrivalFlag;

@property (nonatomic, retain) NSSet *legs;
@property (nonatomic, retain) Plan *plan;   // Plan this itinerary belongs to
@property (nonatomic, retain) Plan *uniqueItineraryForPlan;  // If this is a unique itinerary, points to plan (otherwise nil)
@property (nonatomic, strong) NSArray *sortedLegs; // Array of legs sorted by startTime (not stored in Core Data)
@property (nonatomic, retain) NSNumber * elevationGained;
@property (nonatomic, retain) NSNumber * elevationLost;
@property (nonatomic, retain) NSNumber * fareInCents;
@property (nonatomic, retain) NSNumber * tooSloped;
@property (nonatomic, retain) NSNumber * transfers;
@property (nonatomic, retain) NSNumber * transitTime;
@property (nonatomic, retain) NSNumber * waitingTime;
@property (nonatomic, retain) NSNumber * walkDistance;
@property (nonatomic, retain) NSNumber * walkTime;
@property (nonatomic) BOOL isRealTimeItinerary;
@property (nonatomic) BOOL hideItinerary;
@property (nonatomic, strong) NSString *tripIdhexString;
@property (nonatomic, strong) NSDate *maximumPredictionDate;
@property (nonatomic, retain) NSDate *startTimeOfLeg;
@property (nonatomic) int status;

- (void)sortLegs;
- (NSArray *)sortedLegs;
- (PlanPlace *)from;
- (PlanPlace *)to;
- (NSString *)ncDescription;

- (BOOL)isOTPItinerary;  // Returns true if itinerary is from OTP
- (BOOL)isUberItinerary; // Returns true if itinerary is from Uber API
- (BOOL)isUniqueItinerary; // Returns trues if itinerary is a unique itinerary

// Returns true if each leg's starttime is current versus the GTFS file date for that leg's agency
// Otherwise returns false
- (BOOL)isCurrentVsGtfsFilesIn:(TransitCalendar *)transitCalendar;

// Compares the itineraries to see if they are equivalent in substance
- (ItineraryCompareResult)compareItineraries:(Itinerary *)itin0;

// Returns the start-time of the first leg if there is one, otherwise returns startTime property
- (NSDate *)startTimeOfFirstLeg;

// Returns the end-time of the last leg if there is one, otherwise returns endTime property
- (NSDate *)endTimeOfLastLeg;

// Initializes startTimeOnly and endTimeOnly variables based on reqDate
- (void)initializeTimeOnlyVariablesWithRequestDate:(NSDate *)reqDate;

// Returns a nicely formatted address string for the starting point, if available
- (NSString *)fromAddressString;

// Returns a nicely formatted address string for the end point, if available
- (NSString *)toAddressString;

// Returns a string which can be used in RouteOptionsView to give a summary of the itinerary
// Each line of the string will be truncated to fit within width using font
// If width is 0 or font == nil, returns untruncated strings
- (NSString *)itinerarySummaryStringForWidth:(CGFloat)width Font:(UIFont *)font;

// Returns a sorted array of the title strings to show itinerary details as needed
// for display a route details view.  Might have more elements than legs in the itinerary.
// Adds a start and/or end point if needed.  Modifies the first and last walking
// leg if needed.
- (NSArray *)legDescriptionTitleSortedArray;

// Same as above but containing the corresponding subtitles
- (NSArray *)legDescriptionSubtitleSortedArray;

// This array has the same # of elements as the above title and subtitle arrays.
// For the same element as the title or subtitle array, this array maps back to the corresponding leg
// if there is one.  If there was an added start or endpoint, the first or last element will return
// NSNull
- (NSArray *)legDescriptionToLegMapArray;

// Returns the number of itinerary rows there are
// This equals the number of rows in the legDescriptionTitleSortedArray.
- (int)itineraryRowCount;

// Returns true if itin is an itinerary that goes past 3:00am and is >=3 hours in length
// Workaround for OTP tendency to generate itineraries that go overnight past the end of service for
// Caltrain and other agencies.  Robust solution will be to fix OTP
- (BOOL)isOvernightItinerary;

// Compare Two Itineraries whether they have the same modes, agencies, and start & endpoints
// Does not compare times (this test is primarily for determining unique itineraries).
// This match itinerary like leg by leg if all match the return yes otherwise return no.
- (BOOL)isEquivalentModesAndStopsAs:(Itinerary *)itinerary;

// Compare Two Itineraries whether they have the same routes and start & endpoints
// Compares times just for scheduled legs (not for unscheduled legs)
// This match itinerary like leg by leg if all match the return yes otherwise return no.
- (BOOL)isEquivalentRoutesStopsAndScheduledTimingAs:(Itinerary *)itinerary;

- (BOOL) isEquivalentModesAndStopsAndRouteAs:(Itinerary *)itinerary;

// Set Itinerary RealTime from Legs RealTime
// If itinerary has one scheduled leg then itinerary realtime is same as scheduled leg realtime.
// If itinerary have more than one scheduled leg then check if one leg is early and other is delayed then realtime for itinerary is time slipage else if all flag have same realtime then itinerary realtime is same as scheduled legs realtime else leg is not delayed or early then itinerary real time is ontime.
- (void) setArrivalFlagFromLegsRealTime;

// return the conflict leg from sorted legs of itinerary
- (Leg *) conflictLegFromItinerary;

// return true if itinerary have only unscheduled leg.
- (BOOL) haveOnlyUnScheduledLeg;

// Returns true if the itinerary is valid given the requestTime, buffer time intervals before & after
// the request, and the depOrArrive.
// Note, for arrive requests, intervalBeforeRequest actually is the buffer time after the request date (slack for being late)
- (BOOL) isWithinRequestTime:(NSDate *)requestTime
       intervalBeforeRequest:(NSTimeInterval)intervalBeforeRequest
        intervalAfterRequest:(NSTimeInterval)intervalAfterRequest
              departOrArrive:(DepartOrArrive)depOrArrive;

// Returns true if all the itinerary's legs' serviceDays match the serviceDays for requestDate
- (BOOL)doAllServiceDaysMatchDate:(NSDate *)requestDate;

- (BOOL)containsUnscheduledLeg;
- (BOOL)containsBikeLeg;

- (void) initializeLegStartTime;
@end

@interface Itinerary (CoreDataGeneratedAccessors)

- (void)addLegsObject:(Leg *)value;
- (void)removeLegsObject:(Leg *)value;
- (void)addLegs:(NSSet *)values;
- (void)removeLegs:(NSSet *)values;
@end
