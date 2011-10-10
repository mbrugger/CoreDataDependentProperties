//
//  DetailViewController.h
//  CoreDataDependentPropertiesIOS
//
//  Created by Martin Brugger on 10.10.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LPManagedObjectContext;
@interface DetailViewController : UIViewController {
    
}

@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) LPManagedObjectContext *editContext;


- (void)doneAction;
- (void)cancelAction;

@end
