#import "Invoice.h"

#import "Customer.h"

@implementation Invoice 

@dynamic alreadyPaid;
@dynamic invoiceSum;
@dynamic invoiceNumber;
@dynamic customer;
@dynamic discount;

//+(NSArray*) keyPathsForValuesAffectingDerivedDiscount
//{
//	return [NSArray arrayWithObjects:@"customer.standardDiscount", nil];
//}

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
	return newInvoice;
}

-(void) updateDerivedDiscount
{
//	double invoicesSum = 0.0;
//	for (Invoice* invoice in self.invoices)
//	{
//		if (!invoice.alreadyPaid.boolValue)
//			invoicesSum += invoice.invoiceSum.doubleValue;
//	}
//	
//	// only update sum if really changed
//	if (self.sum == nil || self.sum.doubleValue != invoicesSum)
//		self.sum = [NSNumber numberWithDouble:invoicesSum];
}

- (NSNumber*) discountedInvoiceSum
{
	double sum = self.invoiceSum.doubleValue;
	double discount = self.discount.doubleValue;
	return [NSNumber numberWithDouble:sum - sum*discount];
}


@end
