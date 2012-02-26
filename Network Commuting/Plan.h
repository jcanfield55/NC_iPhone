//
//  Plan.h
//  Network Commuting
//
//  Created by John Canfield on 1/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/Restkit.h>
#import "PlanPlace.h"
#import "Itinerary.h"
#import "Location.h"
#import "enums.h"

@interface Plan : NSManagedObject

@property(nonatomic, strong) NSDate *date;
@property(nonatomic,strong) PlanPlace *fromPlanPlace;
@property(nonatomic,strong) PlanPlace *toPlanPlace;
@property(nonatomic,strong) NSSet *itineraries;
@property(nonatomic,strong) Location *fromLocation;
@property(nonatomic,strong) Location *toLocation;
@property(nonatomic,strong) NSArray *sortedItineraries;  // Array of ordered itineraries (not stored in Core Data)

+ (RKManagedObjectMapping *)objectMappingforPlanner:(APIType)tpt;
- (NSString *)ncDescription;
- (void)sortItineraries;  // Re-sorts the itineraries array
@end
