#import "TestLPAutomatedObserving.h"
#import "Customer.h"
#import "Invoice.h"
#import "LPManagedObjectContext.h"

@implementation TestLPAutomatedObserving


- (void)testBasicCustomer
{
	Customer* firstCustomer = [Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	STAssertNotNil(firstCustomer, @"insert of new customer failed");
	STAssertTrue([firstCustomer.name isEqualToString:@"customer A"], @"customer name wrong %@", firstCustomer.name);
	STAssertTrue(firstCustomer.sum.doubleValue == 0.0, @"customer without invoices should have zero sum");
	STAssertTrue(firstCustomer.standardDiscount.doubleValue == 0.0, @"customer without invoices should have zero sum");
}

- (void)testBasicInvoice
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

- (void)testSumsOfNewEntries
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

- (void)testChangeInvoiceCustomer
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

- (void)testSumObservings
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

- (void)testAlreadyPaidObservings
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

- (void)testChangePaidInvoice
{
    Customer* firstCustomer = [Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
  	Invoice* firstInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];
    STAssertTrue(firstCustomer.sum.doubleValue == 0.0, @"customer sum %@", firstCustomer);
    firstInvoice.alreadyPaid = [NSNumber numberWithBool:YES];
    firstInvoice.invoiceSum = [NSNumber numberWithDouble:10.0];
    STAssertTrue(firstCustomer.sum.doubleValue == 0.0, @"changing paid invoices should not matter customer sum %@", firstCustomer);
}

- (void)testDisabledObservings
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
	
	
	// restore consistent state before activating observings!
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:0.0];
	
	// now change again with active observings
	managedObjectContext.observingsActive = YES;
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:2.0];
	STAssertTrue(firstCustomer.sum.doubleValue == 2.0, @"customer with invoices sum %@", firstCustomer.sum);
	STAssertTrue(observerCount == 1, @"observer count %d", observerCount);
	
	[firstCustomer removeObserver:self forKeyPath:@"sum"];
}

- (void)testFindAllCustomers
{
	[Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	[Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	
	NSArray* allCustomers = [Customer findAllCustomersInManagedObjectContext:self.context];
	STAssertTrue(allCustomers.count == 2, @"found customers");
	
}


- (void)testDiscountedInvoiceSum
{
	observerCount = 0;
	Customer* firstCustomer = [Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	Invoice* firstInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];
	
	[firstInvoice addObserver:self 
				   forKeyPath:@"discountedInvoiceSum" 
					  options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)  
					  context:@"UnitTest"];	
	
	STAssertTrue(observerCount == 0, @"observer count %d", observerCount);
	STAssertTrue(firstInvoice.invoiceSum.doubleValue == 0.0, @"new invoices should have zero sum");
	
	//change invoice sum
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:100];
	STAssertTrue(observerCount == 1, @"observer count %d", observerCount);	
	STAssertTrue(firstInvoice.invoiceSum.doubleValue == 100.0, @"sum %@", firstInvoice.invoiceSum);
	
	//change discount
	firstInvoice.discount = [NSNumber numberWithDouble:0.3];
	STAssertTrue(firstInvoice.invoiceSum.doubleValue == 100.0, @"sum %@", firstInvoice.invoiceSum);
	STAssertTrue(firstInvoice.discountedInvoiceSum.doubleValue == 70.0, @"sum %@", firstInvoice.discountedInvoiceSum);
	STAssertTrue(observerCount == 2, @"observer count %d", observerCount);
	
	[firstInvoice removeObserver:self forKeyPath:@"discountedInvoiceSum"];
}

- (void)testDiscountedInvoiceSumCustomer
{
	observerCount = 0;
	Customer* firstCustomer = [Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	Invoice* firstInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];
	
	[firstCustomer addObserver:self 
					forKeyPath:@"sum" 
					   options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)  
					   context:@"UnitTest"];	
	
	STAssertTrue(observerCount == 0, @"observer count %d", observerCount);
	STAssertTrue(firstInvoice.invoiceSum.doubleValue == 0.0, @"new invoices should have zero sum");
	STAssertTrue(firstCustomer.sum.doubleValue == 0.0, @"customer with invoices sum %@", firstCustomer.sum);
	
	//change invoice sum
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:100];
	STAssertTrue(observerCount == 1, @"observer count %d", observerCount);	
	STAssertTrue(firstInvoice.invoiceSum.doubleValue == 100.0, @"sum %@", firstInvoice.invoiceSum);
	STAssertTrue(firstCustomer.sum.doubleValue == 100.0, @"customer with invoices sum %@", firstCustomer.sum);
	
	//change discount
	firstInvoice.discount = [NSNumber numberWithDouble:0.3];
	STAssertTrue(observerCount == 2, @"observer count %d", observerCount);
	STAssertTrue(firstInvoice.invoiceSum.doubleValue == 100.0, @"sum %@", firstInvoice.invoiceSum);
	STAssertTrue(firstInvoice.discountedInvoiceSum.doubleValue == 70.0, @"sum %@", firstInvoice.discountedInvoiceSum);
	STAssertTrue(firstCustomer.sum.doubleValue == 70.0, @"customer with invoices sum %@", firstCustomer.sum);
	
	[firstCustomer removeObserver:self forKeyPath:@"sum"];
}

- (void)testChangeCustomerDiscount
{
	Customer* firstCustomer = [Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	Invoice* firstInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];
	Invoice* secondInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];
	
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:100.0];
	secondInvoice.invoiceSum = [NSNumber numberWithDouble:100.0];
	
	STAssertTrue(firstCustomer.sum.doubleValue == 200.0, @"customer with invoices sum %@", firstCustomer.sum);
	
	firstInvoice.alreadyPaid = [NSNumber numberWithBool:YES];
	STAssertTrue(firstCustomer.sum.doubleValue == 100.0, @"customer with invoices sum %@", firstCustomer.sum);
	
	// changing discount
	firstCustomer.standardDiscount = [NSNumber numberWithDouble:0.1];
	// unpaid/unsent invoices get discount
	STAssertTrue(secondInvoice.invoiceSum.doubleValue == 100.0, @"sum %@", firstInvoice.invoiceSum);
	STAssertTrue(secondInvoice.discountedInvoiceSum.doubleValue == 90.0, @"sum %@", firstInvoice.discountedInvoiceSum);
	
	// paid invoices remain unchanged
	STAssertTrue(firstInvoice.invoiceSum.doubleValue == 100.0, @"sum %@", firstInvoice.invoiceSum);
	STAssertTrue(firstInvoice.discountedInvoiceSum.doubleValue == 100.0, @"sum %@", firstInvoice.discountedInvoiceSum);
}

- (void)testAddInvoiceToCustomerWithDiscount
{
	@try
	{
	Customer* firstCustomer = [Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	// changing discount
	firstCustomer.standardDiscount = [NSNumber numberWithDouble:0.1];
	
	
	Invoice* firstInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];	
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:100.0];
	
	STAssertTrue(firstInvoice.invoiceSum.doubleValue == 100.0, @"sum %@", firstInvoice.invoiceSum);
	STAssertTrue(firstInvoice.discountedInvoiceSum.doubleValue == 90.0, @"sum %@", firstInvoice.discountedInvoiceSum);

	}
	@catch (NSException * e)
	{
		STAssertTrue(e == nil, @"should not fail: %@", e);
	}
}

- (void)testChangeCustomerDiscountUndo
{
	Customer* firstCustomer = [Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	Invoice* firstInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];
	Invoice* secondInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];
	
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:100.0];
	secondInvoice.invoiceSum = [NSNumber numberWithDouble:100.0];
	
	STAssertTrue(firstCustomer.sum.doubleValue == 200.0, @"customer with invoices sum %@", firstCustomer.sum);
	
	firstInvoice.alreadyPaid = [NSNumber numberWithBool:YES];
	STAssertTrue(firstCustomer.sum.doubleValue == 100.0, @"customer with invoices sum %@", firstCustomer.sum);
	
	
	[self.context processPendingChanges];
	
	[[self.context undoManager] setActionName:@"initialOperations"];
	[[self.context undoManager] endUndoGrouping];
	
	
	
	STAssertTrue([[self.context.undoManager undoMenuItemTitle] isEqualToString:@"Undo initialOperations"], @"undoName - %@",[self.context.undoManager undoMenuItemTitle]);
	
	[self.context processPendingChanges];
	[[self.context undoManager] beginUndoGrouping];
	
	// changing discount
	firstCustomer.standardDiscount = [NSNumber numberWithDouble:0.1];
	// unpaid/unsent invoices get discount
	STAssertTrue(secondInvoice.invoiceSum.doubleValue == 100.0, @"sum %@", firstInvoice.invoiceSum);
	STAssertTrue(secondInvoice.discountedInvoiceSum.doubleValue == 90.0, @"sum %@", firstInvoice.discountedInvoiceSum);
	
	// paid invoices remain unchanged
	STAssertTrue(firstInvoice.invoiceSum.doubleValue == 100.0, @"sum %@", firstInvoice.invoiceSum);
	STAssertTrue(firstInvoice.discountedInvoiceSum.doubleValue == 100.0, @"sum %@", firstInvoice.discountedInvoiceSum);
	
	[self.context processPendingChanges];
	
	[[self.context undoManager] setActionName:@"changedDiscount"];
	[[self.context undoManager] endUndoGrouping];
	
	[secondInvoice addObserver:self 
					forKeyPath:@"discount" 
					   options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)  
					   context:@"UnitTest"];
	
	NSLog(@"undo discount change");
	[[self.context undoManager] undo];
	STAssertTrue(observerCount == 1, @"observer count %d", observerCount);
	
	[secondInvoice removeObserver:self forKeyPath:@"discount"];
	
	
}

- (void)testChangeCustomerDiscountRedo
{
	
}

- (void)testDicountChangeCustomer
{
	Customer* firstCustomer = [Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	Customer* secondCustomer = [Customer insertNewCustomerWithName:@"customer B" inManagedObjectContext:self.context];
	Invoice* firstInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];
	
	
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:100.0];
	
	
	STAssertTrue(firstCustomer.sum.doubleValue == 100.0, @"customer with invoices sum %@", firstCustomer.sum);
	
	firstCustomer.standardDiscount = [NSNumber numberWithDouble:0.1];
	secondCustomer.standardDiscount = [NSNumber numberWithDouble:0.3];
	
	[self.context processPendingChanges];	
	[[self.context undoManager] setActionName:@"initialOperations"];
	[[self.context undoManager] endUndoGrouping];
	
	
	[firstInvoice addObserver:self 
				   forKeyPath:@"discount" 
					  options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)  
					  context:@"UnitTest"];
	
	// create undo group to change customer of invoice
	[self.context processPendingChanges];
	[[self.context undoManager] beginUndoGrouping];
	
	firstInvoice.customer = secondCustomer;
	
	
	STAssertTrue(observerCount == 1, @"observer count %d", observerCount);
	STAssertTrue(secondCustomer.sum.doubleValue == 70.0, @"customer with invoices sum %@", secondCustomer.sum);
	[self.context processPendingChanges];	
	[[self.context undoManager] setActionName:@"changeCustomer"];
	[[self.context undoManager] endUndoGrouping];
	
	[[self.context undoManager] undo];
	
	STAssertTrue(observerCount == 2, @"observer count %d", observerCount);
	STAssertTrue(firstCustomer.sum.doubleValue == 90.0, @"customer with invoices sum %@", firstCustomer.sum);
	[[self.context undoManager] redo];
	
	STAssertTrue(observerCount == 3, @"observer count %d", observerCount);
	STAssertTrue(secondCustomer.sum.doubleValue == 70.0, @"customer with invoices sum %@", secondCustomer.sum);
	
	[firstInvoice removeObserver:self forKeyPath:@"discount"];
	
}

- (void)testFaulting
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

	

	
	// turn both invoices into fault, all data is saved at this point, the context is clean!
	// as this does not work in iOS, reset the context to make sure everything is faulted
	// only happens in iOS Tests
	[self.context refreshObject:firstInvoice mergeChanges:NO];
	[self.context refreshObject:secondInvoice mergeChanges:NO];
	
//	[self.context reset];	
	STAssertTrue([firstInvoice isFault] == YES, @"firstInvoice must be fault");	
	STAssertTrue([secondInvoice isFault] == YES, @"secondInvoice must be fault");


	
	Customer *fetchedCustomer = [Customer findAllCustomersInManagedObjectContext:self.context].lastObject;
	STAssertTrue(fetchedCustomer != nil, @"fetched customer missing");
	STAssertTrue(fetchedCustomer.sum.doubleValue == 20.0, @"fetchedCustomer sum not loaded correctly %@", fetchedCustomer);
	STAssertTrue(fetchedCustomer.invoices.count == 2, @"fetchedCustomer.invoices %@", fetchedCustomer.invoices);
	
	firstInvoice = [fetchedCustomer.invoices.allObjects objectAtIndex:0];
	secondInvoice = [fetchedCustomer.invoices.allObjects objectAtIndex:1];
	
	STAssertTrue(fetchedCustomer.sum.doubleValue == 20.0, @"invoices sum is %@", fetchedCustomer.sum);
	STAssertTrue([firstInvoice isFault] == YES, @"firstInvoice must be fault");	
	STAssertTrue([secondInvoice isFault] == YES, @"secondInvoice must be fault");
	
	
	// change value of firstInvoice
	// make sure the other invoice stays faulted
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:5.0];
	STAssertTrue(fetchedCustomer.sum.doubleValue == 15.0, @"invoices sum is %@", fetchedCustomer.sum);
	STAssertTrue([secondInvoice isFault] == YES, @"secondInvoice must be fault");
}

- (void)testFaultingInsertObject
{
	NSError *error = nil;
	Customer* firstCustomer = [Customer insertNewCustomerWithName:@"customer A" inManagedObjectContext:self.context];
	Invoice* firstInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:10.0];
	
	STAssertTrue(firstCustomer.sum.doubleValue == 10.0, @"invoices sum is %@", firstCustomer.sum);
	@try
	{
		[self.context save:&error];	
	}
	@catch (NSException * e)
	{
		STAssertTrue(e == nil, @"error: %@", e);
	}
	
	// turn invoice into fault, all data is saved at this point, the context is clean!
//	[self.context refreshObject:firstInvoice mergeChanges:NO];
	[self.context reset];

	STAssertTrue([firstInvoice isFault] == YES, @"firstInvoice must be fault");	
	
	// insert new invoice
	// make sure the other invoice stays faulted

	Customer *fetchedCustomer = [Customer findAllCustomersInManagedObjectContext:self.context].lastObject;
	STAssertTrue(fetchedCustomer != nil, @"fetched customer missing");
	STAssertTrue(fetchedCustomer.invoices.count == 1, @"fetchedCustomer.invoices %@", fetchedCustomer.invoices);
	
	firstInvoice = [fetchedCustomer.invoices.allObjects objectAtIndex:0];
	
	Invoice* secondInvoice = [Invoice insertNewInvoiceWithCustomer:fetchedCustomer inManagedObjectContext:self.context];
	secondInvoice.invoiceSum = [NSNumber numberWithDouble:10.0];

	STAssertTrue(fetchedCustomer.sum.doubleValue == 20.0, @"invoices sum is %@", fetchedCustomer.sum);
	STAssertTrue([firstInvoice isFault] == YES, @"firstInvoice must be fault");
}

- (void)testFaultingRemoveObject
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
		[self.context save:&error];	
	}
	@catch (NSException * e)
	{
		STAssertTrue(e == nil, @"error: %@", e);
	}
	
	// turn both invoices into fault, all data is saved at this point, the context is clean!
//	[self.context refreshObject:firstInvoice mergeChanges:NO];
//	[self.context refreshObject:secondInvoice mergeChanges:NO];
	
	[self.context reset];
	
	STAssertTrue([firstInvoice isFault] == YES, @"firstInvoice must be fault");	
	STAssertTrue([secondInvoice isFault] == YES, @"secondInvoice must be fault");	
	
	
	Customer *fetchedCustomer = [Customer findAllCustomersInManagedObjectContext:self.context].lastObject;
	STAssertTrue(fetchedCustomer != nil, @"fetched customer missing");
	STAssertTrue(fetchedCustomer.sum.doubleValue == 20.0, @"fetchedCustomer sum not loaded correctly %@", fetchedCustomer);
	STAssertTrue(fetchedCustomer.invoices.count == 2, @"fetchedCustomer.invoices %@", fetchedCustomer.invoices);
	
	firstInvoice = [fetchedCustomer.invoices.allObjects objectAtIndex:0];
	secondInvoice = [fetchedCustomer.invoices.allObjects objectAtIndex:1];
	
	STAssertTrue(fetchedCustomer.sum.doubleValue == 20.0, @"invoices sum is %@", fetchedCustomer.sum);
	STAssertTrue([firstInvoice isFault] == YES, @"firstInvoice must be fault");	
	STAssertTrue([secondInvoice isFault] == YES, @"secondInvoice must be fault");
	
	
	// delete second invoice
	// make sure the other invoice stays faulted
	
	[self.context deleteObject:secondInvoice];
	[self.context processPendingChanges];
	
	// do I need to process pending changes at this point?
	STAssertTrue(fetchedCustomer.sum.doubleValue == 10.0, @"invoices sum is %@", fetchedCustomer.sum);
	STAssertTrue([firstInvoice isFault] == YES, @"firstInvoice must be fault");
}

- (void)testFaultingStandardDiscountChanged
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
	
	
	
	
	// turn both invoices into fault, all data is saved at this point, the context is clean!
	// as this does not work in iOS, reset the context to make sure everything is faulted
	// only happens in iOS Tests
	[self.context refreshObject:firstInvoice mergeChanges:NO];
	[self.context refreshObject:secondInvoice mergeChanges:NO];
	
//	[self.context reset];	
	STAssertTrue([firstInvoice isFault] == YES, @"firstInvoice must be fault");	
	STAssertTrue([secondInvoice isFault] == YES, @"secondInvoice must be fault");
	NSLog(@"context reset done");
	
	NSLog(@"load customer");
	Customer *fetchedCustomer = [Customer findAllCustomersInManagedObjectContext:self.context].lastObject;
	STAssertTrue(fetchedCustomer != nil, @"fetched customer missing");
	STAssertTrue(fetchedCustomer.sum.doubleValue == 20.0, @"fetchedCustomer sum not loaded correctly %@", fetchedCustomer);
	STAssertTrue(fetchedCustomer.invoices.count == 2, @"fetchedCustomer.invoices %@", fetchedCustomer.invoices);
	NSLog(@"customer loaded");
	NSLog(@"change discount");
	fetchedCustomer.standardDiscount = [NSNumber numberWithDouble:0.1];
	NSLog(@"discount changed");	
	firstInvoice = [fetchedCustomer.invoices.allObjects objectAtIndex:0];
	secondInvoice = [fetchedCustomer.invoices.allObjects objectAtIndex:1];
	
	STAssertTrue(fetchedCustomer.sum.doubleValue == 18.0, @"invoices sum is %@", fetchedCustomer.sum);
	STAssertTrue([firstInvoice isFault] == NO, @"firstInvoice must not be fault");	
	STAssertTrue([secondInvoice isFault] == NO, @"secondInvoice must not be fault");
}



- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)observerContext
{
	if (observerContext == @"UnitTest")
	{
		observerCount++;
	}
}

@end
