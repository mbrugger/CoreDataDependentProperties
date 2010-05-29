#import "Invoice.h"

#import "Customer.h"

@implementation Invoice 

@dynamic alreadyPaid;
@dynamic invoiceSum;
@dynamic invoiceNumber;
@dynamic customer;
@dynamic discount;

+(NSArray*) keyPathsForValuesAffectingDerivedDiscount
{
	return [NSArray arrayWithObjects:@"customer.standardDiscount", nil];
}

+(NSArray*) keyPathsForValuesAffectingDiscountedInvoiceSum
{
	return [NSArray arrayWithObjects:@"discount", @"invoiceSum", nil];
}

+(Invoice*) insertNewInvoiceWithCustomer:(Customer*) newCustomer inManagedObjectContext:(NSManagedObjectContext*) context
{
	if (newCustomer == nil)
		[NSException raise:@"Customer required" format:@"insertNewInvoice failed because of missing customer"];
	
	Invoice *newInvoice = [NSEntityDescription insertNewObjectForEntityForName:@"Invoice"
														  inManagedObjectContext:context];
	newInvoice.customer = newCustomer;
	newInvoice.discount = newCustomer.standardDiscount;
	return newInvoice;
}

-(void) updateDerivedDiscount
{
	//transient property undo gets handeled by undomanager
	//do nothing in this case!

	
	if ([self.managedObjectContext.undoManager isUndoing]
		||[self.managedObjectContext.undoManager isRedoing])
	{
		return;
	}
	
	//NSLog(@"<%p %@> update discount", self, [self className]);	
	if (!self.alreadyPaid.boolValue
		&& self.discount.doubleValue != self.customer.standardDiscount.doubleValue)
	{
		self.discount = self.customer.standardDiscount;
	}
}

- (NSNumber*) discountedInvoiceSum
{
	double sum = self.invoiceSum.doubleValue;
	double discount = self.discount.doubleValue;
	return [NSNumber numberWithDouble:sum - sum*discount];
}


@end
