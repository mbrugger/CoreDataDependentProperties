#import <CoreData/CoreData.h>
#import "LPManagedObject.h"

@class Invoice;

@interface Customer :  LPManagedObject  
{
	NSNumber* sum;
}

@property (nonatomic, retain) NSNumber *sum;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSSet *invoices;

-(void) updateDerivedSum;

+ (Customer*) insertNewCustomerWithName:(NSString*) newName inManagedObjectContext:(NSManagedObjectContext*) context;
@end


@interface Customer (CoreDataGeneratedAccessors)
- (void)addInvoicesObject:(Invoice *)value;
- (void)removeInvoicesObject:(Invoice *)value;
- (void)addInvoices:(NSSet *)value;
- (void)removeInvoices:(NSSet *)value;

@end

