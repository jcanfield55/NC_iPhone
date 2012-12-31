//
//  Leg.m
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/24/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "Leg.h"
#import "Itinerary.h"
#import "Step.h"
#import "UtilityFunctions.h"
#import "KeyObjectStore.h"

@interface Leg() 
// Private instance methods
+(NSDictionary *)agencyDisplayNameByAgencyId;
#define AGENCY_DISPLAY_NAME_BY_AGENCYID_KEY @"agencyDisplayNameByAgencyIdKey"
#define AGENCY_DISPLAY_NAME_BY_AGENCYID_VERSION_NUMBER @"agencyDisplayNameByAgencyIdVersionNumber"

@end

@implementation Leg

@dynamic agencyId;
@dynamic bogusNonTransitLeg;
@dynamic distance;
@dynamic duration;
@dynamic endTime;
@dynamic headSign;
@dynamic interlineWithPreviousLeg;
@dynamic legGeometryLength;
@dynamic legGeometryPoints;
@dynamic mode;
@dynamic route;
@dynamic routeLongName;
@dynamic routeShortName;
@dynamic startTime;
@dynamic tripShortName;
@dynamic from;
@dynamic itinerary;
@dynamic steps;
@dynamic to;
@dynamic legId;
@dynamic tripId;
@dynamic agencyName;
@synthesize sortedSteps;
@synthesize polylineEncodedString;
@synthesize arrivalTime,arrivalFlag,timeDiffInMins;

static NSDictionary* __agencyDisplayNameByAgencyId;

// Create the sorted array of itineraries
- (void)sortSteps
{
    //Edited by Sitanshu Joshi
    NSSortDescriptor *sortD = [NSSortDescriptor sortDescriptorWithKey:@"absoluteDirection" ascending:YES];
    [self setSortedSteps:[[self steps] sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortD]]];
}

- (NSArray *)sortedSteps
{
    if (!sortedSteps) {
        [self sortSteps];  // create the itinerary array
    }
    return sortedSteps;
}

+ (NSDictionary *)agencyDisplayNameByAgencyId
{
    if (!__agencyDisplayNameByAgencyId) { // if not already set, check in database
        KeyObjectStore* store = [KeyObjectStore keyObjectStore];
        __agencyDisplayNameByAgencyId = [store objectForKey:AGENCY_DISPLAY_NAME_BY_AGENCYID_KEY];
        if (!__agencyDisplayNameByAgencyId) {  // if not stored in the database, create it
            __agencyDisplayNameByAgencyId = [NSDictionary dictionaryWithKeysAndObjects:
                                             AGENCY_DISPLAY_NAME_BY_AGENCYID_VERSION_NUMBER, CALTRAIN_PRELOAD_VERSION_NUMBER,
                                             @"AC Transit", @"AC Transit",
                                             @"BART", @"BART",
                                             @"AirBART", @"AirBART",
                                             @"caltrain-ca-us", @"Caltrain",
                                             @"8", @"Blue & Gold Fleet",
                                             @"10", @"Harbor Bay Ferry",
                                             @"11", @"Baylink",
                                             @"12", @"Golden Gate Ferry",
                                             @"MIDDAY", @"Menlo Park Midday Shuttle",
                                             @"SFMTA", @"Muni",
                                             @"VTA", @"VTA",
                                             nil];
            [store setObject:__agencyDisplayNameByAgencyId forKey:AGENCY_DISPLAY_NAME_BY_AGENCYID_KEY];
        }
    }
    return __agencyDisplayNameByAgencyId;
}

// Getter to create (if needed) and return the polylineEncodedString object corresponding to the legGeometryPoints
- (PolylineEncodedString *)polylineEncodedString
{
    if (!polylineEncodedString) {
        polylineEncodedString = [[PolylineEncodedString alloc] initWithEncodedString:[self legGeometryPoints]];
    }
    return polylineEncodedString;
}

// Returns a single-line summary of the leg useful for RouteOptionsView details
// If includeTime == true, then include a time at the beginning of the summary text
- (NSString *)summaryTextWithTime:(BOOL)includeTime
{
    @try {
    NSMutableString* summary = [NSMutableString stringWithString:@""];
    if (includeTime) {
        //Part Of DE-229 Implementation
        if([self.arrivalFlag intValue] == DELAYED) {
            NSDate* realTimeArrivalTime = [[self startTime]
                                           dateByAddingTimeInterval:[self.timeDiffInMins floatValue]*60.0];
            if(realTimeArrivalTime){
              [summary appendFormat:@"%@ ", superShortTimeStringForDate(realTimeArrivalTime)];  
            }
            else{
                [summary appendFormat:@"%@ ", superShortTimeStringForDate([self startTime])];
            }
        }
        else if([self.arrivalFlag intValue] == EARLY){
            NSDate* realTimeArrivalTime = [[self startTime]
                                           dateByAddingTimeInterval:[self.timeDiffInMins floatValue]*(-60.0)];
            if(realTimeArrivalTime){
                [summary appendFormat:@"%@ ", superShortTimeStringForDate(realTimeArrivalTime)];
            }
            else{
                [summary appendFormat:@"%@ ", superShortTimeStringForDate([self startTime])];
            }
        }
        else{
            [summary appendFormat:@"%@ ", superShortTimeStringForDate([self startTime])];
        }
        
    }
    NSString* shortAgencyName = [[Leg agencyDisplayNameByAgencyId] objectForKey:[self agencyId]];
    if (!shortAgencyName) {
        shortAgencyName = [self mode];  // Use generic mode instead if name not available
    }
    [summary appendFormat:@"%@", shortAgencyName];
    if ([[self mode] isEqualToString:@"BUS"]) {
        [summary appendString:@" Bus"];
    }
    else if ([[self mode] isEqualToString:@"TRAM"]) {
        [summary appendString:@" Tram"];
    }
    if (![[self agencyId] isEqualToString:@"BART"] && ![[self agencyId] isEqualToString:@"caltrain-ca-us"]) { // don't add BART route name because too long
        [summary appendFormat:@" %@", [self route]];
    }
    
    // US-184 Implementation
    if ([[self agencyId] isEqualToString:@"caltrain-ca-us"]) {
        NSRange range;
        NSString *strTrainNumber;
        NSString *strHeadSign = [self headSign];
        NSArray *headSignComponent = [strHeadSign componentsSeparatedByString:CALTRAIN_TRAIN];
        if([headSignComponent count] > 1){
            strTrainNumber = [headSignComponent objectAtIndex:1];
            if(!strTrainNumber){
                [summary appendFormat:@" %@", [self route]];
            }
            else{
                if([strTrainNumber rangeOfString:@")" options:NSCaseInsensitiveSearch].location != NSNotFound){
                    range = [strTrainNumber rangeOfString:@")"];
                    strTrainNumber = [strTrainNumber substringToIndex:range.location];
                    NSString * strTemp = [strTrainNumber stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    NSString *strFullTrainNumber = [NSString stringWithFormat:@"#%@",strTemp];
                    [summary appendFormat:@" %@", strFullTrainNumber];
                    
                }
            }
        }
        else{
            [summary appendFormat:@" %@", [self route]];
        }
    }
    return summary;
    }
    @catch (NSException *exception) {
        logException(@"Leg->summaryTextWithTime:", @"", exception);
        return @"";
    }
}

// Returns title text for RouteDetailsView
// US121 and US124 implementation
- (NSString *)directionsTitleText:(LegPositionEnum)legPosition
{
    @try {
    NSMutableString *titleText=[NSMutableString stringWithString:@""];
    if ([[self mode] isEqualToString:@"WALK"]) {
        if (legPosition == FIRST_LEG) {    // US124 implementation
            // Part Of DE-229 & US-169 Implementation
            if([self.arrivalFlag intValue] == DELAYED) {
                NSDate* realTimeArrivalTime = [[self startTime]
                                               dateByAddingTimeInterval:[self.timeDiffInMins floatValue]*60.0];
                if(realTimeArrivalTime){
                    [titleText appendFormat:@"%@ Walk to %@",
                     superShortTimeStringForDate(realTimeArrivalTime),
                     [[self to] name]];
                }
                else{
                    [titleText appendFormat:@"%@ Walk to %@",
                     superShortTimeStringForDate([self startTime]),
                     [[self to] name]];
                }
                
                NIMLOG_EVENT1(@"Updated time: %@", titleText);
            }
            else if ([self.arrivalFlag intValue] == EARLY || [self.arrivalFlag intValue] == EARLIER) {
                NSDate* realTimeArrivalTime = [[self startTime]
                                               dateByAddingTimeInterval:[self.timeDiffInMins floatValue]*(-60.0)];
                if(realTimeArrivalTime){
                    [titleText appendFormat:@"%@ Walk to %@",
                     superShortTimeStringForDate(realTimeArrivalTime),
                     [[self to] name]];
                }
                else{
                    [titleText appendFormat:@"%@ Walk to %@",
                     superShortTimeStringForDate([self startTime]),
                     [[self to] name]];
                }
                
                NIMLOG_EVENT1(@"Updated time: %@", titleText);
            }
            else {
                [titleText appendFormat:@"%@ Walk to %@",
                 superShortTimeStringForDate([[self itinerary] startTime]),
                 [[self to] name]];
            }
            
        } else if (legPosition == LAST_LEG) {   // US124 implementation
            if([self.arrivalFlag intValue] == DELAYED) {
                NSDate* realTimeArrivalTime = [[self endTime]
                                               dateByAddingTimeInterval:[self.timeDiffInMins floatValue]*60.0];
                if(realTimeArrivalTime){
                    [titleText appendFormat:@"%@ Arrive at %@",
                     superShortTimeStringForDate(realTimeArrivalTime),
                     [[self itinerary] toAddressString]];
                }
                else{
                    [titleText appendFormat:@"%@ Arrive at %@",
                     superShortTimeStringForDate([self endTime]),
                     [[self itinerary] toAddressString]];
                }
                
                NIMLOG_EVENT1(@"Updated time: %@", titleText);
            }
            else if ([self.arrivalFlag intValue] == EARLY || [self.arrivalFlag intValue] == EARLIER) {
                NSDate* realTimeArrivalTime = [[self endTime]
                                               dateByAddingTimeInterval:[timeDiffInMins floatValue]*(-60.0)];
                if(realTimeArrivalTime){
                    [titleText appendFormat:@"%@ Arrive at %@",
                     superShortTimeStringForDate(realTimeArrivalTime),
                     [[self itinerary] toAddressString]];
                }
                else{
                    [titleText appendFormat:@"%@ Arrive at %@",
                     superShortTimeStringForDate([self endTime]),
                     [[self itinerary] toAddressString]];
                }
                NIMLOG_EVENT1(@"Updated time: %@", titleText);
            }
            else {
                [titleText appendFormat:@"%@ Arrive at %@",
                 superShortTimeStringForDate([[self itinerary] endTime]),
                 [[self itinerary] toAddressString]];
            }
        }
        else {
            [titleText appendFormat:@"Walk to %@", [[self to] name]];
        }
    }
    else {  
        BOOL areRealTimeUpdates = NO;
        
        // if not walking, check for real-time updates:
        if([self arrivalTime]) {
            areRealTimeUpdates = YES;
            NIMLOG_EVENT1(@"Real-time flag: %@, scheduled arrival: %@, real-time arrival: %@, diff: %@", 
                  [self arrivalFlag], superShortTimeStringForDate([self startTime]),
                  [self arrivalTime], [self timeDiffInMins]);

            if([self.arrivalFlag intValue] == DELAYED) {
                NSDate* realTimeArrivalTime = [[self startTime] 
                                               dateByAddingTimeInterval:[timeDiffInMins floatValue]*60.0];
                if(realTimeArrivalTime){
                   [titleText appendFormat:@"%@ ", superShortTimeStringForDate(realTimeArrivalTime)]; 
                }
                else{
                    [titleText appendFormat:@"%@ ", superShortTimeStringForDate([self startTime])];
                }
                
                NIMLOG_EVENT1(@"Updated time: %@", titleText);
            }
            else if ([self.arrivalFlag intValue] == EARLY || [self.arrivalFlag intValue] == EARLIER) {
                NSDate* realTimeArrivalTime = [[self startTime] 
                                               dateByAddingTimeInterval:[timeDiffInMins floatValue]*(-60.0)];
                if(realTimeArrivalTime){
                  [titleText appendFormat:@"%@ ", superShortTimeStringForDate(realTimeArrivalTime)];  
                }
                else{
                   [titleText appendFormat:@"%@ ", superShortTimeStringForDate([self startTime])];
                }
                NIMLOG_EVENT1(@"Updated time: %@", titleText);
            }
            else {
                [titleText appendFormat:@"%@ ", superShortTimeStringForDate([self startTime])];
            }
        }
        else {
            // add the departure time (US 121 implementation)
            [titleText appendFormat:@"%@ ", superShortTimeStringForDate([self startTime])];
        }
            
        if ([[self mode] isEqualToString:@"BUS"]) {
            [titleText appendString:@"Bus "];
        }
        else if ([[self mode] isEqualToString:@"TRAM"]) {
            [titleText appendString:@"Tram "];
        }
        
        BOOL isShortName = false;
        if ([self routeShortName] && [[self routeShortName] length]>0) {
            [titleText appendFormat:@"%@", [self routeShortName]];
            isShortName = true;
        }
        if ([self routeLongName] && [[self routeLongName] length]>0) {
            if (isShortName) {
                [titleText appendFormat:@" - "];
            }
            if ([[self agencyId] isEqualToString:@"BART"]) {
                [titleText appendString:@"BART"];  // special case for BART -- just show "BART" rather than route name
            } else {
                [titleText appendFormat:@"%@", [self routeLongName]];
            }
        }
        if ([self headSign] && [[self headSign] length]>0) {
            [titleText appendFormat:@" to %@", [self headSign]];
        }
        if (areRealTimeUpdates) {
            if ([self.arrivalFlag intValue] == ON_TIME) {
                [titleText appendString:@" (On-Time)"];
            }
            else if([self.arrivalFlag intValue] == DELAYED) {
                [titleText appendString:@" (Delayed)"];
            }
            else if ([self.arrivalFlag intValue] == EARLY || [self.arrivalFlag intValue] == EARLIER) {
                [titleText appendString:@" (Early)"];
            }
        }
    }
    return titleText;
    }
    @catch (NSException *exception) {
        logException(@"Leg->directionsTitleText:", @"", exception);
        return @"";
    }
}

- (NSString *)directionsDetailText:(LegPositionEnum)legPosition
{
    @try {
    NSString *subTitle;
    if ([[self mode] isEqualToString:@"WALK"]) {
        if (legPosition == FIRST_LEG) {
            subTitle = [NSString stringWithFormat:@"From %@ (%@)",
                        [[self itinerary] fromAddressString], 
                        distanceStringInMilesFeet([[self distance] floatValue])];
        } else {
            subTitle = [NSString stringWithFormat:@"About %@, %@", 
                        durationString([[self duration] floatValue]), 
                        distanceStringInMilesFeet([[self distance] floatValue])];
        }
    }
    else {
        // Part Of DE-229 & US-169 Implementation
        if([self.arrivalFlag intValue] == DELAYED) {
            NSDate* realTimeArrivalTime = [[self endTime]
                                           dateByAddingTimeInterval:[timeDiffInMins floatValue]*60.0];
            if(realTimeArrivalTime){
                subTitle = [NSString stringWithFormat:@"%@  Arrive %@",
                            superShortTimeStringForDate(realTimeArrivalTime),
                            [[self to] name]];
            }
            else{
                subTitle = [NSString stringWithFormat:@"%@  Arrive %@",
                            superShortTimeStringForDate([self endTime]),
                            [[self to] name]];
            }
            NIMLOG_EVENT1(@"Updated time: %@", subTitle);
        }
        else if ([self.arrivalFlag intValue] == EARLY || [self.arrivalFlag intValue] == EARLIER) {
            NSDate* realTimeArrivalTime = [[self endTime]
                                           dateByAddingTimeInterval:[timeDiffInMins floatValue]*(-60.0)];
            if(realTimeArrivalTime){
                subTitle = [NSString stringWithFormat:@"%@  Arrive %@",
                            superShortTimeStringForDate(realTimeArrivalTime),
                            [[self to] name]];
            }
            else{
                subTitle = [NSString stringWithFormat:@"%@  Arrive %@",
                            superShortTimeStringForDate([self endTime]),
                            [[self to] name]];
            }
            NIMLOG_EVENT1(@"Updated time: %@", subTitle);
        }
        else {
            subTitle = [NSString stringWithFormat:@"%@  Arrive %@",
                        superShortTimeStringForDate([self endTime]),
                        [[self to] name]];
        }
                    
    }
    return subTitle;
    }
@catch (NSException *exception) {
    logException(@"Leg->directionsDetailText", @"", exception);
    return @"";
}
}


//Implemented by Sitanshu Joshi
-(BOOL)isWalk
{
    if ([[self mode] isEqualToString:@"WALK"]) {   
        return true;   
    }
    return false;
}

-(BOOL)isHeavyTrain
{
    if ([[self mode] isEqualToString:@"RAIL"] && [[self agencyId] isEqualToString:@"caltrain-ca-us"]) {
        return true;
    } else {
        return false;
    }
}

-(BOOL)isTrain
{
    if ([[self mode] isEqualToString:@"RAIL"] || [[self mode] isEqualToString:@"TRAM"] ||
        [[self mode] isEqualToString:@"SUBWAY"]) {
        return true;
    } // else
    return false;
}
-(BOOL)isBus
{
    if ([[self mode] isEqualToString:@"BUS"]) {   
        return true;   
    } 
    return false;
}
-(BOOL)isSubway
{
    if ([[self mode] isEqualToString:@"SUBWAY"]) {   
        return true;   
    } 
    return false; 
}

// True if the main characteristics of referring Leg is equal to leg0
// Compares timeOnly components of startTime and of endTime, to name, and from name
- (BOOL)isEqualInSubstance:(Leg *)leg0
{
    if ([timeOnlyFromDate([leg0 startTime]) isEqualToDate:timeOnlyFromDate([self startTime])] &&
        [timeOnlyFromDate([leg0 endTime]) isEqualToDate:timeOnlyFromDate([self endTime])] &&
        [[[leg0 from] name] isEqualToString:[[self from] name]] &&
        [[[leg0 to] name] isEqualToString:[[self to] name]] &&
        [[leg0 route] isEqualToString:[self route]]) {
        return TRUE;
    } else {
        return FALSE;
    }
}

// Compare Two Legs
// If Leg is walk then compatr TO&From location lat/Lng and distance.
// If leg is not walk then compare routeShortname if not nill else compare routeLongName then compate TO&From Location Lat/Lng and agencyname.
// If legs are equal then return yes otherwise return no
- (BOOL) isEquivalentLegAs:(Leg *)leg{
    if([self.mode isEqualToString:@"WALK"] && [leg.mode isEqualToString:@"WALK"]){
        if([self.to.lat doubleValue] != [leg.to.lat doubleValue] || [self.to.lng doubleValue] != [leg.to.lng doubleValue] || [self.from.lat doubleValue] !=[leg.from.lat doubleValue] || [self.from.lng doubleValue] != [leg.from.lng doubleValue] || [self.distance doubleValue] != [leg.distance doubleValue]){
            return NO;
        }
        return YES;
    }
    else if([self.mode isEqualToString:leg.mode]){
        if(!self.routeShortName || !leg.routeShortName){
            if(![self.routeLongName isEqualToString:leg.routeLongName] || ![self.agencyName isEqualToString:leg.agencyName] || [self.to.lat doubleValue] != [leg.to.lat doubleValue] ||  [self.to.lng doubleValue] != [leg.to.lng doubleValue] || [self.from.lat doubleValue] != [leg.from.lat doubleValue] || [self.from.lng doubleValue] != [leg.from.lng doubleValue]){
                return NO;
            }
        }
        else if(![self.routeShortName isEqualToString:leg.routeShortName] || ![self.agencyName isEqualToString:leg.agencyName] || [self.to.lat doubleValue] != [leg.to.lat doubleValue] ||  [self.to.lng doubleValue] != [leg.to.lng doubleValue] || [self.from.lat doubleValue] != [leg.from.lat doubleValue] || [self.from.lng doubleValue] != [leg.from.lng doubleValue]){
            return NO;
        }
        return YES;
    }
    else{
        return NO;
    }
}

- (NSString *)ncDescription
{
    NSMutableString* desc = [NSMutableString stringWithFormat:
                             @"{Leg Object: mode: %@;  headSign: %@;  endTime: %@ ... ", [self mode], [self headSign], [self endTime]];
    for (Step *step in [self steps]) {
        [desc appendString:[NSString stringWithFormat:@"\n%@", [step ncDescription]]];
    }
    return desc;
}

@end
