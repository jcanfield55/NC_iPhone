//
//  Locations.m
//  Network Commuting
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "Location.h"


@implementation Location

@dynamic apiType;
@dynamic geoCoderStatus;
@dynamic types;
@dynamic formattedAddress;
@dynamic addressComponents;
@synthesize latLng;
@dynamic locationType;
@dynamic viewPort;
@dynamic toFrequency;
@dynamic fromFrequency;
@dynamic nickName;

+ (RKObjectMapping *)objectMappingForApi:(APIType)gt;
{
    // Create empty ObjectMapping to fill and return
    RKObjectMapping* locationMapping = [RKObjectMapping mappingForClass:[Location class]];
    
    // Call on sub-objects for their Object Mappings
    RKObjectMapping* addrCompMapping = [AddressComponent objectMappingForApi:gt];
    RKObjectMapping* latLngMapping = [LatLng objectMappingForApi:gt];
    RKObjectMapping* geoRectMapping = [GeoRectangle objectMappingForApi:gt];
    
    // Make the mappings
    if (gt==GOOGLE_GEOCODER) {
        [locationMapping mapKeyPath:@"types" toAttribute:@"types"];
        [locationMapping mapKeyPath:@"formatted_address" toAttribute:@"formattedAddress"];
        [locationMapping mapKeyPath:@"address_components" toRelationship:@"addressComponents" 
                        withMapping:addrCompMapping];
        [locationMapping mapKeyPath:@"geometry.location" toRelationship:@"latLng" 
                        withMapping:latLngMapping];
        [locationMapping mapKeyPath:@"geometry.location_type" toAttribute:@"locationType"];
        [locationMapping mapKeyPath:@"geometry.viewport" toRelationship:@"viewPort" 
                        withMapping:geoRectMapping];

    }
    else {
        // TODO Unknown geocoder type, throw an exception
    }
    return locationMapping;
}

// TODO Delete this commented method
/*
- (id)init
{
    self = [super init];
    rawAddresses = [[NSMutableSet alloc] init];
    
    return self;
} */

- (bool)isMatchingRawAddress:(NSString *)rawAddr
{
    return ([rawAddresses member:rawAddr] != nil);
}

- (void)addRawAddress:(NSString *)rawAddr
{
    [rawAddresses addObject:rawAddr];
}

// Convenience method for flattening lat/lng properties
- (double)lat {
    return [latLng lat];
}

// Convenience method for flattening lat/lng properties
- (double)lng {
    return [latLng lng];
}

// Convenience method for flattening lat/lng properties
- (void)setLat:(double)lat {
    if (!latLng) {   // if latLng does not exist, create it
        latLng = [[LatLng alloc] init];
    }
    [latLng setLat:lat];   // set the lat property
}

// Convenience method for flattening lat/lng properties
- (void)setLng:(double)lng {
    if (!latLng) {   // if latLng does not exist, create it
        latLng = [[LatLng alloc] init];
    }
    [latLng setLng:lng];
}

- (void)incrementToFrequency {
    toFrequency++;
}

- (void)incrementFromFrequency {
    fromFrequency++;
}

// Method to see whether two locations are effectively equivalent
// If they have the exact same formatted address, or they are within ~0.05 miles 
// For example, it is 233 feet between 1350 and 1315 Hull Drive
// 1350 Hull Lat: 37.510594; Lng: -122.268646;
// 1315 Hull Lat: 37.510811; Lng: -122.267816; 
// Difference is ~0.0008.  Rather than compute exact distince, simply use a surrounding box calculation
- (bool)isEquivalent:(Location *)loc2
{
    if ([formattedAddress isEqualToString:[loc2 formattedAddress]]) {
        return true;
    }
    float lat2 = [[loc2 latLng] lat];
    float lng2 = [[loc2 latLng] lng];
    if ((fabs([latLng lat] - lat2) < 0.0008) && (fabs([latLng lng] - lng2) < 0.0008)) {
        return true;
    }
    else
        return false;
}

- (NSString *)description
{
    NSString* desc = [NSString stringWithFormat:
                      @"{Location Object:  apiType: %d;  rawAddresses: %@;  geoCoderStatus: %@;  types: %@;  formatted address: %@;  addressComponents: %@;  latLng: %@;  locationType: %@;  viewPort: %@;  toFrequency %d;  fromFrequency %d;  nickName: %@}",
                      apiType, rawAddresses, geoCoderStatus, types, formattedAddress, addressComponents, 
                      latLng, locationType, viewPort, toFrequency, fromFrequency, nickName];
    return desc;
}
@end
