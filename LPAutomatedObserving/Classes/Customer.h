#import <CoreData/CoreData.h>
#import "LPManagedObject.h"

@class Invoice;

@interface Customer :  LPManagedObject  
{
	
}

@property (nonatomic, retain) NSNumber *standardDiscount;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSSet *invoices;
@property (nonatomic, retain) NSNumber *sum;

-(void) updateDerivedSumForChange:(NSDictionary *)change;

+ (Customer*) insertNewCustomerWithName:(NSString*) newName inManagedObjectContext:(NSManagedObjectContext*) context;
+ (NSArray*) findAllCustomersInManagedObjectContext:(NSManagedObjectContext*) context;
@end


@interface Customer (CoreDataGeneratedAccessors)
- (void)addInvoicesObject:(Invoice *)value;
- (void)removeInvoicesObject:(Invoice *)value;
- (void)addInvoices:(NSSet *)value;
- (void)removeInvoices:(NSSet *)value;

@end

