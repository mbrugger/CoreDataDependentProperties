#import "TestLPAutomatedObserving.h"
#import "Customer.h"
#import "Invoice.h"
#import "LPManagedObjectContext.h"

@implementation TestLPAutomatedObserving


-(void) testBasicCustomer
{
	Customer* firstCustomer = [Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	STAssertNotNil(firstCustomer, @"insert of new customer failed");
	STAssertTrue([firstCustomer.name isEqualToString:@"customer A"], @"customer name wrong %@", firstCustomer.name);
	STAssertTrue(firstCustomer.sum.doubleValue == 0.0, @"customer without invoices should have zero sum");
}

-(void) testBasicInvoice
{
	@try
	{
		Invoice* firstInvoice = [Invoice insertNewInvoiceWithCustomer:nil inManagedObjectContext:self.context];
		STAssertNil(firstInvoice, @"do not allow invoices without customer");
	}
	@catch (NSException * e)
	{
		
	}
	
	Customer* firstCustomer = [Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	Invoice* firstInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];
	
	STAssertTrue(firstInvoice.invoiceSum.doubleValue == 0.0, @"new invoices should have zero sum");
	STAssertNotNil(firstInvoice, @"insert new invoice with customer failed");
}

-(void) testSumsOfNewEntries
{
	// create empty customer
	Customer* firstCustomer = [Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	STAssertTrue(firstCustomer.sum.doubleValue == 0.0, @"customer without invoices should have zero sum");
	
	// create invoice for customer
	Invoice* firstInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];	
	STAssertTrue(firstCustomer.sum.doubleValue == 0.0, @"customer with zero sum invoices should have zero sum %@", firstCustomer.sum);
	
	// change invoice sum
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:1.5];
	STAssertTrue(firstCustomer.sum.doubleValue == 1.5, @"customer with invoices sum %@", firstCustomer.sum);
	
	// create second invoice
	Invoice* secondInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];	

	// change second invoice sum
	secondInvoice.invoiceSum = [NSNumber numberWithDouble:1.0];
	STAssertTrue(firstCustomer.sum.doubleValue == 2.5, @"customer with invoices sum %@", firstCustomer.sum);	
}

-(void) testChangeInvoiceCustomer
{
	// create two customer
	Customer* firstCustomer = [Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	STAssertTrue(firstCustomer.sum.doubleValue == 0.0, @"customer without invoices should have zero sum");
	
	
	Customer* secondCustomer = [Customer insertNewCustomerWithName:@"customer B" inManagedObjectContext:self.context];
	STAssertTrue(secondCustomer.sum.doubleValue == 0.0, @"customer without invoices should have zero sum");
	
	// create invoice for customer
	Invoice* firstInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];	
	// change invoice sum
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:1.0];
	STAssertTrue(firstCustomer.sum.doubleValue == 1.0, @"customer with invoices sum %@", firstCustomer.sum);
	
	
	//move invoice form customer A to customer B
	firstInvoice.customer = secondCustomer;
	STAssertTrue(firstCustomer.sum.doubleValue == 0.0, @"customer with invoices sum %@", firstCustomer.sum);
	STAssertTrue(secondCustomer.sum.doubleValue == 1.0, @"customer with invoices sum %@", firstCustomer.sum);
}

-(void) testSumObservings
{
	observerCount = 0;
	
	Customer* firstCustomer = [Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	STAssertTrue(firstCustomer.sum.doubleValue == 0.0, @"customer without invoices should have zero sum");
	
	[firstCustomer addObserver:self 
					forKeyPath:@"sum" 
					   options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)  
					   context:@"UnitTest"];
	
	Invoice* firstInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];	
	// just adding an invoice with zero sum should not cause KVO notification
	STAssertTrue(observerCount == 0, @"observer count %d", observerCount);
	
	// change invoice sum
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:1.5];
	STAssertTrue(firstCustomer.sum.doubleValue == 1.5, @"customer with invoices sum %@", firstCustomer.sum);
	STAssertTrue(observerCount == 1, @"observer count %d", observerCount);
	
	// remove invoice from customer
	firstInvoice.customer = nil;
	STAssertTrue(observerCount == 2, @"observer count %d", observerCount);
	
	
	// adding invoice with sum
	firstInvoice.customer = firstCustomer;
	STAssertTrue(observerCount == 3, @"observer count %d", observerCount);

	NSLog(@"delete invoice begin");
	//deleting invoice within customer
	[self.context deleteObject:firstInvoice];
	[self.context processPendingChanges];
	STAssertTrue(firstCustomer.sum.doubleValue == 0.0, @"after deleting sum %@", firstCustomer.sum);
	STAssertTrue(observerCount == 4, @"observer count %d", observerCount);	
	NSLog(@"delete invoice end");
	[firstCustomer removeObserver:self forKeyPath:@"sum"];
}

-(void) testAlreadyPaidObservings
{
	observerCount = 0;
	
	Customer* firstCustomer = [Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	STAssertTrue(firstCustomer.sum.doubleValue == 0.0, @"customer without invoices should have zero sum");
	
	[firstCustomer addObserver:self 
					forKeyPath:@"sum" 
					   options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)  
					   context:@"UnitTest"];
	
	Invoice* firstInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];	
	// just adding an invoice with zero sum should not cause KVO notification
	STAssertTrue(observerCount == 0, @"observer count %d", observerCount);
	
	// change invoice sum
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:1.0];
	STAssertTrue(firstCustomer.sum.doubleValue == 1.0, @"customer with invoices sum %@", firstCustomer.sum);
	STAssertTrue(observerCount == 1, @"observer count %d", observerCount);
	
	// change alreadyPaid status
	firstInvoice.alreadyPaid = [NSNumber numberWithBool:YES];
	STAssertTrue(observerCount == 2, @"observer count %d", observerCount);
	STAssertTrue(firstCustomer.sum.doubleValue == 0.0, @"customer with invoices sum %@", firstCustomer.sum);
	
	firstInvoice.alreadyPaid = [NSNumber numberWithBool:NO];
	STAssertTrue(observerCount == 3, @"observer count %d", observerCount);
	STAssertTrue(firstCustomer.sum.doubleValue == 1.0, @"customer with invoices sum %@", firstCustomer.sum);
	
	
	NSLog(@"delete invoice begin");
	//deleting invoice within customer
	[self.context deleteObject:firstInvoice];
	[self.context processPendingChanges];
	STAssertTrue(firstCustomer.sum.doubleValue == 0.0, @"after deleting sum %@", firstCustomer.sum);
	STAssertTrue(observerCount == 4, @"observer count %d", observerCount);	
	NSLog(@"delete invoice end");
	[firstCustomer removeObserver:self forKeyPath:@"sum"];
}

-(void) testDisabledObservings
{
	LPManagedObjectContext* managedObjectContext = (LPManagedObjectContext*) self.context;
	managedObjectContext.observingsActive = NO;
	Customer* firstCustomer = [Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	STAssertTrue(firstCustomer.sum.doubleValue == 0.0, @"customer without invoices should have zero sum");
	
	[firstCustomer addObserver:self 
					forKeyPath:@"sum" 
					   options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)  
					   context:@"UnitTest"];
	
	Invoice* firstInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];	
	// just adding an invoice with zero sum should not cause KVO notification
	STAssertTrue(observerCount == 0, @"observer count %d", observerCount);
	
	// change invoice sum should not do anything
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:1.0];
	STAssertTrue(firstCustomer.sum.doubleValue == 0.0, @"customer with invoices sum %@", firstCustomer.sum);
	STAssertTrue(observerCount == 0, @"observer count %d", observerCount);
	
	// now change again with active observings
	managedObjectContext.observingsActive = YES;
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:2.0];
	STAssertTrue(firstCustomer.sum.doubleValue == 2.0, @"customer with invoices sum %@", firstCustomer.sum);
	STAssertTrue(observerCount == 1, @"observer count %d", observerCount);
	
	[firstCustomer removeObserver:self forKeyPath:@"sum"];
}

-(void) testFindAllCustomers
{
	[Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	[Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];

	NSArray* allCustomers = [Customer findAllCustomersInManagedObjectContext:self.context];
	STAssertTrue(allCustomers.count == 2, @"found customers");

}

-(void) testUndoDelete
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
	[[self.context undoManager] removeAllActions];
	
	[self.context processPendingChanges];
	[[self.context undoManager] beginUndoGrouping];
	[[self.context undoManager] setActionName:@"delete"];
	
	[self.context deleteObject:firstCustomer];
	[self.context processPendingChanges];
	[[self.context undoManager] endUndoGrouping];
	
	NSArray* allCustomers = [Customer findAllCustomersInManagedObjectContext:self.context];
	STAssertTrue(allCustomers.count == 0, @"all customers deleted %@", allCustomers);
	
//	NSLog(@"insertedObjects: %@", [self.context insertedObjects]);
//	NSLog(@"undoName: %@", [self.context.undoManager undoMenuItemTitle]);
	[[self.context undoManager] undo];
//	NSLog(@"insertedObjects: %@", [self.context insertedObjects]);	
//	NSLog(@"undoName: %@", [self.context.undoManager undoMenuItemTitle]);

	STAssertTrue([[self.context undoManager] canUndo] == NO, @"undoManager canUndo");
	
//	NSLog(@"undomanager: %@", [self.context undoManager]);
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
	
	STAssertTrue(undeletedCustomer.sum.doubleValue == 34.33, @"customer with invoices sum %f", undeletedCustomer.sum.doubleValue);
	STAssertTrue(observerCount == 1, @"observer count %d", observerCount);
	[undeletedCustomer removeObserver:self forKeyPath:@"sum"];
}


-(void) testUndo
{
	
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)observerContext
{
	if (observerContext == @"UnitTest")
	{
		observerCount++;
	}
}

@end
