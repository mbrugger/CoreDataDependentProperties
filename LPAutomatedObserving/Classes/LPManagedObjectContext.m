#import "LPManagedObjectContext.h"
#import "LPManagedObject.h"
#import <objc/runtime.h>
#if !TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
#import <objc/objc-runtime.h>
#endif
#import "LPManagedObjectObservationInfo.h"
#import "LPManagedObject_ObservationInfo.h"

#ifndef DEBUG_OBSERVING
#define DEBUG_OBSERVING 0
#endif

// this method is needed to properly restart observing in deleted objects after undo
// in 10.6 and iPhone OS a different solution is possible!
@interface NSManagedObjectContext (HiddenMethods)
- (void)_undoDeletions:(id)object;
@end

@interface LPManagedObjectContext (PrivateMethods)
-(void) processEntity:(NSEntityDescription*) entityDescription;
-(void) addObservationInfo:(LPManagedObjectObservationInfo*) newObservationInfo;
-(void) addObservationInfosFromArray:(NSArray*) observationInfos;
@end

#pragma mark -
@implementation LPManagedObjectContext
@synthesize dependendPropertiesObservationInfo;
@synthesize observingsActive;
@synthesize isMergingChanges;

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		observingsActive = YES;
		self.dependendPropertiesObservationInfo = nil;
	}
	return self;
}

- (void) dealloc
{
    // stop all observings
    [self stopObserving];
    
    
	// cleanup dictionary as last step after all managedObjects died
	// workaround necessary here?
	NSMutableDictionary * temporaryRetainedDictionary = [self.dependendPropertiesObservationInfo retain];
    [dependendPropertiesObservationInfo release], dependendPropertiesObservationInfo = nil;
	[super dealloc];
	[temporaryRetainedDictionary release];
	temporaryRetainedDictionary = nil;
}

#pragma mark Dependend properties specific code

// uses the ManagedObjectModel of the current ManagedObjectContext to scan all classes for relevant methods indicating dependencies with keyPathsForValuesAffectingDerived<Key>
// creates LPManagedObjectObservationInfo objects for each dependency found
// does basic validation of given information
-(void) prepareDependentProperties
{
	NSAssert(self.dependendPropertiesObservationInfo == nil, @"preparedDependendProperties must not be called twice");
	NSAssert([self persistentStoreCoordinator] != nil, @"Error missing persistentStoreCoordinator");
	NSAssert([[self persistentStoreCoordinator] managedObjectModel] != nil, @"Error missing managedObjectModel");
	
	self.dependendPropertiesObservationInfo = [NSMutableDictionary dictionary];
	
	NSManagedObjectModel *managedObjectModel = [[self persistentStoreCoordinator] managedObjectModel];	

	// check each entity in object model for dependend properties
	for (NSString* entityName in [[managedObjectModel entitiesByName] allKeys])
	{
		NSEntityDescription* entity = [[managedObjectModel entitiesByName] objectForKey:entityName];
		NSString *className = [entity managedObjectClassName];
		Class entityClass = NSClassFromString(className);
		
		// only process classes inherited from LPManagedObject
		if ([entityClass isInheritedFromClass:[LPManagedObject class]])
		{
			if (DEBUG_OBSERVING) NSLog(@"willAnalyze: %@", entityClass);
			[self processEntity:entity];
		}
	}	
}

- (void)startObserving
{
    self.observingsActive = YES;
    for (LPManagedObject *object in self.registeredObjects)
    {
        if ([object isKindOfClass:[LPManagedObject class]] && ![object isFault])
        {
            [object startObserving];
        }
    }
    if (DEBUG_OBSERVING) NSLog(@"all observings started");
}

- (void)stopObserving
{
    self.observingsActive = NO;
    for (LPManagedObject *object in self.registeredObjects)
    {
        if ([object isKindOfClass:[LPManagedObject class]] && object.observingsActive)
        {
            [object stopObserving];
        }
    }

    if (DEBUG_OBSERVING) NSLog(@"all observings stopped");    
}


@end

#pragma mark -
@implementation LPManagedObjectContext (PrivateMethods)

-(void) processEntity:(NSEntityDescription*) entityDescription
{
	// get class of entity
	Class managedObjectClass = NSClassFromString([entityDescription managedObjectClassName]);
	
	//process class if inherited from LPManagedObject
	if ([managedObjectClass isInheritedFromClass: [LPManagedObject class]])
	{
		NSArray* propertiesWithDependencyInformation = [managedObjectClass propertiesWithDependencyInformation];
		for (NSString* propertyName in propertiesWithDependencyInformation)
		{
			NSArray* observerInformationForProperty = [managedObjectClass observerInformationForProperty:propertyName withEntityDescription: entityDescription];
			[self addObservationInfosFromArray:observerInformationForProperty];
		}
	}
}

-(void) addObservationInfosFromArray:(NSArray*) observationInfos
{
	for (LPManagedObjectObservationInfo* newObservationInfo in observationInfos)
	{
		[self addObservationInfo:newObservationInfo];
	}
}

// adds observation info to the internal observation info dictionary
-(void) addObservationInfo:(LPManagedObjectObservationInfo*) newObservationInfo
{   
    if (DEBUG_OBSERVING)
    {
        NSLog(@"add observer information: %@", newObservationInfo);
    }
	NSMutableArray* observationInfosForClass = [self.dependendPropertiesObservationInfo objectForKey:newObservationInfo.observerClassName];
	if (observationInfosForClass == nil)
	{
		observationInfosForClass = [NSMutableArray array];
		[self.dependendPropertiesObservationInfo setObject:observationInfosForClass forKey:newObservationInfo.observerClassName];
	}
	[observationInfosForClass addObject:newObservationInfo];
}


// needed for 10.5 backwards compatibility
// in 10.6 use
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
	#if (__MAC_OS_X_VERSION_MIN_REQUIRED < 1060)

#error Make sure you really want to use this code!
- (void)_undoDeletions:(id)deletions
{
	[super _undoDeletions:deletions];
	@try
	{
		for (id deletion in deletions)
        {
            if([deletion isKindOfClass:[NSManagedObject class]])
            {    
                [deletion awakeFromFetch]; // treating this as a fetch works for my purposes
            }
            else if ([deletion isKindOfClass:[NSArray class]])
            {
                for(id object in deletion)
                {
                    if([object isKindOfClass:[NSManagedObject class]])
                        [object awakeFromFetch]; // treating this as a fetch works for my purposes
                }
            }
        }
	}
	@catch (NSException *exception)
	{
		
	}
}
	#endif
#endif

- (void)mergeChangesFromContextDidSaveNotification:(NSNotification *)notification
{
    @try 
    {
        self.isMergingChanges = YES;
        [self stopObserving];
        [super mergeChangesFromContextDidSaveNotification:notification];
    }
    @catch (NSException *exception) 
    {
        [exception raise];
    }
    @finally 
    {
        self.isMergingChanges = NO;
        [self startObserving];
    }
}
@end 

