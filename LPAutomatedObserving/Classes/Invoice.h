#import <CoreData/CoreData.h>
#import "LPManagedObject.h"

@class Customer;

@interface Invoice :  LPManagedObject  
{
}

@property (nonatomic, retain) NSNumber * alreadyPaid;
@property (nonatomic, retain) NSNumber * invoiceSum;
@property (nonatomic, retain) NSString * invoiceNumber;
@property (nonatomic, retain) Customer * customer;

+(Invoice*) insertNewInvoiceWithCustomer:(Customer*) newCustomer inManagedObjectContext:(NSManagedObjectContext*) context;

@end



