#import "Person.h"

#import "Invoice.h"
#import "LPManagedObjectObservationInfo.h"

@implementation Person 

@dynamic standardDiscount;
@dynamic name;
@dynamic invoices;
@dynamic sum;

+(NSArray*) keyPathsForValuesAffectingDerivedSum
{
	return [NSArray arrayWithObjects:@"invoices.discountedInvoiceSum", @"invoices.alreadyPaid", nil];
}

#if MACOSX_DEPLOYMENT_TARGET >= 1060
- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
	[super awakeFromSnapshotEvents:flags];
}
#endif



-(void) updateDerivedSumForChange:(NSDictionary *)change
{
	if ([self.managedObjectContext.undoManager isUndoing] || [self.managedObjectContext.undoManager isRedoing])
	{
		// do not process any changes while undo/redo!
		return;
	}
	// ----------------------------- performance update ------------------------------------
//	id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
//	id newValue = [change objectForKey:NSKeyValueChangeNewKey];
//	
//	NSString *keyPath = [change objectForKey:LPKeyValueChangeKeyPathKey];
//	
//	LPManagedObjectObservationInfo *observationInfo = [change objectForKey:LPKeyValueChangeObservationInfoKey];
//	
	double invoicesSum = self.sum.doubleValue;
	
//	if ([keyPath isEqualToString:@"discountedInvoiceSum"])
//	{
//		invoicesSum = self.sum.doubleValue;
//		
//		invoicesSum -= [oldValue doubleValue];
//		invoicesSum += [newValue doubleValue];
//	}
//	else if ([keyPath isEqualToString:@"invoices"])
//	{
//		// ignore other observings of this relation to reduce multiple updates for a single relation change
//		if ([observationInfo.observedPropertyKeyPath isEqualToString:@"discountedInvoiceSum"])
//		{
//			invoicesSum = self.sum.doubleValue;
//	
//			// is there any chance the invoice sum changes while the relation is changed?
//			// removed invoices from current customer
//			if (![oldValue isEqual:[NSNull null]] && oldValue != nil)
//			{
//				// remove A from Relation containing A,B
//				// OLD: A,B NEW: B -> A,B MINUS B => A
//				NSMutableSet *removedInvoices = [NSMutableSet setWithSet:oldValue];
//				[removedInvoices minusSet:newValue];
//				for (Invoice *removedInvoice in removedInvoices)
//				{
//					if (!removedInvoice.alreadyPaid.boolValue)
//						invoicesSum -= removedInvoice.discountedInvoiceSum.doubleValue;
//					
//				}
//			}
//			
//			// added invoices to current customer	
//			if (![newValue isEqual:[NSNull null]] && newValue != nil)
//			{
//				// add A to relation containing B
//				// OLD: B, NEW: A,B -> A,B minus B => A
//				NSMutableSet *addedInvoices = [NSMutableSet setWithSet:newValue];
//				[addedInvoices minusSet:oldValue];
//				for (Invoice *addedInvoice in addedInvoices)
//				{
//					if (!addedInvoice.alreadyPaid.boolValue)
//						invoicesSum += addedInvoice.discountedInvoiceSum.doubleValue;
//					
//				}
//			}
//			
//		}		
//	}
//	// ----------------------------- simple update ------------------------------------
//	else
{
	// if update type is unknown, simple recalculate the full sum
	NSDate *startDate = [NSDate date];

	for (NSInteger count = 0; count < 10000; count++)
	{
		invoicesSum = 0.0;
		invoicesSum = [[self valueForKeyPath:@"invoices.@sum.discountedInvoiceSum"] doubleValue];
	}
	NSLog(@"calculation time @sum: %f", [[NSDate date] timeIntervalSinceDate:startDate]);
	startDate = [NSDate date];
	
	for (NSInteger count = 0; count < 10000; count++)
	{
		for (Invoice* invoice in self.invoices)
		{
//				if (!invoice.alreadyPaid.boolValue)
				invoicesSum += invoice.discountedInvoiceSum.doubleValue;
		}
	}		
	NSLog(@"calculation time looping: %f", [[NSDate date] timeIntervalSinceDate:startDate]);		
}
	
	// only update sum if really changed
	if (self.sum == nil || self.sum.doubleValue != invoicesSum)
		self.sum = [NSNumber numberWithDouble:invoicesSum];
}

@end
