//
//  GtfsParser.m
//  Nimbler Caltrain
//
//  Created by macmini on 07/12/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "GtfsParser.h"
#import "GtfsAgency.h"
#import "UtilityFunctions.h"
#import "GtfsCalendarDates.h"
#import "GtfsCalendar.h"
#import "GtfsRoutes.h"
#import "GtfsStop.h"
#import "GtfsTrips.h"
#import "GtfsStopTimes.h"
#import "UtilityFunctions.h"

@implementation GtfsParser

@synthesize managedObjectContext;
@synthesize strAgenciesURL;
@synthesize strCalendarDatesURL;
@synthesize strCalendarURL;
@synthesize strRoutesURL;
@synthesize strStopsURL;
@synthesize strTripsURL;
@synthesize strStopTimesURL;


- (id)initWithManagedObjectContext:(NSManagedObjectContext *)moc
{
    self = [super init];
    if (self) {
        self.managedObjectContext = moc;
    }
    
    return self;
}

- (void) parseAgencyDataAndStroreToDataBase:(NSDictionary *)dictFileData{
    NSFetchRequest * fetchAgencies = [[NSFetchRequest alloc] init];
    [fetchAgencies setEntity:[NSEntityDescription entityForName:@"GtfsAgency" inManagedObjectContext:self.managedObjectContext]];
    NSArray * arrayAgencies = [self.managedObjectContext executeFetchRequest:fetchAgencies error:nil];
    for (id planRequestChunks in arrayAgencies){
        [self.managedObjectContext deleteObject:planRequestChunks];
    }
    
    NSMutableArray *arrayAgencyID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayAgencyName = [[NSMutableArray alloc] init];
    NSMutableArray *arrayAgencyURL = [[NSMutableArray alloc] init];

    NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
    for(int k=1;k<=4;k++){
        NSArray *arrayComponentsAgency = [dictComponents objectForKey:[NSString stringWithFormat:@"%d_agency",k]];
        for(int i=1;i<[arrayComponentsAgency count];i++){
            NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
            NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
            if([arraySubComponents count] > 0){
                [arrayAgencyID addObject:[arraySubComponents objectAtIndex:0]];
            }
            else{
                [arrayAgencyID addObject:@""];
            }
            if([arraySubComponents count] > 1){
                [arrayAgencyName addObject:[arraySubComponents objectAtIndex:1]];
            }
            else{
                [arrayAgencyName addObject:@""];
            }
            if([arraySubComponents count] > 2){
                [arrayAgencyURL addObject:[arraySubComponents objectAtIndex:2]];
            }
            else{
                [arrayAgencyURL addObject:@""];
            }
        }
    }
    for(int i=0;i<[arrayAgencyID count];i++){
            GtfsAgency* agency = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsAgency" inManagedObjectContext:self.managedObjectContext];
            agency.agencyID = [arrayAgencyID objectAtIndex:i];
            agency.agencyName = [arrayAgencyName objectAtIndex:i];
            agency.agencyURL = [arrayAgencyURL objectAtIndex:i];
    }
    saveContext(self.managedObjectContext);
}

- (void) parseCalendarDatesDataAndStroreToDataBase:(NSDictionary *)dictFileData{
    NSFetchRequest * fetchCalendarDates = [[NSFetchRequest alloc] init];
    [fetchCalendarDates setEntity:[NSEntityDescription entityForName:@"GtfsCalendarDates" inManagedObjectContext:self.managedObjectContext]];
    NSArray * arrayPlanCalendarDates = [self.managedObjectContext executeFetchRequest:fetchCalendarDates error:nil];
    for (id calendarDates in arrayPlanCalendarDates){
        [self.managedObjectContext deleteObject:calendarDates];
    }
    
    NSMutableArray *arrayServiceID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayDate = [[NSMutableArray alloc] init];
    NSMutableArray *arrayExceptionType = [[NSMutableArray alloc] init];
    
    NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
    for(int k=1;k<=4;k++){
        NSArray *arrayComponentsAgency = [dictComponents objectForKey:[NSString stringWithFormat:@"%d_calendar_dates",k]];
        for(int i=1;i<[arrayComponentsAgency count];i++){
            NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
            NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
            if([arraySubComponents count] > 0){
                [arrayServiceID addObject:[arraySubComponents objectAtIndex:0]];
            }
            else{
                [arrayServiceID addObject:@""];
            }
            if([arraySubComponents count] > 1){
                [arrayDate addObject:[arraySubComponents objectAtIndex:1]];
            }
            else{
                [arrayDate addObject:@""];
            }
            if([arraySubComponents count] > 2){
                [arrayExceptionType addObject:[arraySubComponents objectAtIndex:2]];
            }
            else{
                [arrayExceptionType addObject:@""];
            }
        }
    }
    NSDateFormatter *formtter = [[NSDateFormatter alloc] init];
    [formtter setDateFormat:@"yyyyMMdd"];
    for(int i=0;i<[arrayServiceID count];i++){
        GtfsCalendarDates* calendarDates = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsCalendarDates" inManagedObjectContext:self.managedObjectContext];
        calendarDates.serviceID = [arrayServiceID objectAtIndex:i];
        NSDate *dates = [formtter dateFromString:[arrayDate objectAtIndex:i]];
        calendarDates.date = dates;
        calendarDates.exceptionType = [arrayExceptionType objectAtIndex:i];
    }
    saveContext(self.managedObjectContext);
}

- (void) parseCalendarDataAndStroreToDataBase:(NSDictionary *)dictFileData{
    NSFetchRequest * fetchCalendar = [[NSFetchRequest alloc] init];
    [fetchCalendar setEntity:[NSEntityDescription entityForName:@"GtfsCalendar" inManagedObjectContext:self.managedObjectContext]];
    NSArray * arrayCalendar = [self.managedObjectContext executeFetchRequest:fetchCalendar error:nil];
    for (id calendar in arrayCalendar){
        [self.managedObjectContext deleteObject:calendar];
    }
    
    NSMutableArray *arrayServiceID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayMonday = [[NSMutableArray alloc] init];
    NSMutableArray *arrayTuesday = [[NSMutableArray alloc] init];
    NSMutableArray *arrayWednesday = [[NSMutableArray alloc] init];
    NSMutableArray *arrayThursday = [[NSMutableArray alloc] init];
    NSMutableArray *arrayFriday = [[NSMutableArray alloc] init];
    NSMutableArray *arraySaturday = [[NSMutableArray alloc] init];
    NSMutableArray *arraySunday = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStartDate = [[NSMutableArray alloc] init];
    NSMutableArray *arrayEndDate = [[NSMutableArray alloc] init];
    
    NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
    for(int k=1;k<=4;k++){
        NSArray *arrayComponentsAgency = [dictComponents objectForKey:[NSString stringWithFormat:@"%d_calendar",k]];
        for(int i=1;i<[arrayComponentsAgency count];i++){
            NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
            NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
            if([arraySubComponents count] > 0){
                [arrayServiceID addObject:[arraySubComponents objectAtIndex:0]];
            }
            else{
                [arrayServiceID addObject:@""];
            }
            if([arraySubComponents count] > 1){
                [arrayMonday addObject:[arraySubComponents objectAtIndex:1]];
            }
            else{
                [arrayMonday addObject:@""];
            }
            if([arraySubComponents count] > 2){
                [arrayTuesday addObject:[arraySubComponents objectAtIndex:2]];
            }
            else{
                [arrayTuesday addObject:@""];
            }
            if([arraySubComponents count] > 3){
                [arrayWednesday addObject:[arraySubComponents objectAtIndex:3]];
            }
            else{
                [arrayWednesday addObject:@""];
            }
            if([arraySubComponents count] > 4){
                [arrayThursday addObject:[arraySubComponents objectAtIndex:4]];
            }
            else{
                [arrayThursday addObject:@""];
            }
            if([arraySubComponents count] > 5){
                [arrayFriday addObject:[arraySubComponents objectAtIndex:5]];
            }
            else{
                [arrayFriday addObject:@""];
            }
            if([arraySubComponents count] > 6){
                [arraySaturday addObject:[arraySubComponents objectAtIndex:6]];
            }
            else{
                [arraySaturday addObject:@""];
            }
            if([arraySubComponents count] > 7){
                [arraySunday addObject:[arraySubComponents objectAtIndex:7]];
            }
            else{
                [arraySunday addObject:@""];
            }
            if([arraySubComponents count] > 8){
                [arrayStartDate addObject:[arraySubComponents objectAtIndex:8]];
            }
            else{
                [arrayStartDate addObject:@""];
            }
            if([arraySubComponents count] > 9){
                [arrayEndDate addObject:[arraySubComponents objectAtIndex:9]];
            }
            else{
                [arrayEndDate addObject:@""];
            }
        }
    }
    NSDateFormatter *formtter = [[NSDateFormatter alloc] init];
    [formtter setDateFormat:@"yyyyMMdd"];
    for(int i=0;i<[arrayServiceID count];i++){
        GtfsCalendar* calendar = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsCalendar" inManagedObjectContext:self.managedObjectContext];
        calendar.serviceID = [arrayServiceID objectAtIndex:i];
        int dMonday = [[arrayMonday objectAtIndex:i] intValue];
        int dTuesday = [[arrayTuesday objectAtIndex:i] intValue];
        int dWednesday = [[arrayWednesday objectAtIndex:i] intValue];
        int dThursday = [[arrayThursday objectAtIndex:i] intValue];
        int dFriday = [[arrayFriday objectAtIndex:i] intValue];
        int dSaturday = [[arraySaturday objectAtIndex:i] intValue];
        int dSunday = [[arraySunday objectAtIndex:i] intValue];
        calendar.monday = [NSNumber numberWithInt:dMonday];
        calendar.tuesday = [NSNumber numberWithInt:dTuesday];
        calendar.wednesday = [NSNumber numberWithInt:dWednesday];
        calendar.thursday = [NSNumber numberWithInt:dThursday];
        calendar.friday = [NSNumber numberWithInt:dFriday];
        calendar.saturday = [NSNumber numberWithInt:dSaturday];
        calendar.sunday = [NSNumber numberWithInt:dSunday];
        
        NSDate *startDate = [formtter dateFromString:[arrayStartDate objectAtIndex:i]];
        NSDate *endDate = [formtter dateFromString:[arrayEndDate objectAtIndex:i]];
        calendar.startDate = startDate;
        calendar.startDate = endDate;
    }
    saveContext(self.managedObjectContext);
}

- (void) parseRoutesDataAndStroreToDataBase:(NSDictionary *)dictFileData{
    NSFetchRequest * fetchRoutes = [[NSFetchRequest alloc] init];
    [fetchRoutes setEntity:[NSEntityDescription entityForName:@"GtfsRoutes" inManagedObjectContext:self.managedObjectContext]];
    NSArray * arrayRoutes = [self.managedObjectContext executeFetchRequest:fetchRoutes error:nil];
    for (id routes in arrayRoutes){
        [self.managedObjectContext deleteObject:routes];
    }
    
    NSMutableArray *arrayRouteID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayRouteShortName = [[NSMutableArray alloc] init];
    NSMutableArray *arrayRouteLongName = [[NSMutableArray alloc] init];
    NSMutableArray *arrayRouteDesc = [[NSMutableArray alloc] init];
    NSMutableArray *arrayRouteType = [[NSMutableArray alloc] init];
    NSMutableArray *arrayRouteURL = [[NSMutableArray alloc] init];
    NSMutableArray *arrayRouteColor = [[NSMutableArray alloc] init];
    NSMutableArray *arrayRouteTextColor = [[NSMutableArray alloc] init];
    
    NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
    for(int k=1;k<=4;k++){
        NSArray *arrayComponentsAgency = [dictComponents objectForKey:[NSString stringWithFormat:@"%d_routes",k]];
        for(int i=1;i<[arrayComponentsAgency count];i++){
            NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
            NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
            if([arraySubComponents count] > 0){
                [arrayRouteID addObject:[arraySubComponents objectAtIndex:0]];
            }
            else{
                [arrayRouteID addObject:@""];
            }
            if([arraySubComponents count] > 1){
                [arrayRouteShortName addObject:[arraySubComponents objectAtIndex:1]];
            }
            else{
                [arrayRouteShortName addObject:@""];
            }
            if([arraySubComponents count] > 2){
                [arrayRouteLongName addObject:[arraySubComponents objectAtIndex:2]];
            }
            else{
                [arrayRouteLongName addObject:@""];
            }
            if([arraySubComponents count] > 3){
                [arrayRouteDesc addObject:[arraySubComponents objectAtIndex:3]];
            }
            else{
                [arrayRouteDesc addObject:@""];
            }
            if([arraySubComponents count] > 4){
                [arrayRouteType addObject:[arraySubComponents objectAtIndex:4]];
            }
            else{
                [arrayRouteType addObject:@""];
            }
            if([arraySubComponents count] > 5){
                [arrayRouteURL addObject:[arraySubComponents objectAtIndex:5]];
            }
            else{
                [arrayRouteURL addObject:@""];
            }
            if([arraySubComponents count] > 6){
                [arrayRouteColor addObject:[arraySubComponents objectAtIndex:6]];
            }
            else{
                [arrayRouteColor addObject:@""];
            }
            if([arraySubComponents count] > 7){
                [arrayRouteTextColor addObject:[arraySubComponents objectAtIndex:7]];
            }
            else{
                [arrayRouteTextColor addObject:@""];
            }
        }
    }
    for(int i=0;i<[arrayRouteID count];i++){
        GtfsRoutes* routes = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsRoutes" inManagedObjectContext:self.managedObjectContext];
        routes.routeID = [arrayRouteID objectAtIndex:i];
        routes.routeShortName = [arrayRouteShortName objectAtIndex:i];
        routes.routeLongname = [arrayRouteLongName objectAtIndex:i];
        routes.routeDesc = [arrayRouteDesc objectAtIndex:i];
        routes.routeType = [arrayRouteType objectAtIndex:i];
        routes.routeURL = [arrayRouteURL objectAtIndex:i];
        routes.routeColor = [arrayRouteColor objectAtIndex:i];
        routes.routeTextColor = [arrayRouteTextColor objectAtIndex:i];
    }
    saveContext(self.managedObjectContext);
}

- (void) parseStopsDataAndStroreToDataBase:(NSDictionary *)dictFileData{
    NSFetchRequest * fetchStops = [[NSFetchRequest alloc] init];
    [fetchStops setEntity:[NSEntityDescription entityForName:@"GtfsStop" inManagedObjectContext:self.managedObjectContext]];
    NSArray * arrayStops = [self.managedObjectContext executeFetchRequest:fetchStops error:nil];
    for (id stops in arrayStops){
        [self.managedObjectContext deleteObject:stops];
    }
    
    NSMutableArray *arrayStopID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStopName = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStopDesc = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStopLat = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStopLong = [[NSMutableArray alloc] init];
    NSMutableArray *arrayZoneID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStopURL = [[NSMutableArray alloc] init];
    
    NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
    for(int k=1;k<=4;k++){
        NSArray *arrayComponentsAgency = [dictComponents objectForKey:[NSString stringWithFormat:@"%d_stops",k]];
        for(int i=1;i<[arrayComponentsAgency count];i++){
            NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
            NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
            if([arraySubComponents count] > 0){
                [arrayStopID addObject:[arraySubComponents objectAtIndex:0]];
            }
            else{
                [arrayStopID addObject:@""];
            }
            if([arraySubComponents count] > 1){
                [arrayStopName addObject:[arraySubComponents objectAtIndex:1]];
            }
            else{
                [arrayStopName addObject:@""];
            }
            if([arraySubComponents count] > 2){
                [arrayStopDesc addObject:[arraySubComponents objectAtIndex:2]];
            }
            else{
                [arrayStopDesc addObject:@""];
            }
            if([arraySubComponents count] > 3){
                [arrayStopLat addObject:[arraySubComponents objectAtIndex:3]];
            }
            else{
                [arrayStopLat addObject:@""];
            }
            if([arraySubComponents count] > 4){
                [arrayStopLong addObject:[arraySubComponents objectAtIndex:4]];
            }
            else{
                [arrayStopLong addObject:@""];
            }
            if([arraySubComponents count] > 5){
                [arrayZoneID addObject:[arraySubComponents objectAtIndex:5]];
            }
            else{
                [arrayZoneID addObject:@""];
            }
            if([arraySubComponents count] > 6){
                [arrayStopURL addObject:[arraySubComponents objectAtIndex:6]];
            }
            else{
                [arrayStopURL addObject:@""];
            }
        }
    }
    for(int i=0;i<[arrayStopID count];i++){
        GtfsStop* routes = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsStop" inManagedObjectContext:self.managedObjectContext];
        routes.stopID = [arrayStopID objectAtIndex:i];
        routes.stopName = [arrayStopName objectAtIndex:i];
        routes.stopDesc = [arrayStopDesc objectAtIndex:i];
        double stopLat = [[arrayStopLat objectAtIndex:i] doubleValue];
        double stopLong = [[arrayStopLong objectAtIndex:i] doubleValue];
        routes.stopLat = [NSNumber numberWithDouble:stopLat];
        routes.stopLon = [NSNumber numberWithDouble:stopLong];
        routes.zoneID = [arrayZoneID objectAtIndex:i];
        routes.stopURL = [arrayStopURL objectAtIndex:i];
    }
    saveContext(self.managedObjectContext);
}

- (void) parseTripsDataAndStroreToDataBase:(NSDictionary *)dictFileData{
    NSFetchRequest * fetchTrips = [[NSFetchRequest alloc] init];
    [fetchTrips setEntity:[NSEntityDescription entityForName:@"GtfsTrips" inManagedObjectContext:self.managedObjectContext]];
    NSArray * arrayTrips = [self.managedObjectContext executeFetchRequest:fetchTrips error:nil];
    for (id trips in arrayTrips){
        [self.managedObjectContext deleteObject:trips];
    }
    
    NSMutableArray *arrayTripID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayRouteID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayServiceID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayTripHeadSign = [[NSMutableArray alloc] init];
    NSMutableArray *arrayDirectionID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayBlockID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayShapeID = [[NSMutableArray alloc] init];
    
    NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
    for(int k=1;k<=4;k++){
        NSArray *arrayComponentsAgency = [dictComponents objectForKey:[NSString stringWithFormat:@"%d_trips",k]];
        for(int i=1;i<[arrayComponentsAgency count];i++){
            NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
            NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
            if([arraySubComponents count] > 0){
                [arrayTripID addObject:[arraySubComponents objectAtIndex:0]];
            }
            else{
                [arrayTripID addObject:@""];
            }
            if([arraySubComponents count] > 1){
                [arrayRouteID addObject:[arraySubComponents objectAtIndex:1]];
            }
            else{
                [arrayRouteID addObject:@""];
            }
            if([arraySubComponents count] > 2){
                [arrayServiceID addObject:[arraySubComponents objectAtIndex:2]];
            }
            else{
                [arrayServiceID addObject:@""];
            }
            if([arraySubComponents count] > 3){
                [arrayTripHeadSign addObject:[arraySubComponents objectAtIndex:3]];
            }
            else{
                [arrayTripHeadSign addObject:@""];
            }
            if([arraySubComponents count] > 4){
                [arrayDirectionID addObject:[arraySubComponents objectAtIndex:4]];
            }
            else{
                [arrayDirectionID addObject:@""];
            }
            if([arraySubComponents count] > 5){
                [arrayBlockID addObject:[arraySubComponents objectAtIndex:5]];
            }
            else{
                [arrayBlockID addObject:@""];
            }
            if([arraySubComponents count] > 6){
                [arrayShapeID addObject:[arraySubComponents objectAtIndex:6]];
            }
            else{
                [arrayShapeID addObject:@""];
            }
        }
    }
    for(int i=0;i<[arrayTripID count];i++){
        GtfsTrips* routes = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsTrips" inManagedObjectContext:self.managedObjectContext];
        routes.tripID = [arrayTripID objectAtIndex:i];
        routes.routeID = [arrayRouteID objectAtIndex:i];
        routes.serviceID = [arrayServiceID objectAtIndex:i];
        routes.tripHeadSign = [arrayTripHeadSign objectAtIndex:i];
        routes.directionID = [arrayDirectionID objectAtIndex:i];
        routes.blockID = [arrayBlockID objectAtIndex:i];
        routes.shapeID = [arrayShapeID objectAtIndex:i];
    }
    saveContext(self.managedObjectContext);
}

- (void) parseStopTimesAndStroreToDataBase:(NSDictionary *)dictFileData:(NSString *)strResourcePath{
    NSArray *arrayComponents = [strResourcePath componentsSeparatedByString:@"?"];
    NSString *tempString = [arrayComponents objectAtIndex:1];
    NSArray *arraySubComponents = [tempString componentsSeparatedByString:@"="];
    NSString *tempStringSubComponents = [arraySubComponents objectAtIndex:1];
    NSArray *arrayAgencyIds = [tempStringSubComponents componentsSeparatedByString:@"%2C"];
    NSMutableArray *arrayTripID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayArrivalTime = [[NSMutableArray alloc] init];
    NSMutableArray *arrayDepartureTime = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStopID = [[NSMutableArray alloc] init];
    NSMutableArray *arrayStopSequence = [[NSMutableArray alloc] init];
    NSMutableArray *arrayPickUpType = [[NSMutableArray alloc] init];
    NSMutableArray *arrayDropOffType = [[NSMutableArray alloc] init];
    NSMutableArray *arrayShapeDistTraveled = [[NSMutableArray alloc] init];
    NSMutableArray *arrayAgencyID = [[NSMutableArray alloc] init];
    
    NSDictionary *dictComponents = [dictFileData objectForKey:@"data"];
    for(int k=0;k<[arrayAgencyIds count];k++){
        NSArray *arrayComponentsAgency = [dictComponents objectForKey:[arrayAgencyIds objectAtIndex:k]];
        for(int i=1;i<[arrayComponentsAgency count];i++){
            NSString *strAgencyIds = [arrayAgencyIds objectAtIndex:k];
            NSArray *arrayAgencyIdsComponents = [strAgencyIds componentsSeparatedByString:@"_"];
            if([arrayAgencyIdsComponents count] > 1){
                [arrayAgencyID addObject:[arrayAgencyIdsComponents objectAtIndex:0]];
            }
            else{
               [arrayAgencyID addObject:@""];
            }
            NSString *strSubComponents = [arrayComponentsAgency objectAtIndex:i];
            NSArray *arraySubComponents = [strSubComponents componentsSeparatedByString:@","];
            if([arraySubComponents count] > 0){
                [arrayTripID addObject:[arraySubComponents objectAtIndex:0]];
            }
            else{
                [arrayTripID addObject:@""];
            }
            if([arraySubComponents count] > 1){
                [arrayArrivalTime addObject:[arraySubComponents objectAtIndex:1]];
            }
            else{
                [arrayArrivalTime addObject:@""];
            }
            if([arraySubComponents count] > 2){
                [arrayDepartureTime addObject:[arraySubComponents objectAtIndex:2]];
            }
            else{
                [arrayDepartureTime addObject:@""];
            }
            if([arraySubComponents count] > 3){
                [arrayStopID addObject:[arraySubComponents objectAtIndex:3]];
            }
            else{
                [arrayStopID addObject:@""];
            }
            if([arraySubComponents count] > 4){
                [arrayStopSequence addObject:[arraySubComponents objectAtIndex:4]];
            }
            else{
                [arrayStopSequence addObject:@""];
            }
            if([arraySubComponents count] > 5){
                [arrayPickUpType addObject:[arraySubComponents objectAtIndex:5]];
            }
            else{
                [arrayPickUpType addObject:@""];
            }
            if([arraySubComponents count] > 6){
                [arrayDropOffType addObject:[arraySubComponents objectAtIndex:6]];
            }
            else{
                [arrayDropOffType addObject:@""];
            }
            if([arraySubComponents count] > 7){
                [arrayShapeDistTraveled addObject:[arraySubComponents objectAtIndex:7]];
            }
            else{
                [arrayShapeDistTraveled addObject:@""];
            }
        }
    }
    
    for(int l=0;l<[arrayTripID count];l++){
        NSFetchRequest * fetchTrips = [[NSFetchRequest alloc] init];
        [fetchTrips setEntity:[NSEntityDescription entityForName:@"GtfsStopTimes" inManagedObjectContext:self.managedObjectContext]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"tripID = %@ && stopSequence = %@",[arrayTripID objectAtIndex:l],[arrayStopSequence objectAtIndex:l]];
        [fetchTrips setPredicate:predicate];
        NSArray * arrayTrips = [self.managedObjectContext executeFetchRequest:fetchTrips error:nil];
        for (id trips in arrayTrips){
            [self.managedObjectContext deleteObject:trips];
        }
    }
    for(int j=0;j<[arrayTripID count];j++){
        GtfsStopTimes* stopTimes = [NSEntityDescription insertNewObjectForEntityForName:@"GtfsStopTimes" inManagedObjectContext:self.managedObjectContext];
        stopTimes.tripID = [arrayTripID objectAtIndex:j];
        stopTimes.arrivalTime = [arrayArrivalTime objectAtIndex:j];
        stopTimes.departureTime = [arrayDepartureTime objectAtIndex:j];
        stopTimes.stopID = [arrayStopID objectAtIndex:j];
        stopTimes.stopSequence = [arrayStopSequence objectAtIndex:j];
        stopTimes.pickUpTime = [arrayPickUpType objectAtIndex:j];
        stopTimes.dropOfTime = [arrayDropOffType objectAtIndex:j];
        stopTimes.shapeDistTravelled = [arrayShapeDistTraveled objectAtIndex:j];
        stopTimes.agencyID = [arrayAgencyID objectAtIndex:j];
    }
    saveContext(self.managedObjectContext);
}

// Find The nearest Stations
- (NSArray *)findNearestStation:(CLLocation *)toLocation{
    NSFetchRequest * fetchTrips = [[NSFetchRequest alloc] init];
    [fetchTrips setEntity:[NSEntityDescription entityForName:@"GtfsStop" inManagedObjectContext:self.managedObjectContext]];
    NSArray * arrayTrips = [self.managedObjectContext executeFetchRequest:fetchTrips error:nil];
    NSMutableArray *arrayStops = [[NSMutableArray alloc] init];
    for (int i=0;i<[arrayTrips count];i++){
        GtfsStop *stop = [arrayTrips objectAtIndex:i];
        double lat = [stop.stopLat doubleValue];
        double lng = [stop.stopLon doubleValue];
        CLLocation *fromLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lng];
        CLLocationDistance distance = distanceBetweenTwoLocation(toLocation, fromLocation);
        int nDistance = distance/1000;
        if(nDistance <= 3){
            [arrayStops addObject:stop];
        }
    }
    return arrayStops;
}

#pragma mark  GTFS Requests

// Request The Server For Agency Data.
-(void)getAgencyDatas{
    @try {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"agency",ENTITY,@"1,2,3,4",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strAgenciesURL = request;
        NIMLOG_OBJECT1(@"Get Agencies: %@", request);
        [[RKClient sharedClient]  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getAgencies", @"", exception);
    }
}

// Request The Server For Calendar Dates.
-(void)getCalendarDates{
    @try {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"calendar_dates",ENTITY,@"1,2,3,4",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strCalendarDatesURL = request;
        NIMLOG_OBJECT1(@"Get Calendar Dates: %@", request);
        [[RKClient sharedClient]  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getCalendarDates", @"", exception);
    }
}

// Request The Server For Calendar Data.
-(void)getCalendarData{
    @try {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"calendar",ENTITY,@"1,2,3,4",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strCalendarURL = request;
        NIMLOG_OBJECT1(@"Get Calendar: %@", request);
        [[RKClient sharedClient]  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getCalendarData", @"", exception);
    }
}

// Request The Server For Routes Data.
-(void)getRoutesData{
    @try {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"routes",ENTITY,@"1,2,3,4",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strRoutesURL = request;
        NIMLOG_OBJECT1(@"Get Routes: %@", request);
        [[RKClient sharedClient]  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getRoutesData", @"", exception);
    }
}

// Request The Server For Stops Data.
-(void)getStopsData{
    @try {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"stops",ENTITY,@"1,2,3,4",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strStopsURL = request;
        NIMLOG_OBJECT1(@"Get Stops: %@", request);
        [[RKClient sharedClient]  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getStopsData", @"", exception);
    }
}

// Request The Server For Trips Data.
-(void)getTripsData{
    @try {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:@"trips",ENTITY,@"1,2,3,4",AGENCY_IDS, nil];
        NSString *request = [GTFS_RAWDATA appendQueryParams:dictParameters];
        strTripsURL = request;
        NIMLOG_OBJECT1(@"Get Trips: %@", request);
        [[RKClient sharedClient]  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getTripsData", @"", exception);
    }
}

// Request The Server For StopTimes Data.
- (void) getGtfsStopTimes:(NSMutableString *)strRequestString{
    int nLength = [strRequestString length];
    if(nLength > 0){
        [strRequestString deleteCharactersInRange:NSMakeRange(nLength-1, 1)];
    }
    @try {
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        [RKClient setSharedClient:client];
        NSDictionary *dictParameters = [NSDictionary dictionaryWithObjectsAndKeys:strRequestString,AGENCY_IDS, nil];
        NSString *request = [GTFS_STOP_TIMES appendQueryParams:dictParameters];
        strStopTimesURL = request;
        NIMLOG_OBJECT1(@"get Gtfs Stop Times: %@", request);
        [[RKClient sharedClient]  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->getAgencies", @"", exception);
    }
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response
{
    NSString *strRequestURL = request.resourcePath;
    @try {
        if ([request isGET]) {
            NSError *error = nil;
            if (error == nil)
            {
               if ([strRequestURL isEqualToString:strAgenciesURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self performSelector:@selector(parseAgencyDataAndStroreToDataBase:) withObject:res];
                        [self performSelector:@selector(getCalendarDates) withObject:nil];
                    }
                    else{
                        [self performSelector:@selector(getAgencyDatas) withObject:nil];
                    }
                }
                else if ([strRequestURL isEqualToString:strCalendarDatesURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self performSelector:@selector(parseCalendarDatesDataAndStroreToDataBase:) withObject:res];
                        [self performSelector:@selector(getCalendarData) withObject:nil];
                    }
                    else{
                        [self performSelector:@selector(getCalendarDates) withObject:nil];
                    }
                }
                else if ([strRequestURL isEqualToString:strCalendarURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self performSelector:@selector(parseCalendarDataAndStroreToDataBase:) withObject:res];
                        [self performSelector:@selector(getRoutesData) withObject:nil];
                    }
                    else{
                        [self performSelector:@selector(getCalendarData) withObject:nil];
                    }
                }
                else if ([strRequestURL isEqualToString:strRoutesURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self performSelector:@selector(parseRoutesDataAndStroreToDataBase:) withObject:res];
                        [self performSelector:@selector(getStopsData) withObject:nil];
                    }
                    else{
                        [self performSelector:@selector(getRoutesData) withObject:nil];
                    }
                }
                else if ([strRequestURL isEqualToString:strStopsURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self performSelector:@selector(parseStopsDataAndStroreToDataBase:) withObject:res];
                        [self performSelector:@selector(getTripsData) withObject:nil];
                    }
                    else{
                        [self performSelector:@selector(getStopsData) withObject:nil];
                    }
                }
                else if ([strRequestURL isEqualToString:strTripsURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self performSelector:@selector(parseTripsDataAndStroreToDataBase:) withObject:res];
                    }
                    else{
                        [self performSelector:@selector(getTripsData) withObject:nil];
                    }
                }
                else if ([strRequestURL isEqualToString:strStopTimesURL]) {
                    RKJSONParserJSONKit* rkLiveDataParser = [RKJSONParserJSONKit new];
                    NSDictionary *  res = [rkLiveDataParser objectFromString:[response bodyAsString] error:nil];
                    NSNumber *respCode = [res objectForKey:RESPONSE_CODE];
                    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                        [self parseStopTimesAndStroreToDataBase:res :strRequestURL];
                    }
                }
            }
        }
    }
    @catch (NSException *exception) {
        logException(@"GtfsParser->didLoadResponse", @"catching TPServer Response", exception);
    }
}

// Partial Implementation ( Working On this Function)
// Check Schedule Table with ToLocation,FromLocation and arrayLegs.
// If all match in Schedule Then we will not save pattern again otherwise we will save pattern.
- (void)checkIfPatternAlreadyExists:(NSArray *)arrayLegs:(Location *)toLocation:(Location *)fromLocation{
    NSMutableArray *arrayFinalLegs = [[NSMutableArray alloc] initWithArray:arrayLegs];
    NSFetchRequest * fetchTrips = [[NSFetchRequest alloc] init];
    [fetchTrips setEntity:[NSEntityDescription entityForName:@"Schedule" inManagedObjectContext:self.managedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fromLat=%@ && fromLng=%@ && toLat=%@ && toLng = %@",fromLocation.lat,fromLocation.lng,toLocation.lat,toLocation.lng];
    [fetchTrips setPredicate:predicate];
    NSArray * arraySchedule = [self.managedObjectContext executeFetchRequest:fetchTrips error:nil];
    for(int i=0;i<[arraySchedule count];i++){
            Schedule *schedule1 = [arraySchedule objectAtIndex:i];
            NSArray *arrLegs1 = schedule1.legs;
        for(int j=0;j<[arrLegs1 count];j++){
            for(int l=0;l<[arrayLegs count];l++){
                NSArray *tempArray1 = [arrLegs1 objectAtIndex:j];
                NSArray *tempArray2 = [arrayLegs objectAtIndex:l];
                if(![tempArray1 isEqualToArray:tempArray2]){
                    [arrayFinalLegs addObject:tempArray2];
                }
            }
        }
        schedule1.toLat = toLocation.lat;
        schedule1.toLng = toLocation.lng;
        schedule1.fromLat = fromLocation.lat;
        schedule1.fromLng = fromLocation.lng;
        schedule1.toFormattedAddress = toLocation.formattedAddress;
        schedule1.fromFormattedAddress = fromLocation.formattedAddress;
        schedule1.legs = arrayFinalLegs;
    }
    saveContext(self.managedObjectContext);
}

// Save Patterns To Schedule Table.
- (void)saveSchedule:(Plan *)plan:(Location *)fromLocation:(Location *)toLocation{
    NSMutableArray *arrayLegs = [[NSMutableArray alloc] init];
    NSMutableArray *arrFinalLegs = [[NSMutableArray alloc] init];
    NSArray *itiArray = [plan sortedItineraries];
    for(int i=0;i<[itiArray count];i++){
        Itinerary *iti = [itiArray objectAtIndex:i];
        NSArray *legArray = [iti sortedLegs];
        if([arrayLegs count] == 0){
            [arrayLegs addObject:legArray];
        }
        else{
            NSArray *tempLegs = [NSArray arrayWithArray:arrayLegs];
            for(int i=0;i<[tempLegs count];i++){
                NSArray *subArray = [tempLegs objectAtIndex:i];
                if([subArray count] != [legArray count]){
                    [arrayLegs addObject:legArray];
                }
                else{
                    BOOL isLegsEqual = YES;
                    for(int i=0;i<[legArray count];i++){
                        Leg *leg1 = [legArray objectAtIndex:i];
                        Leg *leg2 = [subArray objectAtIndex:i];
                        if(![leg1.agencyName isEqualToString:leg2.agencyName] || ![leg1.to.lat isEqual:leg2.to.lat] || ![leg1.from.lat isEqual:leg2.from.lat]|| ![leg1.to.lng isEqual:leg2.to.lng] || ![leg1.from.lng isEqual:leg2.from.lng]){
                            isLegsEqual = NO;
                        }
                    }
                    if(!isLegsEqual){
                        [arrayLegs addObject:legArray];
                    }
                }
            }
        }
    }
    for(int i=0;i<[arrayLegs count];i++){
        for (int l=i+1;l<[arrayLegs count];l++){
            NSArray *arrayTemp1 = [arrayLegs objectAtIndex:i];
            NSArray *arrayTemp2 = [arrayLegs objectAtIndex:l];
            for(int j=0;j<[arrayTemp1 count];j++){
                for(int k=0;k<[arrayTemp2 count];k++){
                    Leg *leg1 = [arrayTemp1 objectAtIndex:j];
                    Leg *leg2 = [arrayTemp2 objectAtIndex:k];
                    if([leg1.agencyName isEqualToString:leg2.agencyName] && [leg1.to.lat isEqual:leg2.to.lat] && [leg1.from.lat isEqual:leg2.from.lat]&& [leg1.to.lng isEqual:leg2.to.lng] && [leg1.from.lng isEqual:leg2.from.lng]){
                        [arrayLegs removeObjectAtIndex:l];
                    }
                }
            }
        }
    }
    for(int i=0;i<[arrayLegs count];i++){
        NSMutableArray *arrUnfilteredLegs = [[NSMutableArray alloc] init];
        NSArray *arrayLeg = [arrayLegs objectAtIndex:i];
        for(int j=0;j<[arrayLeg count];j++){
            Leg *leg = [arrayLeg objectAtIndex:j];
            NSMutableDictionary *dictLeg = [[NSMutableDictionary alloc] init];
            if(leg.agencyId){
                [dictLeg setObject:leg.agencyId forKey:@"agencyID"];
            }
            if(leg.agencyName){
                [dictLeg setObject:leg.agencyName forKey:@"agencyName"];
            }
            if(leg.route){
                [dictLeg setObject:leg.route forKey:@"route"];
            }
            if(leg.routeShortName){
                [dictLeg setObject:leg.routeShortName forKey:@"routeShortName"];
            }
            if(leg.routeLongName){
                [dictLeg setObject:leg.routeLongName forKey:@"routeLongName"];
            }
            if(leg.mode){
                [dictLeg setObject:leg.mode forKey:@"mode"];
            }
            if(leg.startTime){
                [dictLeg setObject:leg.startTime forKey:@"startTime"];
            }
            if(leg.endTime){
                [dictLeg setObject:leg.endTime forKey:@"endTime"];
            }
            if(leg.polylineEncodedString){
                [dictLeg setObject:leg.polylineEncodedString.encodedString forKey:@"polyLineEncodedString"];
            }
            if(leg.distance){
                [dictLeg setObject:leg.distance forKey:@"distance"];
            }
            if(leg.duration){
                [dictLeg setObject:leg.duration forKey:@"duration"];
            }
            if(![[leg mode] isEqualToString:@"WALK"]){
                if(leg.to.lat){
                    [dictLeg setObject:leg.to.lat forKey:@"toLat"];
                }
                if(leg.to.lng){
                    [dictLeg setObject:leg.to.lng forKey:@"toLng"];
                }
                if(leg.from.lat){
                    [dictLeg setObject:leg.from.lat forKey:@"fromLat"];
                }
                if(leg.from.lng){
                    [dictLeg setObject:leg.from.lng forKey:@"fromLng"];
                }
            }
            [arrUnfilteredLegs addObject:dictLeg];
        }
        [arrFinalLegs addObject:arrUnfilteredLegs];
    }
    [self checkIfPatternAlreadyExists:arrFinalLegs :toLocation :fromLocation];
}

// Get Schedule From Schedule Table According To TO&From Location.
- (NSArray *)getSchedule:(PlanRequestParameters *)planRequestParameters{
    Location *toLocation = planRequestParameters.toLocation;
    Location *fromLocatin = planRequestParameters.fromLocation;
    NSFetchRequest * fetchTrips = [[NSFetchRequest alloc] init];
    [fetchTrips setEntity:[NSEntityDescription entityForName:@"Schedule" inManagedObjectContext:self.managedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fromLat=%@ && fromLng=%@ && toLat=%@ && toLng = %@",fromLocatin.lat,fromLocatin.lng,toLocation.lat,toLocation.lng];
    [fetchTrips setPredicate:predicate];
    NSArray * arraySchedule = [self.managedObjectContext executeFetchRequest:fetchTrips error:nil];
    return arraySchedule;
}

// Check StopTimes Table for particular tripID&agencyID data is exists or not.
// If Data For tripID&agencyID  Already Exists then we will not ask StopTimes Data for that tripID from Server otherwise we will ask for StopTimes Data.
- (BOOL) checkIfTripIDAndAgencyIDAlreadyExists:(NSString *)strTripID:(NSString *)agencyID{
    NSFetchRequest * fetchTrips = [[NSFetchRequest alloc] init];
    [fetchTrips setEntity:[NSEntityDescription entityForName:@"GtfsStopTimes" inManagedObjectContext:self.managedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"tripID=%@ && agencyID=%@",strTripID,agencyID];
    [fetchTrips setPredicate:predicate];
    NSArray * arrayStopTimes = [self.managedObjectContext executeFetchRequest:fetchTrips error:nil];
    if([arrayStopTimes count] > 0){
        return YES;
    }
    else{
        return NO;
    }
}

// Generate The StopTimes Request Comma Separated string like agencyID_tripID
- (void)generateStopTimesRequestString:(Plan *)plan{
    NSMutableString *strRequestString = [[NSMutableString alloc] init];
    NSArray *itiArray = [plan sortedItineraries];
    for(int i=0;i<[itiArray count];i++){
        Itinerary *iti = [itiArray objectAtIndex:i];
        NSArray *legArray = [iti sortedLegs];
        for(int j=0;j<[legArray count];j++){
            Leg *leg = [legArray objectAtIndex:j];
            if(![[leg mode] isEqualToString:@"WALK"]){
                    if([leg.agencyName isEqualToString:CALTRAIN_AGENCY_NAME]){
                        if(![self checkIfTripIDAndAgencyIDAlreadyExists:leg.tripId:CALTRAIN_AGENCY_IDS]){
                            [strRequestString appendFormat:@"%@_%@,",CALTRAIN_AGENCY_IDS,leg.tripId];
                        }
                    }
                    else if(([leg.agencyName isEqualToString:BART_AGENCY_NAME] ||[leg.agencyName isEqualToString:AIRBART_AGENCY_NAME])){
                        if(![self checkIfTripIDAndAgencyIDAlreadyExists:leg.tripId:BART_AGENCY_ID]){
                            [strRequestString appendFormat:@"%@_%@,",BART_AGENCY_ID,leg.tripId];
                        }
                    }
                    else if([leg.agencyName isEqualToString:SFMUNI_AGENCY_NAME]){
                        if(![self checkIfTripIDAndAgencyIDAlreadyExists:leg.tripId:SFMUNI_AGENCY_ID]){
                            [strRequestString appendFormat:@"%@_%@,",SFMUNI_AGENCY_ID,leg.tripId];
                        }
                    }
                    else if ([leg.agencyName isEqualToString:ACTRANSIT_AGENCY_NAME]){
                        if(![self checkIfTripIDAndAgencyIDAlreadyExists:leg.tripId:ACTRANSIT_AGENCY_ID]){
                            [strRequestString appendFormat:@"%@_%@,",ACTRANSIT_AGENCY_ID,leg.tripId];
                        }
                    }
                }
            }
        }
    if([strRequestString length] > 0){
       [self getGtfsStopTimes:strRequestString]; 
    }
}

// Get The stopID For To&From Location.
- (NSString *) getTheStopIDAccrodingToStation:(NSString *)lat:(NSString *)lng{
    NSFetchRequest * fetchTrips = [[NSFetchRequest alloc] init];
    [fetchTrips setEntity:[NSEntityDescription entityForName:@"GtfsStop" inManagedObjectContext:self.managedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"stopLat=%@ && stopLon=%@",lat,lng];
    [fetchTrips setPredicate:predicate];
    NSArray * arrayStopTimes = [self.managedObjectContext executeFetchRequest:fetchTrips error:nil];
    NSString *strStopID;
    if([arrayStopTimes count] > 0){
        GtfsStop *stop = [arrayStopTimes objectAtIndex:0];
        strStopID = stop.stopID;
    }
    else{
        strStopID = nil;
    }
    return strStopID;
}

// Get The Stop Times Data From StopTimes Table According To To&From stopID.
- (NSArray *)getLegsTimes:(NSString *)strToStopID:(NSString *)strFromStopID:(PlanRequestParameters *)parameters{
    NSFetchRequest * fetchTrips = [[NSFetchRequest alloc] init];
    [fetchTrips setEntity:[NSEntityDescription entityForName:@"GtfsStopTimes" inManagedObjectContext:self.managedObjectContext]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"stopID=%@ || stopID=%@",strToStopID,strFromStopID];
    [fetchTrips setPredicate:predicate];
    NSArray * arrayStopTimes = [self.managedObjectContext executeFetchRequest:fetchTrips error:nil];
    NSMutableArray *arrMutableStopTimes = [[NSMutableArray alloc] init];
    for(int i=0;i<[arrayStopTimes count];i++){
        for(int j= i+1;j<[arrayStopTimes count];j++){
            int hour = 0;
            GtfsStopTimes *stopTimes1 = [arrayStopTimes objectAtIndex:i];
            GtfsStopTimes *stopTimes2 = [arrayStopTimes objectAtIndex:j];
            NSString *strDepartureTime;
            NSArray *arrayDepartureTimeComponents = [stopTimes1.departureTime componentsSeparatedByString:@":"];
            if([arrayDepartureTimeComponents count] > 0){
                int hours = [[arrayDepartureTimeComponents objectAtIndex:0] intValue];
                int minutes = [[arrayDepartureTimeComponents objectAtIndex:1] intValue];
                int seconds = [[arrayDepartureTimeComponents objectAtIndex:2] intValue];
                if(hours > 23){
                    hour = hours;
                    hours = hours - 24;
                }
                strDepartureTime = [NSString stringWithFormat:@"%d:%d:%d",hours,minutes,seconds];
            }
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"HH:mm:ss";
            NSDate *departureDate = [formatter dateFromString:strDepartureTime];
            NSDate *departureTime = timeOnlyFromDate(departureDate);
            NSDate *tripTime = timeOnlyFromDate(parameters.thisRequestTripDate);
            
            NSCalendar *calendarDepartureTime = [NSCalendar currentCalendar];
            NSDateComponents *componentsDepartureTime = [calendarDepartureTime components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:departureTime];
            int hourDepartureTime = [componentsDepartureTime hour];
            int minuteDepartureTime = [componentsDepartureTime minute];
            int intervalDepartureTime = (hour+hourDepartureTime)*60*60 + minuteDepartureTime*60;
            
            NSCalendar *calendarTripTime = [NSCalendar currentCalendar];
            NSDateComponents *componentsTripTime = [calendarTripTime components:(NSHourCalendarUnit | NSMinuteCalendarUnit) fromDate:tripTime];
            int hourTripTime = [componentsTripTime hour];
            int minuteTripTime = [componentsTripTime minute];
            int intervalTripTime = hourTripTime*60*60 + minuteTripTime*60;
            if(stopTimes1 && stopTimes2){
                if([stopTimes1.tripID isEqualToString:stopTimes2.tripID] && [stopTimes2.stopSequence intValue] > [stopTimes1.stopSequence intValue] && intervalDepartureTime >= intervalTripTime){
                    NSArray *arrayTemp = [NSArray arrayWithObjects:stopTimes1,stopTimes2, nil];
                    [arrMutableStopTimes addObject:arrayTemp];
                }
                else if([stopTimes1.tripID isEqualToString:stopTimes2.tripID] && [stopTimes2.stopSequence intValue] < [stopTimes1.stopSequence intValue] && intervalDepartureTime >= intervalTripTime){
                    NSArray *arrayTemp = [NSArray arrayWithObjects:stopTimes2,stopTimes1, nil];
                    [arrMutableStopTimes addObject:arrayTemp];
                }
            }
        }
    }
    return arrMutableStopTimes;
}

// Code To Get Stored Patterns
// Then Get The stopID From To And From Location.
// Then We get The StopTimes According To TO&From stopID.
- (void)getStoredPatterns:(PlanRequestParameters *)parameters{
    NSMutableArray *arrMutableStopTimes = [[NSMutableArray alloc] init];
    NSArray *arraySchedules = [self getSchedule:parameters];
    for(int i=0;i<[arraySchedules count];i++){
        Schedule *schedule = [arraySchedules objectAtIndex:i];
        NSArray *arrayTempSchedule = schedule.legs;
        for(int k=0;k<[arrayTempSchedule count];k++){
            NSArray *legs = [arrayTempSchedule objectAtIndex:k];
            for(int l=0;l<[legs count];l++){
                NSDictionary *dictLeg = [legs objectAtIndex:l];
                if(![[dictLeg objectForKey:@"mode"] isEqualToString:@"WALK"]){
                    NSString *strTOLat = [dictLeg objectForKey:@"toLat"];
                    NSString *strTOLng = [dictLeg objectForKey:@"toLng"];
                    NSString *strFromLat = [dictLeg objectForKey:@"fromLat"];
                    NSString *strFromLng = [dictLeg objectForKey:@"fromLng"];
                    NSString *strTOStopID = [self getTheStopIDAccrodingToStation:strTOLat:strTOLng];
                    NSString *strFromStopID = [self getTheStopIDAccrodingToStation:strFromLat:strFromLng];
                    NSArray *arrStopTimes = [self getLegsTimes:strTOStopID :strFromStopID:parameters];
                    [arrMutableStopTimes addObjectsFromArray:arrStopTimes];
                }
            }
        }
    }
    for(int j = 0; j < [arrMutableStopTimes count]; j++){
        for(int k = j+1;k < [arrMutableStopTimes count];k++){
            if([[arrMutableStopTimes objectAtIndex:j] isEqual:[arrMutableStopTimes objectAtIndex:k]]){
                [arrMutableStopTimes removeObjectAtIndex:k];
            }
        }
    }
}

@end
