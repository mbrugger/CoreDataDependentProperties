//
//  AppDelegate_Shared.h
//  iosmini2
//
//  Created by Martin Brugger on 04.10.11.
//  Copyright 2011 Nimblo Softwareentwicklungs OG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "LPManagedObjectContext.h"

@interface AppDelegate_Shared : NSObject <UIApplicationDelegate> {
    
    UIWindow *window;
    
@private
    NSManagedObjectContext *managedObjectContext_;
    NSManagedObjectModel *managedObjectModel_;
    NSPersistentStoreCoordinator *persistentStoreCoordinator_;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain, readonly) LPManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory;
- (void)saveContext;

@end

