//
//  TestCoreDataDependentPropertiesUndoManager.m
//  CoreDataDependentPropertiesMac
//
//  Created by Martin Brugger on 06.10.11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TestCoreDataDependentPropertiesUndoManager.h"
#import "Customer.h"
#import "Invoice.h"

@implementation TestCoreDataDependentPropertiesUndoManager

- (void)testUndoDelete
{
	// begin undo grouping
	// create customer
	// create 2 invoices
	// delete customer
	// end undo grouping
	// undo operation
	// check for observings
	
	STAssertTrue([self.context.undoManager canUndo] == NO, @"undoManager canUndo");
	STAssertTrue([[self.context undoManager] isUndoRegistrationEnabled] == YES, @"undoRegistration %d", [[self.context undoManager] isUndoRegistrationEnabled]);
	observerCount = 0;
	
	
	Customer* firstCustomer = [Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	STAssertTrue(firstCustomer.sum.doubleValue == 0.0, @"customer without invoices should have zero sum");
	
	[firstCustomer addObserver:self 
					forKeyPath:@"sum" 
					   options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)  
					   context:@"UnitTest"];
	
	Invoice* firstInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];		
	// change invoice sum
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:1.0];
	STAssertTrue(firstCustomer.sum.doubleValue == 1.0, @"customer with invoices sum %@", firstCustomer.sum);
	STAssertTrue(observerCount == 1, @"observer count %d", observerCount);
	
	Invoice* secondInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];	
	
	// change invoice sum
	secondInvoice.invoiceSum = [NSNumber numberWithDouble:1.0];
	STAssertTrue(firstCustomer.sum.doubleValue == 2.0, @"customer with invoices sum %@", firstCustomer.sum);
	STAssertTrue(observerCount == 2, @"observer count %d", observerCount);
	
	NSLog(@"insertedObjects: %@", [self.context insertedObjects]);
	
	[firstCustomer removeObserver:self forKeyPath:@"sum"];
	
	
	// create undo group for delete operation
	[self.context processPendingChanges];
	
	[[self.context undoManager] setActionName:@"initialOperations"];
	[[self.context undoManager] endUndoGrouping];
	
	
	
	STAssertTrue([[self.context.undoManager undoMenuItemTitle] isEqualToString:@"Undo initialOperations"], @"undoName - %@",[self.context.undoManager undoMenuItemTitle]);
	
	[self.context processPendingChanges];
	[[self.context undoManager] beginUndoGrouping];
	[[self.context undoManager] setActionName:@"delete"];
	
	[self.context deleteObject:firstCustomer];
	[self.context processPendingChanges];
	[[self.context undoManager] endUndoGrouping];
	
	
	NSArray* allCustomers = [Customer findAllCustomersInManagedObjectContext:self.context];
	STAssertTrue(allCustomers.count == 0, @"all customers deleted %@", allCustomers);
	
	STAssertTrue([[self.context.undoManager undoMenuItemTitle] isEqualToString:@"Undo delete"], @"undoName - %@",[self.context.undoManager undoMenuItemTitle]);
	[[self.context undoManager] undo];
	
	STAssertTrue([[self.context.undoManager undoMenuItemTitle] isEqualToString:@"Undo initialOperations"], @"undoName - %@",[self.context.undoManager undoMenuItemTitle]);
	
	
	// test for value change
	[self.context processPendingChanges];
	[[self.context undoManager] beginUndoGrouping];
	
	[[self.context undoManager] setActionName:@"change"];
	
	allCustomers = [Customer findAllCustomersInManagedObjectContext:self.context];
	STAssertTrue(allCustomers.count == 1, @"customer undelete failed %d", allCustomers.count);
	
	//check if observings still work
	observerCount = 0;
	Customer* undeletedCustomer = [allCustomers lastObject];
	[undeletedCustomer addObserver:self 
						forKeyPath:@"sum" 
						   options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)  
						   context:@"UnitTest"];
	
	Invoice* undeletedInvoice = [undeletedCustomer.invoices anyObject];
	undeletedInvoice.invoiceSum = [NSNumber numberWithDouble:33.33];
	
	[self.context processPendingChanges];
	[[self.context undoManager] endUndoGrouping];
	
	STAssertTrue(undeletedCustomer.sum.doubleValue == 34.33, @"customer with invoices sum %f", undeletedCustomer.sum.doubleValue);
	STAssertTrue(observerCount == 1, @"observer count %d", observerCount);
	[undeletedCustomer removeObserver:self forKeyPath:@"sum"];
    
}


- (void)testUndo
{	
	[self testUndoDelete];
	STAssertTrue([[self.context.undoManager undoMenuItemTitle] isEqualToString:@"Undo change"], @"undoName - %@",[self.context.undoManager undoMenuItemTitle]);
	
	NSArray* allCustomers = [Customer findAllCustomersInManagedObjectContext:self.context];
	STAssertTrue(allCustomers.count == 1, @"customer undelete failed %d", allCustomers.count);
	
	//check if observings still work
	observerCount = 0;
	Customer* undeletedCustomer = [allCustomers lastObject];
	[undeletedCustomer addObserver:self 
						forKeyPath:@"sum" 
						   options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)  
						   context:@"UnitTest"];
	
	//Invoice* undeletedInvoice = [undeletedCustomer.invoices anyObject];
	
	[[self.context undoManager] undo];
	
	STAssertTrue(undeletedCustomer.sum.doubleValue == 2.0, @"customer with invoices sum %f", undeletedCustomer.sum.doubleValue);
	STAssertTrue(observerCount == 1, @"observer count %d", observerCount);
	
	[[self.context undoManager] redo];
	
	STAssertTrue(undeletedCustomer.sum.doubleValue == 34.33, @"customer with invoices sum %f", undeletedCustomer.sum.doubleValue);
	STAssertTrue(observerCount == 2, @"observer count %d", observerCount);
	
	[undeletedCustomer removeObserver:self forKeyPath:@"sum"];
	
}

- (void)testDeleteUndoDeleteInvoice
{
	STAssertTrue([self.context.undoManager canUndo] == NO, @"undoManager canUndo");
	STAssertTrue([[self.context undoManager] isUndoRegistrationEnabled] == YES, @"undoRegistration %d", [[self.context undoManager] isUndoRegistrationEnabled]);		
	
	Customer* firstCustomer = [Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	STAssertTrue(firstCustomer.sum.doubleValue == 0.0, @"customer without invoices should have zero sum");
	
	Invoice* firstInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];		
	// change invoice sum
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:1.0];
	STAssertTrue(firstCustomer.sum.doubleValue == 1.0, @"customer with invoices sum %@", firstCustomer.sum);

	NSLog(@"insertedObjects: %@", [self.context insertedObjects]);
	
	// create undo group for delete operation
	[self.context processPendingChanges];
	
	[[self.context undoManager] setActionName:@"initialOperations"];
	[[self.context undoManager] endUndoGrouping];

    
    //delete invoice	
	//check if observings still work

    [self.context processPendingChanges];
	[[self.context undoManager] beginUndoGrouping];
	[[self.context undoManager] setActionName:@"delete"];
	
	[self.context deleteObject:firstInvoice];
	
    [self.context processPendingChanges];
	[[self.context undoManager] endUndoGrouping];
	
	
    STAssertTrue([firstInvoice isDeleted] == YES,@"invoice not deleted %@", firstInvoice);
    // undo delete invoice
    [[self.context undoManager] undo];

    STAssertTrue([firstInvoice isDeleted] == NO,@"invoice is deleted %@", firstInvoice);    
    
    // delete again
    [self.context processPendingChanges];
	[[self.context undoManager] beginUndoGrouping];
	[[self.context undoManager] setActionName:@"delete"];
	
	[self.context deleteObject:firstInvoice];

	[self.context processPendingChanges];
	[[self.context undoManager] endUndoGrouping];
    
    STAssertTrue([firstInvoice isDeleted] == YES,@"invoice not deleted %@", firstInvoice);    
    
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)observerContext
{
	if (observerContext == @"UnitTest")
	{
		observerCount++;
	}
}

@end
