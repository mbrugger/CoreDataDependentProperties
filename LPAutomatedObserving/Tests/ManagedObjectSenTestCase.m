#import "ManagedObjectSenTestCase.h"
#import "LPManagedObjectContext.h"


@implementation ManagedObjectSenTestCase

@synthesize coordinator;
@synthesize context;
@synthesize model;



-(void) setUp
{
	pool = [[NSAutoreleasePool alloc] init];
	
	NSMutableSet *allBundles = [[[NSMutableSet alloc] init] autorelease];
	[allBundles addObjectsFromArray:[NSBundle allBundles]];
	
	NSBundle* bundle = [NSBundle bundleWithIdentifier:@"at.nimblo.LPAutmatedObserving.ModelTest"];
	//NSLog(@"bundle: %@", bundle);
	NSString* path = [bundle pathForResource:@"LPAutomatedObserving_DataModel"
																							ofType:@"mom"];
	//NSLog(@"path: %@", path);
	NSURL* modelURL = [NSURL URLWithString:path];
	self.model = [[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL] autorelease];
	
	self.coordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model] autorelease];
	
	
	LPManagedObjectContext* tempContext = [[[LPManagedObjectContext alloc] init] autorelease];
	

	[tempContext setPersistentStoreCoordinator:coordinator];
	[tempContext setRetainsRegisteredObjects:YES];
	[tempContext prepareDependentProperties];	
	
	self.context = tempContext;
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
