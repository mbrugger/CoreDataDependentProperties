//
//  Customer.m
//  LPAutomatedObserving
//
//  Created by Martin Brugger on 04.10.11.
//  Copyright 2011 Nimblo Softwareentwicklungs OG. All rights reserved.
//

#import "Customer.h"


@implementation Customer

+ (Customer*) insertNewCustomerWithName:(NSString*) newName inManagedObjectContext:(NSManagedObjectContext*) context
{
	Customer *newCustomer = [NSEntityDescription insertNewObjectForEntityForName:@"Customer"
														inManagedObjectContext:context];
	newCustomer.name = newName;
	return newCustomer;
}

+ (NSArray*) findAllCustomersInManagedObjectContext:(NSManagedObjectContext*) context
{
	NSError* error = nil;
	NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"Customer"
														 inManagedObjectContext:context];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	request.entity = entityDescription;
	NSArray *objects = [context executeFetchRequest:request error:&error];
	if (!error)
	{
		return objects;
	}
	return nil;
}

@end

