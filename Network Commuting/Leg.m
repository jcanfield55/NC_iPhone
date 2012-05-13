//
//  Leg.m
//  Network Commuting
//
//  Created by John Canfield on 2/24/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "Leg.h"
#import "Itinerary.h"
#import "Step.h"
#import "UtilityFunctions.h"

@interface Leg()
+ (NSDateFormatter *)timeFormatter;
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
@synthesize sortedSteps;
@synthesize polylineEncodedString;

static NSDateFormatter *timeFormattr;
+ (NSDateFormatter *)timeFormatter{
    if (!timeFormattr) {
        timeFormattr = [[NSDateFormatter alloc] init];
        [timeFormattr setTimeStyle:NSDateFormatterShortStyle];
    }
    return timeFormattr;
}


+ (RKManagedObjectMapping *)objectMappingForApi:(APIType)apiType
{
    // Create empty ObjectMapping to fill and return
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[Leg class]];
    RKManagedObjectMapping* stepsMapping = [Step objectMappingForApi:apiType];
    RKManagedObjectMapping* planPlaceMapping = [PlanPlace objectMappingForApi:apiType];

    // Make the mappings
    if (apiType==OTP_PLANNER) {
        
        [mapping mapKeyPath:@"agencyId" toAttribute:@"agencyId"];
        [mapping mapKeyPath:@"bogusNonTransitLeg" toAttribute:@"bogusNonTransitLeg"];
        [mapping mapKeyPath:@"distance" toAttribute:@"distance"];
        [mapping mapKeyPath:@"duration" toAttribute:@"duration"];
        [mapping mapKeyPath:@"endTime" toAttribute:@"endTime"];
        [mapping mapKeyPath:@"headsign" toAttribute:@"headSign"];
        [mapping mapKeyPath:@"interlineWithPreviousLeg" toAttribute:@"interlineWithPreviousLeg"];
        [mapping mapKeyPath:@"legGeometry.length" toAttribute:@"legGeometryLength"];
        [mapping mapKeyPath:@"legGeometry.points" toAttribute:@"legGeometryPoints"];
        [mapping mapKeyPath:@"mode" toAttribute:@"mode"];
        [mapping mapKeyPath:@"route" toAttribute:@"route"];
        [mapping mapKeyPath:@"routeLongName" toAttribute:@"routeLongName"];
        [mapping mapKeyPath:@"routeShortName" toAttribute:@"routeShortName"];
        [mapping mapKeyPath:@"startTime" toAttribute:@"startTime"];
        [mapping mapKeyPath:@"tripShortName" toAttribute:@"tripShortName"];

        [mapping mapKeyPath:@"steps" toRelationship:@"steps" withMapping:stepsMapping];
        [mapping mapKeyPath:@"from" toRelationship:@"from" withMapping:planPlaceMapping];
        [mapping mapKeyPath:@"to" toRelationship:@"to" withMapping:planPlaceMapping];
    }
    else {
        // TODO Unknown planner type, throw an exception
    }
    return mapping;
}

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


// Getter to create (if needed) and return the polylineEncodedString object corresponding to the legGeometryPoints
- (PolylineEncodedString *)polylineEncodedString
{
    if (!polylineEncodedString) {
        polylineEncodedString = [[PolylineEncodedString alloc] initWithEncodedString:[self legGeometryPoints]];
    }
    return polylineEncodedString;
}

- (NSString *)directionsTitleText
{
    NSMutableString *titleText=[NSMutableString stringWithString:@""];
    if ([[self mode] isEqualToString:@"WALK"]) {
        titleText = [NSString stringWithFormat:@"Walk to %@", [[self to] name]];
    }
    else if ([[self mode] isEqualToString:@"BUS"]) {
        titleText = [NSMutableString stringWithString:@"Bus "];
    }
    else if ([[self mode] isEqualToString:@"TRAM"]) {
        titleText = [NSMutableString stringWithString:@"Tram "];
    }
    else {
        titleText = [NSMutableString stringWithString:@""];
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
        [titleText appendFormat:@"%@", [self routeLongName]];
    }
    if ([self headSign] && [[self headSign] length]>0) {
        [titleText appendFormat:@" to %@", [self headSign]];
    }
    return titleText;
}

- (NSString *)directionsDetailText
{
    NSString *subTitle;
    NSDateFormatter* timeFormatter = [Leg timeFormatter];
    if ([[self mode] isEqualToString:@"WALK"]) {
        subTitle = [NSString stringWithFormat:@"About %@, %@", 
                    durationString([[self duration] floatValue]), 
                    distanceStringInMilesFeet([[self distance] floatValue])];
    }
    else if ([[self mode] isEqualToString:@"BUS"]) {
        subTitle = [NSString stringWithFormat:@"%@  Depart %@\n%@  Arrive %@",
                    [timeFormatter stringFromDate:[self startTime]],
                    [[self from] name],
                    [timeFormatter stringFromDate:[self endTime]],
                    [[self to] name]];
    }
    else {
        subTitle = [NSString stringWithFormat:@"%@  Depart %@\n%@  Arrive %@",
                    [timeFormatter stringFromDate:[self startTime]],
                    [[self from] name],
                    [timeFormatter stringFromDate:[self endTime]],
                    [[self to] name]];            
    }
    return subTitle;
}


//Implemented by Sitanshu Joshi
-(BOOL)isWalk
{
    if ([[self mode] isEqualToString:@"WALK"]) {   
        return true;   
    }
    return false;
}
-(BOOL)isBus
{
    if ([[self mode] isEqualToString:@"BUS"]) {   
        return true;   
    }
    return false;
}

- (NSString *)ncDescription
{
    NSMutableString* desc = [NSMutableString stringWithFormat:
                             @"{Leg Object: mode: %@;  headSign: %@;  endTime: %@ ... ", [self mode], [self headSign], [self endTime]];
    for (Itinerary *step in [self steps]) {
        [desc appendString:[NSString stringWithFormat:@"\n%@", [step ncDescription]]];
    }
    return desc;
}

@end