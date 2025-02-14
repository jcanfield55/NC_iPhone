//
//  TransitCalendar.m
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/21/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//
// This class stores transit calendars for various agencies and does matching on whether a cached transit
// request would have the same schedule as a new request

#import "TransitCalendar.h"
#import "UtilityFunctions.h"
#import "KeyObjectStore.h"
#import "nc_AppDelegate.h"

@interface TransitCalendar() {

}

-(void)loadServiceByWeekday;
-(void)loadCalendarByDate;


@end

@implementation TransitCalendar

@synthesize rkTpClient;
@synthesize lastGTFSLoadDateByAgency;
@synthesize calendarByDateByAgency;
@synthesize serviceByWeekdayByAgency;

@synthesize testCalendarByDateByAgency;
@synthesize testLastGTFSLoadDateByAgency;
@synthesize testServiceByWeekdayByAgency;

static TransitCalendar * transitCalendarSingleton;
static NSDateFormatter* dateOnlyFormatter;  // dateFormatter with pattern @"YYYMMdd"


// returns the singleton value.  
+ (TransitCalendar *)transitCalendar
{
    if (!transitCalendarSingleton) {
        transitCalendarSingleton = [[TransitCalendar alloc] init];
    }
    return transitCalendarSingleton;
}

// requests transitCalendar information from server, starting with last update time, but continuing with all other values if needed
- (void)updateFromServer
{
    NSString *request = [UPDATE_TIME_URL appendQueryParams:nil];
    NIMLOG_EVENT1(@"updateTime req: %@", request);
    [rkTpClient get:request delegate:self];
}


-(void)loadServiceByWeekday{
    @try {
        NSString *serviceByWeekdayReq = [SERVICE_BY_WEEKDAY_URL appendQueryParams:nil];
        NIMLOG_EVENT1(@"Service By Weekday req: %@", serviceByWeekdayReq);
        [rkTpClient get:serviceByWeekdayReq delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->serviceByWeekday", @"", exception);    }
}


-(void)loadCalendarByDate{
    @try {
        NSString *request = [CALENDAR_BY_DATE_URL appendQueryParams:nil];
        NIMLOG_EVENT1(@"Calendar By Date req: %@", request);
        [rkTpClient  get:request delegate:self];
    }
    @catch (NSException *exception) {
        logException(@"ncAppDelegate->calendarByDate", @"", exception);
    }
}

// Accessor override to populate this dictionary if not already there
- (NSDictionary *)lastGTFSLoadDateByAgency
{
    if (!lastGTFSLoadDateByAgency) {
        // See if it is the KeyObjectStore
        KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
        lastGTFSLoadDateByAgency = [keyObjectStore objectForKey:TR_CALENDAR_LAST_GTFS_LOAD_DATE_BY_AGENCY];
        // if (!lastGTFSLoadDateByAgency) {
        // // use stub function to get values -- change this once have server call
        // [self updateTime];
        // //[self getAgencyCalendarDataStub];
        // //[keyObjectStore setObject:lastGTFSLoadDateByAgency forKey:TR_CALENDAR_LAST_GTFS_LOAD_DATE_BY_AGENCY];
    }
    // }
    return lastGTFSLoadDateByAgency;
}

// RestKit callback with server results
- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response
{
    @try {
        NSError *error = nil;
        if (error == nil) {
            RKJSONParserJSONKit* rkParser = [RKJSONParserJSONKit new];
            NSDictionary *tempResponseDictionary = [rkParser objectFromString:[response bodyAsString] error:nil];
            if([tempResponseDictionary objectForKey:GTFS_UPDATE_TIME] != nil ){
                [[NSUserDefaults standardUserDefaults] setObject:dateOnlyFromDate([NSDate date]) forKey:CURRENT_DATE];
                [[NSUserDefaults standardUserDefaults] synchronize];
                NIMLOG_EVENT1(@"Loaded TR_CALENDAR_LAST_GTFS_LOAD_DATE_BY_AGENCY");
                 KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
                lastGTFSLoadDateByAgency = [keyObjectStore objectForKey:TR_CALENDAR_LAST_GTFS_LOAD_DATE_BY_AGENCY];
                if(!lastGTFSLoadDateByAgency){
                    lastGTFSLoadDateByAgency = tempResponseDictionary;
                    KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
                    [keyObjectStore setObject:lastGTFSLoadDateByAgency forKey:TR_CALENDAR_LAST_GTFS_LOAD_DATE_BY_AGENCY];
                    [self loadServiceByWeekday];
                }
                else if(![lastGTFSLoadDateByAgency isEqualToDictionary: tempResponseDictionary]){
                    lastGTFSLoadDateByAgency = tempResponseDictionary;
                    KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
                    [keyObjectStore setObject:lastGTFSLoadDateByAgency forKey:TR_CALENDAR_LAST_GTFS_LOAD_DATE_BY_AGENCY];
                    [self loadServiceByWeekday];
                }
            }
            else if([tempResponseDictionary objectForKey:GTFS_SERVICE_BY_WEEKDAY] != nil){
                NIMLOG_EVENT1(@"Loaded TR_CALENDAR_SERVICE_BY_WEEKDAY_BY_AGENCY");
                serviceByWeekdayByAgency = tempResponseDictionary;
                KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
                [keyObjectStore setObject:serviceByWeekdayByAgency forKey:TR_CALENDAR_SERVICE_BY_WEEKDAY_BY_AGENCY ];
                [self loadCalendarByDate];
            }
            else if([tempResponseDictionary objectForKey:GTFS_SERVICE_EXCEPTIONS_DATES] != nil){
                NIMLOG_EVENT1(@"Loaded TR_CALENDAR_BY_DATE_BY_AGENCY");
                // Note:- Uncomment this line when using seed Database
           #if GENERATING_SEED_DATABASE
                [[nc_AppDelegate sharedInstance].gtfsParser removeAllTripsAndStopTimesData];
                [[nc_AppDelegate sharedInstance].gtfsParser requestStopsDataFromServer];
           #endif
                if(calendarByDateByAgency){
                    [[nc_AppDelegate sharedInstance].gtfsParser removeAllTripsAndStopTimesData];
                    [[nc_AppDelegate sharedInstance].gtfsParser requestStopsDataFromServer];
                }
                calendarByDateByAgency = tempResponseDictionary;
                KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
                [keyObjectStore setObject:calendarByDateByAgency forKey:TR_CALENDAR_BY_DATE_BY_AGENCY];
            }
        }
    }
    @catch (NSException *exception) {
        logException(@"TransitCalendar->didLoadResponse", @"catching TPServer Response", exception);
    }
}


- (NSDictionary *)calendarByDateByAgency
{
    if (!calendarByDateByAgency) {
        // // See if it is the KeyObjectStore
        KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
        calendarByDateByAgency = [keyObjectStore objectForKey:TR_CALENDAR_BY_DATE_BY_AGENCY ];
    }
    return calendarByDateByAgency;
}

- (NSDictionary *)serviceByWeekdayByAgency
{
    if (!serviceByWeekdayByAgency) {
        // // See if it is the KeyObjectStore
        KeyObjectStore* keyObjectStore = [KeyObjectStore keyObjectStore];
        serviceByWeekdayByAgency = [keyObjectStore objectForKey:TR_CALENDAR_SERVICE_BY_WEEKDAY_BY_AGENCY];
        // if (!serviceByWeekdayByAgency) {
        // // use stub function to get values -- change this once have server call
        // [self serviceByWeekday];
        // [keyObjectStore setObject:serviceByWeekdayByAgency forKey:TR_CALENDAR_SERVICE_BY_WEEKDAY_BY_AGENCY ];
    }
    // }
    return serviceByWeekdayByAgency;
}


//
// Returns true if the provided date comes after the last GTFS update for given agencyId
//
- (BOOL)isCurrentVsGtfsFileFor:(NSDate *)date agencyId:(NSString *)agencyId
{
    //NSDate* gtfsLoadDate = [[self lastGTFSLoadDateByAgency] objectForKey:agencyId];
    NSString *gtfsLoadDate = [[[self lastGTFSLoadDateByAgency] objectForKey:GTFS_UPDATE_TIME]objectForKey:agencyId];
    if (!dateOnlyFormatter) {
        dateOnlyFormatter = [[NSDateFormatter alloc] init];
        [dateOnlyFormatter setDateFormat:@"YYYMMdd"];
    }
    NSString* strDateOnly = [dateOnlyFormatter stringFromDate:date];
    if (gtfsLoadDate && [strDateOnly compare:gtfsLoadDate] == NSOrderedDescending) {
        // If dates come after the gtfsLoadDate, then return true
        return true;
    } else {
        return false;
    }
}

// Returns the agency-specific services string for the given date and agency
- (NSString *)serviceStringForDate:(NSDate *)date agencyId:(NSString *)agencyId
{
    NSInteger dayOfWeek = dayOfWeekFromDate(date)-1;
    if (!dateOnlyFormatter) {
        dateOnlyFormatter = [[NSDateFormatter alloc] init];
        [dateOnlyFormatter setDateFormat:@"YYYMMdd"];
    }
    NSString* strDateOnly = [dateOnlyFormatter stringFromDate:date];
    
    // Get the weekday services code
    NSString* dateServices;
    NSString* dateServiceExemption;
    // dateServices = [[[self serviceByWeekdayByAgency] objectForKey:agencyId] objectAtIndex:dayOfWeek];
    dateServices = [[[[self serviceByWeekdayByAgency] objectForKey:GTFS_SERVICE_BY_WEEKDAY] objectForKey:agencyId]objectAtIndex:dayOfWeek];
    
    dateServiceExemption = [[[[self calendarByDateByAgency] objectForKey:GTFS_SERVICE_EXCEPTIONS_DATES] objectForKey:agencyId] objectForKey:strDateOnly];
    
    // Look for exceptions in the calendarDates Dictionary and refine as needed
    if (dateServiceExemption) {
        dateServices = dateServiceExemption;
    }
    return dateServices;
}

//
// Returns true if the two dates have equivalent service schedule based on:
// - day of the week and calendar.txt GTFS file for the given agencyId
// - any exceptions in calendar_dates.txt GTFS file for the given agencyId
// Otherwise returns false
//
- (BOOL)isEquivalentServiceDayFor:(NSDate *)date1 And:(NSDate *)date2 agencyId:(NSString *)agencyId
{
    NSString* date1Services = [self serviceStringForDate:date1 agencyId:agencyId];
    NSString* date2Services = [self serviceStringForDate:date2 agencyId:agencyId];
    
    return (date1Services && date2Services && [date1Services isEqualToString:date2Services]);
}

//
// Stub for filling in the trip information
// TODO -- replace this stubs with logic to load periodically from server
//

- (void)getAgencyCalendarDataStub
{
    NSArray* agencyIDs = [NSArray arrayWithObjects:
                          @"VTA", @"SFMTA", @"BART", @"AirBART", @"AC Transit",
                          CALTRAIN_AGENCY_ID, nil];
    NSMutableDictionary* lastGTFSLoadDateMutable = [[NSMutableDictionary alloc] initWithCapacity:[agencyIDs count]];
    NSMutableDictionary* serviceByWeekdayMutable = [[NSMutableDictionary alloc] initWithCapacity:[agencyIDs count]];
    NSMutableDictionary* calendarByDateMutable = [[NSMutableDictionary alloc] initWithCapacity:[agencyIDs count]];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    
    //NSDate* loadDate = [dateFormatter dateFromString:@"07112012"];  // Last Caltrain load time
   // NSDate* laborDay = [dateFormatter dateFromString:@"September 3, 2012"];
    NSString *loadDate = @"20120711";
    NSString *laborDay = @"20120903";
    for (NSString* agencyID in agencyIDs) {
        [lastGTFSLoadDateMutable setObject:loadDate forKey:agencyID];
        
        // Indicate different services for weekdays, Saturdays and Sundays
        NSArray* serviceByWeekday = [NSArray arrayWithObjects:@"Sunday", @"Weekday",
                                     @"Weekday", @"Weekday", @"Weekday", @"Weekday", @"Saturday", nil];
        NSArray* ACTransitServiceByWeekday = [NSArray arrayWithObjects:@"Sunday", @"Monday",
                                              @"Tuesday", @"Wednesday", @"Thursday", @"Friday", @"Saturday", nil];
        if ([agencyID isEqualToString:@"AC Transit"]) {
            [serviceByWeekdayMutable setObject:ACTransitServiceByWeekday forKey:agencyID];
        } else {
            [serviceByWeekdayMutable setObject:serviceByWeekday forKey:agencyID];
        }
        
        NSDictionary* calendarByDate = [NSDictionary dictionaryWithObjectsAndKeys:
                                        @"Sunday", laborDay, nil];  // Give Sunday schedule on Labor Day
        [calendarByDateMutable setObject:calendarByDate forKey:agencyID];
    }
    NSDictionary *dictlastGTFSLoadDateMutable = [NSDictionary dictionaryWithObject:lastGTFSLoadDateMutable forKey:GTFS_UPDATE_TIME];
    NIMLOG_EVENT1(@"dictlastGTFSLoadDateMutable=%@",dictlastGTFSLoadDateMutable);
    NSDictionary *dictServiceByWeekdayMutable = [NSDictionary dictionaryWithObject:serviceByWeekdayMutable forKey:GTFS_SERVICE_BY_WEEKDAY];
    NSDictionary *dictCalendarByDateMutable = [NSDictionary dictionaryWithObject:calendarByDateMutable forKey:GTFS_SERVICE_EXCEPTIONS_DATES];
    testLastGTFSLoadDateByAgency = dictlastGTFSLoadDateMutable;
    testServiceByWeekdayByAgency = dictServiceByWeekdayMutable;
    testCalendarByDateByAgency = dictCalendarByDateMutable;
    
//    [nc_AppDelegate sharedInstance].lastGTFSLoadDateByAgency = lastGTFSLoadDateMutable;
//    [nc_AppDelegate sharedInstance].serviceByWeekdayByAgency = serviceByWeekdayMutable;
//    [nc_AppDelegate sharedInstance].calendarByDateByAgency = calendarByDateMutable;
}



@end
