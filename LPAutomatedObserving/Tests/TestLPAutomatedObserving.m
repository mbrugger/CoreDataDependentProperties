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
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:1.0];
	STAssertTrue(firstCustomer.sum.doubleValue == 1.0, @"customer with invoices sum %@", firstCustomer.sum);
	
	// create second invoice
	Invoice* secondInvoice = [Invoice insertNewInvoiceWithCustomer:firstCustomer inManagedObjectContext:self.context];	

	// change second invoice sum
	secondInvoice.invoiceSum = [NSNumber numberWithDouble:1.0];
	STAssertTrue(firstCustomer.sum.doubleValue == 2.0, @"customer with invoices sum %@", firstCustomer.sum);	
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
	firstInvoice.invoiceSum = [NSNumber numberWithDouble:1.0];
	STAssertTrue(firstCustomer.sum.doubleValue == 1.0, @"customer with invoices sum %@", firstCustomer.sum);
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

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)observerContext
{
	if (observerContext == @"UnitTest")
	{
		observerCount++;
	}
}

@end
