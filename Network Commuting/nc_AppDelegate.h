//
//  nc_AppDelegate.h
//  Network Commuting
//
//  Created by John Canfield on 1/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RestKit/Restkit.h>
#import <RestKit/CoreData.h>
#import "ModelDataStore.h"

@interface nc_AppDelegate : UIResponder <UIApplicationDelegate> {
    ModelDataStore *modelDataStore;
}

@property (strong, nonatomic) IBOutlet UIWindow *window;

// Properties for Core Data
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;


- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
