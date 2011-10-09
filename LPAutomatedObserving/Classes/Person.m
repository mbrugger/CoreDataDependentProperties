#import "Person.h"

#import "Invoice.h"
#import "LPManagedObjectObservationInfo.h"
#import "LPManagedObjectContext.h"

@implementation Person 

@dynamic standardDiscount;
@dynamic name;
@dynamic invoices;
@dynamic sum;

+(NSArray*) keyPathsForValuesAffectingDerivedSum
{
	return [NSArray arrayWithObjects:@"invoices.discountedInvoiceSum", @"invoices.alreadyPaid", nil];
}

//#if MACOSX_DEPLOYMENT_TARGET >= 1060
- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
    NSLog(@"Person %p awakeFromSnapshotEvents %d", self, (int)flags);
	[super awakeFromSnapshotEvents:flags];
}
//#endif


- (void)awakeFromFetch
{
    NSLog(@"Person %p awakeFromFetch", self);    
    [super awakeFromFetch];
}

- (void)awakeFromInsert
{
    NSLog(@"Person %p awakeFromInsert", self);
    [super awakeFromInsert];
}

- (void)willTurnIntoFault
{
    NSLog(@"Person %p willTurnIntoFault", self);
    [super willTurnIntoFault];
}

- (void)startObserving
{
    [super startObserving];
//    [self addObserver:self forKeyPath:@"standardDiscount" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld)   context:@"xxx"];
}

- (void)stopObserving
{
//    [self removeObserver:self forKeyPath:@"standardDiscount"];
    [super stopObserving];
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
{
    if ([observer.className isEqualToString:@"Invoice"])// && [observer.description rangeOfString:@"p1"].location != NSNotFound)
    {
        NSLog(@"invoice %p stop observing %@ of customer %p - deleted: %d", observer, keyPath, self, [observer isDeleted]);
    }
    [super removeObserver:observer forKeyPath:keyPath];
}

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context
{
    if ([observer.className isEqualToString:@"Invoice"])// && [observer.description rangeOfString:@"p1"].location != NSNotFound)
    {
        NSLog(@"invoice %p start observing %@ of customer %p - deleted: %d", observer, keyPath, self, [observer isDeleted]);
    }
    [super addObserver:observer forKeyPath:keyPath options:options context:context];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != @"xxx")
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    else
    {
        NSLog(@"XXXXXXXXXXXXXXXXXXXXXXX changed standard discount!");
    }
}

-(void) updateDerivedSumForChange:(NSDictionary *)change
{
	if ([self.managedObjectContext.undoManager isUndoing] 
        || [self.managedObjectContext.undoManager isRedoing] 
        || [((LPManagedObjectContext *)self.managedObjectContext) isMergingChanges])
	{
        // do not process changes while context merge is in progress
        // the property derivedSum was already calculated correctly in other context the merge is performed with
        
		// do not process any changes while undo/redo!
		return;
	}
	// ----------------------------- performance update ------------------------------------
	id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
	id newValue = [change objectForKey:NSKeyValueChangeNewKey];
	
	NSString *keyPath = [change objectForKey:LPKeyValueChangeKeyPathKey];
	
	LPManagedObjectObservationInfo *observationInfo = [change objectForKey:LPKeyValueChangeObservationInfoKey];
    Invoice *invoice = [change objectForKey:LPKeyValueChangeObjectKey];
	
	double invoicesSum = self.sum.doubleValue;
	if ([keyPath isEqualToString:@"alreadyPaid"])
    {
        invoicesSum = self.sum.doubleValue;
        
        if ([oldValue boolValue] == NO && [newValue boolValue] == YES)
        {
            invoicesSum -= invoice.discountedInvoiceSum.doubleValue;
        }
        else if ([oldValue boolValue] == YES && [newValue boolValue] == NO)
        {
            invoicesSum += invoice.discountedInvoiceSum.doubleValue;
        }
    }
	else if ([keyPath isEqualToString:@"discountedInvoiceSum"])
	{
		invoicesSum = self.sum.doubleValue;
		
        if (!invoice.alreadyPaid.boolValue)
        {
            invoicesSum -= [oldValue doubleValue];
            invoicesSum += [newValue doubleValue];
        }
	}
	else if ([keyPath isEqualToString:@"invoices"])
	{
		// ignore other observings of this relation to reduce multiple updates for a single relation change
		if ([observationInfo.observedPropertyKeyPath isEqualToString:@"discountedInvoiceSum"])
		{
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
					if (!addedInvoice.alreadyPaid.boolValue)
						invoicesSum += addedInvoice.discountedInvoiceSum.doubleValue;
					
				}
			}
			
		}		
	}
	// ----------------------------- simple update ------------------------------------
	else
	{
		// if update type is unknown, simple recalculate the full sum
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
