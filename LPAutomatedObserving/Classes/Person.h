#import <CoreData/CoreData.h>
#import "LPManagedObject.h"

@class Invoice;

@interface Person :  LPManagedObject  
{
	
}

@property (nonatomic, retain) NSNumber *standardDiscount;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSSet *invoices;
@property (nonatomic, retain) NSNumber *sum;

-(void) updateDerivedSumForChange:(NSDictionary *)change;

@end


@interface Person (CoreDataGeneratedAccessors)
- (void)addInvoicesObject:(Invoice *)value;
- (void)removeInvoicesObject:(Invoice *)value;
- (void)addInvoices:(NSSet *)value;
- (void)removeInvoices:(NSSet *)value;

@end

