//
//  TransitCalendar.h
//  Nimbler Caltrain
//
//  Created by John Canfield on 8/21/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//
//
// This singleton class stores transit calendars for various agencies and does matching on whether a cached transit
// request would have the same schedule as a new request

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>

@interface TransitCalendar : NSObject<RKRequestDelegate>

@property(strong, nonatomic) RKClient* rkTpClient;   // RestKit client for TP Server

// lastGTFSLoadDateByAgency -- dictionary
// Dictionary where key is agencyID string and object is NSDate* of last time that agency was updated
@property(strong, nonatomic) NSDictionary* lastGTFSLoadDateByAgency;

// serviceByWeekendArray -- a Dictionary of arrays
// Dictionary key is agencyID string and object is an NSArray
// Each array is 7 long and contains NSString describing the services available for that day
@property(strong, nonatomic) NSDictionary* serviceByWeekdayByAgency;

// calendarByDateByAgency -- a Dictionary of dictionaries
// First dictionary key is agencyID string, object is a dictionary
// The embedded dictionary key is an NSDate containing just the mm/dd/yy (not time) of a date
//   The returned object is a string describing the services available for that day
@property(strong, nonatomic) NSDictionary* calendarByDateByAgency;


// Added for Automation Tests

@property(strong, nonatomic) NSDictionary* testLastGTFSLoadDateByAgency;
@property(strong, nonatomic) NSDictionary* testServiceByWeekdayByAgency;
@property(strong, nonatomic) NSDictionary* testCalendarByDateByAgency;
//
// Methods
//

// returns the singleton value.
+ (TransitCalendar *)transitCalendar;

// requests transitCalendar information from server
- (void)updateFromServer;

//
// Returns true if the provided date comes after the last GTFS update for given agencyId
//
- (BOOL)isCurrentVsGtfsFileFor:(NSDate *)date agencyId:(NSString *)agencyId;

// Returns the agency-specific services string for the given date and agency
- (NSString *)serviceStringForDate:(NSDate *)date agencyId:(NSString *)agencyId;

//
// Returns true if the two dates have equivalent service schedule based on:
//   - day of the week and calendar.txt GTFS file for the given agencyId
//   - any exceptions in calendar_dates.txt GTFS file for the given agencyId
// Otherwise returns false
//
- (BOOL)isEquivalentServiceDayFor:(NSDate *)date1 And:(NSDate *)date2 agencyId:(NSString *)agencyId;

// Stub data fill function.  For testing purposes
- (void)getAgencyCalendarDataStub;

@end
