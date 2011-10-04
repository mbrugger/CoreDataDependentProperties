#import <CoreData/CoreData.h>
#import "LPManagedObject.h"

@class Person;

@interface Invoice :  LPManagedObject  
{
	
}

@property (nonatomic, retain) NSNumber * alreadyPaid;
@property (nonatomic, retain) NSNumber * invoiceSum;
@property (nonatomic, retain) NSString * invoiceNumber;
@property (nonatomic, retain) Person * customer;
@property (nonatomic, retain) NSNumber * discount;

@property (readonly) NSNumber * discountedInvoiceSum;

+(Invoice*) insertNewInvoiceWithCustomer:(Person*) newCustomer inManagedObjectContext:(NSManagedObjectContext*) context;

@end



