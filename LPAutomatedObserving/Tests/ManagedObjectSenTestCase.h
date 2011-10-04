#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#endif

#import <SenTestingKit/SenTestingKit.h>


@interface ManagedObjectSenTestCase : SenTestCase 
{
	NSPersistentStoreCoordinator *coordinator;
	NSManagedObjectContext *context;
	NSManagedObjectModel *model;
	NSAutoreleasePool *pool;
}

@property (retain,nonatomic) NSPersistentStoreCoordinator *coordinator;
@property (retain,nonatomic) NSManagedObjectContext *context;
@property (retain,nonatomic) NSManagedObjectModel *model;


@end
