//
//  bayArea.h
//  Nimbler
//
//  Created by JaY Kumbhani on 5/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/Restkit.h>
#import "enums.h"
@interface bayArea : NSObject

@property(nonatomic,strong) NSNumber *lowerLeftLatitude;
@property(nonatomic,strong) NSNumber *lowerLeftLongitude;
@property(nonatomic,strong) NSNumber *maxLatitude;
@property(nonatomic,strong) NSNumber *maxLongitude;
@property(nonatomic,strong) NSNumber *minLatitude;
@property(nonatomic,strong) NSNumber *minLongitude;
@property(nonatomic,strong) NSString *transitModes;
@property(nonatomic,strong) NSNumber *upperRightLatitude;
@property(nonatomic,strong) NSNumber *upperRightLongitude;

+ (RKManagedObjectMapping *)objectMappingforError:(APIType)tpt;
@end