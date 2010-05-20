#import "Invoice.h"

#import "Customer.h"

@implementation Invoice 

@dynamic alreadyPaid;
@dynamic invoiceSum;
@dynamic invoiceNumber;
@dynamic customer;

+(Invoice*) insertNewInvoiceWithCustomer:(Customer*) newCustomer inManagedObjectContext:(NSManagedObjectContext*) context
{
	if (newCustomer == nil)
		[NSException raise:@"Customer required" format:@"insertNewInvoice failed because of missing customer"];
	
	Invoice *newInvoice = [NSEntityDescription insertNewObjectForEntityForName:@"Invoice"
														  inManagedObjectContext:context];
	newInvoice.customer = newCustomer;
	return newInvoice;
}

@end
