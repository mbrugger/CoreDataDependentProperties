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
//
//- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
//{
//    if ([[observer className] isEqualToString:@"Invoice"])
//    {
////        NSLog(@"customer addObserver: <%p, %@> forKeyPath: %@", observer, [observer className], keyPath);
//    }
//    [super addObserver:observer forKeyPath:keyPath options:options context:context];
//}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
//{
//    NSLog(@"=======================================================");
//    NSLog(@"observe: keyPath: %@ - object: %p %@", keyPath, object, [object className]);
//    NSLog(@"=======================================================");
//
//    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
//}
//- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
//{
//    if (NSSnapshotEventUndoUpdate == flags)
//    {
//        NSLog(@"customer snapshotEvent: %d", (int)flags);
//    }
//	[super awakeFromSnapshotEvents:flags];
//}

@end

