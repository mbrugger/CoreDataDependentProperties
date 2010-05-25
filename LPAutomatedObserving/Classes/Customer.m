#import "Customer.h"

#import "Invoice.h"

@implementation Customer 

@synthesize sum;

@dynamic name;
@dynamic invoices;

+(NSArray*) keyPathsForValuesAffectingDerivedSum
{
	return [NSArray arrayWithObjects:@"invoices.discountedInvoiceSum", @"invoices.alreadyPaid", nil];
}

-(void) awakeFromInsert
{
	[super awakeFromInsert];
	self.sum = [NSNumber numberWithDouble:0.0];
}

-(void) awakeFromFetch
{
	// always call super awakeFromFetch!
	[super awakeFromFetch];
	// update should not be done here in deep dependency trees
	// could lead to performance issues
	// implement a recalculate while deactivating observings
	[self updateDerivedSum];
}

#if MACOSX_DEPLOYMENT_TARGET >= 1060
- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
	[super awakeFromSnapshotEvents:flags];
	[self updateDerivedSum];
}
#endif

- (void) dealloc
{
	self.sum = nil;
	[super dealloc];
}

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

-(void) updateDerivedSum
{
	double invoicesSum = 0.0;
	for (Invoice* invoice in self.invoices)
	{
		if (!invoice.alreadyPaid.boolValue)
			invoicesSum += invoice.discountedInvoiceSum.doubleValue;
	}
	
	// only update sum if really changed
	if (self.sum == nil || self.sum.doubleValue != invoicesSum)
		self.sum = [NSNumber numberWithDouble:invoicesSum];
}

@end
