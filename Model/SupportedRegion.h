//
//  SupportedRegion.h
//  Nimbler
//
//  Created by Sitanshu Joshi on 5/11/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/Restkit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "PlanRequestChunk.h"
#import "enums.h"

@interface SupportedRegion : NSObject

@property(nonatomic,strong) NSNumber *lowerLeftLatitude;
@property(nonatomic,strong) NSNumber *lowerLeftLongitude;
@property(nonatomic,strong) NSNumber *maxLatitude;
@property(nonatomic,strong) NSNumber *maxLongitude;
@property(nonatomic,strong) NSNumber *minLatitude;
@property(nonatomic,strong) NSNumber *minLongitude;
@property(nonatomic,strong) NSString *transitModes;
@property(nonatomic,strong) NSNumber *upperRightLatitude;
@property(nonatomic,strong) NSNumber *upperRightLongitude;

+ (RKManagedObjectMapping *)objectMappingforRegion:(APIType)apiType;
- (id)initWithDefault;  // loads default min & max supported region values from constants.h file
- (BOOL)isInRegionLat:(double)lat Lng:(double)lng; // Returns true if the given lat/lng are in the supported region
- (CLRegion *)encirclingCLRegion;  // Returns a clRegion that just encircles the supportedRegion
- (MKCoordinateRegion)equivalentMKCoordinateRegion;  // Returns a MKCoordinateRegion which is equivalent to supportedRegion
@end
