//
//  TestCoreDataDependentPropertiesContextMerge.m
//  CoreDataDependentPropertiesIOS
//
//  Created by Martin Brugger on 06.10.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TestCoreDataDependentPropertiesContextMerge.h"
#import "Customer.h"
#import "Invoice.h"
#import "LPManagedObjectContext.h"


@implementation TestCoreDataDependentPropertiesContextMerge

- (void)testChangeRelationObjects
{
	Customer* firstCustomer = [Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	Customer* secondCustomer = [Customer insertNewCustomerWithName:@"customer B" inManagedObjectContext:self.context];
    
	Invoice* firstInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:10.0];
    STAssertTrue(firstCustomer.sum.doubleValue == 10.0, @"invoices sum is %@", firstCustomer.sum);
    
    
    // fault first invoice
    NSLog(@"fault first invoice");
    [self.context refreshObject:firstInvoice mergeChanges:NO];
    STAssertTrue([firstInvoice isFault] == YES, @"firstInvoice must be fault");	
    
    NSLog(@"add second invoice");
    Invoice* secondInvoice = [Invoice insertNewInvoiceWithCustomer:secondCustomer inManagedObjectContext:self.context];
	secondInvoice.invoiceSum = [NSNumber numberWithDouble:10.0];
    STAssertTrue(firstCustomer.sum.doubleValue == 10.0, @"invoices sum is %@", firstCustomer.sum);
    
    firstCustomer.invoices = [NSSet setWithObjects:firstInvoice, secondInvoice, nil];
    
    NSLog(@"firstInvoice observers: %@", [firstInvoice observationInfo]);
    STAssertTrue([firstInvoice isFault] == YES, @"firstInvoice must be fault");	
    STAssertTrue([firstInvoice observationInfo] == nil, @"object must not be observed while faulted %@", [firstInvoice observationInfo]);
}

- (void)testContextMerge
{
    NSError *error = nil;
	Customer* firstCustomer = [Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	Invoice* firstInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:10.0];
	Invoice* secondInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];
	secondInvoice.invoiceSum = [NSNumber numberWithDouble:10.0];
	
	STAssertTrue(firstCustomer.sum.doubleValue == 20.0, @"invoices sum is %@", firstCustomer.sum);
	@try
	{
		BOOL success = [self.context save:&error];	
		STAssertTrue(success == YES, @"error could not save changes");
	}
	@catch (NSException * e)
	{
		STAssertTrue(e == nil, @"error - %@", e);
	}
    
    //[self.context reset];
    NSLog(@"XX fault invoices");
	[self.context refreshObject:firstInvoice mergeChanges:NO];
	[self.context refreshObject:secondInvoice mergeChanges:NO];
    NSLog(@"XX fault invoices done");
    
    STAssertTrue([firstInvoice isFault] == YES, @"firstInvoice must be fault");	
	STAssertTrue([secondInvoice isFault] == YES, @"secondInvoice must be fault");
    
    
    // create new context for inserting invoice
    LPManagedObjectContext *insertContext = [[LPManagedObjectContext alloc] init];
    insertContext.persistentStoreCoordinator = self.context.persistentStoreCoordinator;
    [insertContext prepareDependentProperties];	
    NSLog(@"XX load customer");
	Customer *fetchedCustomer = [Customer findAllCustomersInManagedObjectContext:insertContext].lastObject;
	STAssertTrue(fetchedCustomer != nil, @"fetched customer missing");
	STAssertTrue(fetchedCustomer.sum.doubleValue == 20.0, @"fetchedCustomer sum not loaded correctly %@", fetchedCustomer);
	STAssertTrue(fetchedCustomer.invoices.count == 2, @"fetchedCustomer.invoices %@", fetchedCustomer.invoices);
    
    Invoice *thirdInvoice = [Invoice insertNewInvoiceWithCustomer:fetchedCustomer inManagedObjectContext:insertContext];
	thirdInvoice.invoiceSum = [NSNumber numberWithDouble:10.0];
    
	STAssertTrue(fetchedCustomer.sum.doubleValue == 30.0, @"invoices sum is %@", fetchedCustomer.sum);
    
    // save and merge contexts
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeChanges:) name:NSManagedObjectContextDidSaveNotification object:insertContext];
    @try
	{
        NSLog(@"XX save insert context");
		BOOL success = [insertContext save:&error];	
		STAssertTrue(success == YES, @"error could not save changes");
	}
	@catch (NSException * e)
	{
		STAssertTrue(e == nil, @"error - %@", e);
	}
    NSLog(@"XX DONE");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:insertContext];
    
    fetchedCustomer = [Customer findAllCustomersInManagedObjectContext:self.context].lastObject;
    STAssertTrue([firstInvoice isFault] == YES, @"firstInvoice must be fault");	
	STAssertTrue([secondInvoice isFault] == YES, @"secondInvoice must be fault");
    STAssertTrue(fetchedCustomer.sum.doubleValue == 30.0, @"invoices sum is %@", fetchedCustomer.sum);
    
    [insertContext release];
}

- (void)mergeChanges:(NSNotification *)notification
{
    NSLog(@"XX merge changes to main context");
    [self.context mergeChangesFromContextDidSaveNotification:notification];
}


@end
