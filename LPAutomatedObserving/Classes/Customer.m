#import "Customer.h"

#import "Invoice.h"
#import "LPManagedObjectObservationInfo.h"

@implementation Customer 

@dynamic standardDiscount;
@dynamic name;
@dynamic invoices;
@dynamic sum;

+(NSArray*) keyPathsForValuesAffectingDerivedSum
{
	return [NSArray arrayWithObjects:@"invoices.discountedInvoiceSum", @"invoices.alreadyPaid", nil];
}

-(void) awakeFromInsert
{
	[super awakeFromInsert];
}

-(void) awakeFromFetch
{
	// always call super awakeFromFetch!
	[super awakeFromFetch];
	// update should not be done here in deep dependency trees
	// could lead to performance issues
	// implement a recalculate while deactivating observings
	//[self updateDerivedSum];
}

#if MACOSX_DEPLOYMENT_TARGET >= 1060
- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
	[super awakeFromSnapshotEvents:flags];
	//	[self updateDerivedSum];
}
#endif

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

-(void) updateDerivedSumForChange:(NSDictionary *)change
{
	if ([self.managedObjectContext.undoManager isUndoing] || [self.managedObjectContext.undoManager isRedoing])
	{
		// do not process any changes while undo/redo!
		return;
	}
	
	id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
	id newValue = [change objectForKey:NSKeyValueChangeNewKey];
	
	NSString *keyPath = [change objectForKey:LPKeyValueChangeKeyPathKey];
	
	LPManagedObjectObservationInfo *observationInfo = [change objectForKey:LPKeyValueChangeObservationInfoKey];
	
	double invoicesSum = self.sum.doubleValue;
	
	if ([keyPath isEqualToString:@"discountedInvoiceSum"])
	{
		NSLog(@"updating incremental old: %@, new: %@", oldValue, newValue);
		invoicesSum = self.sum.doubleValue;
		
		invoicesSum -= [oldValue doubleValue];
		invoicesSum += [newValue doubleValue];
	}
	else if ([keyPath isEqualToString:@"invoices"])
	{
		if ([observationInfo.observedPropertyKeyPath isEqualToString:@"discountedInvoiceSum"])
		{
			
			//NSLog(@"updating incremental old: %@, new: %@", oldValue, newValue);
			invoicesSum = self.sum.doubleValue;
			
			
			
			// is there any chance the invoice sum changes while the relation is changed?
			// removed invoices from current customer
			if (![oldValue isEqual:[NSNull null]] && oldValue != nil)
			{
				// remove A from Relation containing A,B
				// OLD: A,B NEW: B -> A,B MINUS B => A
				NSMutableSet *removedInvoices = [NSMutableSet setWithSet:oldValue];
				[removedInvoices minusSet:newValue];
				for (Invoice *removedInvoice in removedInvoices)
				{
					NSLog(@"removing: %@", removedInvoice);
					if (!removedInvoice.alreadyPaid.boolValue)
						invoicesSum -= removedInvoice.discountedInvoiceSum.doubleValue;
					
				}
			}
			
			// added invoices to current customer	
			if (![newValue isEqual:[NSNull null]] && newValue != nil)
			{
				// add A to relation containing B
				// OLD: B, NEW: A,B -> A,B minus B => A
				NSMutableSet *addedInvoices = [NSMutableSet setWithSet:newValue];
				[addedInvoices minusSet:oldValue];
				for (Invoice *addedInvoice in addedInvoices)
				{
					NSLog(@"adding: %@", addedInvoice);
					if (!addedInvoice.alreadyPaid.boolValue)
						invoicesSum += addedInvoice.discountedInvoiceSum.doubleValue;
					
				}
			}
			
		}
		else
		{
			NSLog(@"ignore multiple observings of relation");
		}

		
	}
	else
	{
		NSLog(@"updating brute force");
		invoicesSum = 0.0;
		for (Invoice* invoice in self.invoices)
		{
			if (!invoice.alreadyPaid.boolValue)
				invoicesSum += invoice.discountedInvoiceSum.doubleValue;
		}
	}
	
	// only update sum if really changed
	if (self.sum == nil || self.sum.doubleValue != invoicesSum)
		self.sum = [NSNumber numberWithDouble:invoicesSum];
}

@end
