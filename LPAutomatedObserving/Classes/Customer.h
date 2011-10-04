//
//  Customer.h
//  LPAutomatedObserving
//
//  Created by Martin Brugger on 04.10.11.
//  Copyright 2011 Nimblo Softwareentwicklungs OG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Person.h"

@interface Customer : Person {

}

+ (Customer*) insertNewCustomerWithName:(NSString*) newName inManagedObjectContext:(NSManagedObjectContext*) context;
+ (NSArray*) findAllCustomersInManagedObjectContext:(NSManagedObjectContext*) context;


@end
