#import "ManagedObjectSenTestCase.h"
#import "LPManagedObjectContext.h"


@implementation ManagedObjectSenTestCase

@synthesize coordinator;
@synthesize context;
@synthesize model;



-(void) setUp
{
	@try
	{
		pool = [[NSAutoreleasePool alloc] init];
		
		NSBundle* bundle = [NSBundle bundleWithIdentifier:@"eu.brugger.martin.CDDP"];
		//NSLog(@"bundle: %@", bundle);
		NSString* path = [bundle pathForResource:@"CoreDataDependentPropertiesDataModel" ofType:@"mom"];
		//NSLog(@"path: %@", path);
		NSURL* modelURL = [NSURL URLWithString:path];
		self.model = [[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL] autorelease];
		
		self.coordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model] autorelease];
		
		NSLog(@"create persistent store");
		// create persistent store
		NSString* tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"modeltest"];
		
		NSFileManager  * fileManager = [NSFileManager defaultManager];
		NSError* error = nil;
		if (![fileManager fileExistsAtPath:tempFilePath])
        {
            STAssertTrue([fileManager createDirectoryAtPath:tempFilePath withIntermediateDirectories: YES attributes:nil error:&error], @"error creating temp dir: %@", error);
        }

		
		NSString *persistentStoreFileString = [tempFilePath stringByAppendingPathComponent:@"test.sqlite"];
		if ([fileManager fileExistsAtPath:persistentStoreFileString])
		{
			[fileManager removeItemAtPath:persistentStoreFileString error:&error];
		}
		
		
		[self.coordinator addPersistentStoreWithType:NSSQLiteStoreType 
									   configuration:nil 
												 URL:[NSURL fileURLWithPath:persistentStoreFileString] 
											 options:nil 
											   error:&error];
		
		NSLog(@"create context");	
		LPManagedObjectContext* tempContext = [[[LPManagedObjectContext alloc] init] autorelease];
		
		
		[tempContext setPersistentStoreCoordinator:coordinator];

		[tempContext prepareDependentProperties];	
		
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
		tempContext.undoManager = [[[NSUndoManager alloc] init] autorelease];
#endif
		
		self.context = tempContext;
	}
	@catch (NSException * e)
	{
		STAssertTrue(e == nil, @"error - %@", e);
	}
}

-(void) tearDown
{
	NSLog(@"BEGIN: ManagedObjectSenTestCase tearDown");
	@try
	{
		self.context= nil;
		self.model = nil;
		self.coordinator = nil;
		[pool release];
		pool = nil;
	}
	@catch (NSException * e)
	{
		NSLog(@"%@",e);
		//NSLog(@"%@", [e callStackSymbols]);
		NSLog(@"context reset failed!");
		@throw(e);
		
	}
	NSLog(@"END: ManagedObjectSenTestCase tearDown");
}


-(void) testSetup
{
	STAssertNotNil(self.model, @"error loading model");
	STAssertNotNil(self.coordinator, @"error loading coordinator");
	STAssertNotNil(self.context, @"error loading context");
	
	NSArray* allEntities = [model entities];
	STAssertTrue(allEntities.count > 0, @"no entities in bundle!");	
}

@end
