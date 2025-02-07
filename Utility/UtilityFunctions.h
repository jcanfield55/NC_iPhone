//
//  UtilityFunctions.h
//  Nimbler World, Inc.
//
//  Created by John Canfield on 2/7/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h> 
#import <CoreLocation/CoreLocation.h>
#import "Leg.h"

NSString *pathInDocumentDirectory(NSString *fileName);

void saveContext(NSManagedObjectContext *managedObjectContext);

// Handy debugging function for sending the character-by-character unicode of a string to NSLog
void stringToUnicodeNSLog(NSString *string);

// Converts from milliseconds to a string formatted as "X days, Y hours, Z minutes"
NSString *durationString(double milliseconds);

// Converts from meters to a string in either miles or feed
NSString *distanceStringInMilesFeet(double meters);

NSDateFormatter *utilitiesShortTimeFormatter(void);
NSString *superShortTimeStringForDate(NSDate *date);

// Returns a NSDate object containing just the time of the date parameter.
NSDate *timeOnlyFromDate(NSDate *date);

// Returns a NSString containing just the time of the date parameter in the format HH:mm:ss
NSString *timeStringFromDate(NSDate *date);

// Assumes that the receiver is a timeString of format HH:mm:ss
// Returns a new timeString of the same format but with a value from adding interval (in seconds)
// Note: this will go past 24 hours (i.e. 25:30 represents 1:30am the next day).
NSString *timeStringByAddingInterval(NSString *timeString, NSTimeInterval interval);
    
// Returns a NSDate object containing just the date part of the date parameter (not the time)
// Equivalent to using [NSCalendar currentCalendar] and the month, day, and year components to compute
NSDate *dateOnlyFromDate(NSDate *date);

// Retrieves the day of week from the date (Sunday = 1, Saturday = 7)
NSInteger dayOfWeekFromDate(NSDate *date);

// Returns a date where the date components are taken from dateOnly, and the time components are
// taken from timeOnly
// Mostly should not be used (use addDateOnlyWithTime for proper overnight treatments per GTFS standard)
NSDate *addDateOnlyWithTimeOnly(NSDate *dateOnly, NSDate *timeOnly);

// Returns a date where the date components are taken from dateOnly, and this is added to time
// timeOnly is assumed to have originated from a timeOnly value, but may have a value that passes midnight
// (for example [itinerary startTimeOnly] value)
NSDate *addDateOnlyWithTime(NSDate *date, NSDate *timeOnly);

// Return date with time from time string like (10:45:00).
// Also handles times like 24:30 (by adding a day) for overnight trips per the GTFS standard
// This function should be used with addDateOnlyWithTime() function
NSDate *dateFromTimeString(NSString *strTime);

//
// Returns a string that is a truncated version of string that fits within
// width using font
//
NSString *stringByTruncatingToWidth(NSString *string, CGFloat width, UIFont *font);

//
// Logs event to Flurry (and any other logging)
// Can accept up to 4 parameter names and value pairs.  If  the parameter name is nil, that parameter is not included in the log
// If the parameter value is nil, then the string @"nil" is written in the log instead
//
void logEvent(NSString *eventName, NSString *param1name, NSString *param1value, NSString *param2name, NSString* param2value,
              NSString *param3name, NSString *param3value, NSString *param4name, NSString *param4value);

// Logs exception using NIMLOG_ERR1 and if Flurry activated, logs to Flurry as well
void logException(NSString *errorName, NSString *errorMessage, NSException *e);

// Logs errors using NIMLOG_ERR1 and if Flurry activated, logs to Flurry as well
void logError(NSString *errorName, NSString *errorMessage);

// Handles and logs uncaught exceptions
void uncaughtExceptionHandler(NSException *exception);
float calculateLevenshteinDistance(NSString *originalString,NSString *comparisonString);
NSInteger smallestOf3(NSInteger a,NSInteger b,NSInteger c);
NSInteger smallestOf2(NSInteger a,NSInteger b);

//Calculate Distance Between Two Location
CLLocationDistance distanceBetweenTwoLocation(CLLocation *toLocation,CLLocation *fromLocation);


// Get AgencyId from Agencyname
NSString *agencyFeedIdFromAgencyName(NSString *agencyName);

// Get AgencyName from AgencyId
NSString *agencyNameFromAgencyFeedId(NSString *agencyId);

// return the string at specific index from array if exists else return empty string.
NSString *getItemAtIndexFromArray(int index,NSArray *arrayComponents);

int timeIntervalFromDate(NSDate * date);

// generate 16 character random string
NSString *generateRandomString(int length);

// return the image from document directory or from server
// First check if image exist at document directory folder if yes then take image from document directory otherwise request server for image and save image to document directory and next time use image from document directory.
UIImage *getAgencyIcon(NSString * imageName);

NSString *returnShortAgencyName(NSString *agencyName);

NSString *returnRouteTypeFromLegMode(NSString *legMode);

int timeIntervalFromTimeString(NSString *strTime);

NSData* compressData(NSData* uncompressedData);
NSData* uncompressGZip(NSData* compressedData);

NSString *returnBikeButtonTitle(void);

NSString *containsListFromFormattedAddress(NSString *formattedAddress);

UIImage *returnNavigationBarBackgroundImage(void);

// Takes a NSObject, object, of unknown type and returns a NSNumber if possible.
// If object is a NSNumber, returns that.
// If object is a NSString, converts string to a number if possible using a doubleValue.
// NSString objects with non-numberic values will return a NSNumber with value = 0
// If object is nil or any other type, returns nil.
NSNumber *NSNumberFromNSObject(NSObject *object);

// Takes a NSObject, object, of unknown type and returns an NSString if possible.
// If object is nil or any other type, returns nil.
NSString *NSStringFromNSObject(NSObject *object);