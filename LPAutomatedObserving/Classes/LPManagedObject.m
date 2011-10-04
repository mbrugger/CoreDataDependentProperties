#import "LPManagedObject.h"
#import "LPManagedObjectContext.h"
#import "LPManagedObjectObservationInfo.h"

#import <objc/runtime.h>
#if !TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
#import <objc/objc-runtime.h>
#endif

#ifndef DEBUG_OBSERVING
#define DEBUG_OBSERVING 0
#endif

@implementation LPManagedObject
@synthesize observingsActive;

#pragma mark -
#pragma mark NSManagedObject overridden methods


// collect all observation Infos also for inherited classes
- (NSArray *)observationInfos
{
	LPManagedObjectContext* context = (LPManagedObjectContext*)[self managedObjectContext];
	NSMutableArray *customObservationInfos = [NSMutableArray array];
	
	Class currentClass = [self class];
	do
	{
		NSArray* currentClassObservationInfos = [context.dependendPropertiesObservationInfo objectForKey:NSStringFromClass(currentClass)];
		[customObservationInfos addObjectsFromArray:currentClassObservationInfos];
		
		currentClass = class_getSuperclass(currentClass);
	} while (currentClass != nil && currentClass != [LPManagedObject class]);
  
	return [NSArray arrayWithArray: customObservationInfos];
}

-(void) startObserving
{	
	LPManagedObjectContext* context = (LPManagedObjectContext*)[self managedObjectContext];
	if (![context isKindOfClass:[LPManagedObjectContext class]])
	{
		// do not start observing in other managed object contexts
		return;
	}
  
	if (!self.observingsActive)
	{
		NSAssert1([context isKindOfClass:[LPManagedObjectContext class]], @"error expected LPManagedObjectContext got %@", context);
		self.observingsActive = YES;		
		NSArray* customObservationInfos = [self observationInfos];
		for (LPManagedObjectObservationInfo* customObservationInfo in customObservationInfos)
		{
			id observer = [self valueForKey:customObservationInfo.observerObjectKeyPath];
			
			//wrap observer into a set
			//support for to-one relation observing
			if (observer != nil && ![observer isKindOfClass:[NSSet class]])
			{
				observer = [NSSet setWithObject:observer];
			}
			
			NSString* observationKeyPath = nil;
			if (customObservationInfo.observingType == LPManagedObjectObservationInfoRelation)
				observationKeyPath = customObservationInfo.observedRelationKeyPath;
			else
				observationKeyPath = customObservationInfo.observedPropertyKeyPath;
			
			for (LPManagedObject* observerObject in observer)
			{
        if (DEBUG_OBSERVING) {
          NSString *observerClassName = nil;
          NSString *selfClassName = nil;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
          observerClassName = NSStringFromClass([observer class]);
          selfClassName = NSStringFromClass([self class]);
#else
          observerClassName = [observer className];
          selfClassName = [self className];
#endif
          NSLog(@"startObserving <%p %@> observes <%p %@> keyPath: %@", observer, observerClassName, self, selfClassName, observationKeyPath);
        }
				[self addObserver: observerObject
               forKeyPath:observationKeyPath
                  options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) 
                  context:customObservationInfo];
			}
		}
	}
}

-(void) stopObserving
{
	LPManagedObjectContext* context = (LPManagedObjectContext*)[self managedObjectContext];
	if (![context isKindOfClass:[LPManagedObjectContext class]])
	{
		// do not stop observing in other managed object contexts
		return;
	}
	
	if (self.observingsActive)
	{
    
		NSAssert1([context isKindOfClass:[LPManagedObjectContext class]], @"error expected LPManagedObjectContext got %@", context);
		
		NSArray* customObservationInfos = [self observationInfos];
		for (LPManagedObjectObservationInfo* customObservationInfo in customObservationInfos)
		{	
			id observer = [self valueForKey:customObservationInfo.observerObjectKeyPath];
      
			//wrap observer into a set
			//support for to-one relation observing
			if (observer != nil && ![observer isKindOfClass:[NSSet class]])
			{
				observer = [NSSet setWithObject:observer];
			}
			
			NSString* observationKeyPath = nil;
			if (customObservationInfo.observingType == LPManagedObjectObservationInfoRelation)
				observationKeyPath = customObservationInfo.observedRelationKeyPath;
			else
				observationKeyPath = customObservationInfo.observedPropertyKeyPath;
			
			for (LPManagedObject* observerObject in observer)
			{
        if (DEBUG_OBSERVING) {
          NSString *observerClassName = nil;
          NSString *selfClassName = nil;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
          observerClassName = NSStringFromClass([observer class]);
          selfClassName = NSStringFromClass([self class]);
#else
          observerClassName = [observer className];
          selfClassName = [self className];
#endif        
          NSLog(@"stopObserving <%p %@> observes <%p %@> keyPath: %@", observer, observerClassName, self, selfClassName, observationKeyPath);
        }
				[self removeObserver:observerObject
                  forKeyPath:observationKeyPath];
			}
		}
		
		if ([self observationInfo] != nil)
		{
			if (DEBUG_OBSERVING) NSLog(@"stopObserving failed: %@", [self observationInfo]);
		}
		self.observingsActive = NO;
	}
}

-(void) awakeFromFetch
{
	[super awakeFromFetch];
	[self startObserving];
}

-(void) awakeFromInsert
{
	[super awakeFromInsert];
	[self startObserving];
	
}

// awakeFromSnapshotEvents was introduced in 10.6
// workaround for missing method in LPManagedObjectContext.m
// - (void)_undoDeletions:(id)deletions;
#if ((defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED >= 1060) || TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
	[super awakeFromSnapshotEvents:flags];
	[self startObserving];
}

#endif

-(void) willTurnIntoFault
{
	[self stopObserving];
	[super willTurnIntoFault];
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	LPManagedObjectContext* managedObjectContext = (LPManagedObjectContext*) self.managedObjectContext;	
	
	LPManagedObjectObservationInfo *observationInfo = (LPManagedObjectObservationInfo *)context;
	if (observationInfo != nil && [observationInfo isKindOfClass:[LPManagedObjectObservationInfo class]])
	{
		if (![managedObjectContext isKindOfClass:[LPManagedObjectContext class]])
		{
			// do not handle observing if context is not an LPManagedObjectContext
			return;
		}
		
		NSMutableDictionary *observingChanges = [NSMutableDictionary dictionaryWithDictionary:change];
		[observingChanges setObject:object forKey:LPKeyValueChangeObjectKey];
		[observingChanges setObject:keyPath forKey:LPKeyValueChangeKeyPathKey];
		[observingChanges setObject:observationInfo forKey:LPKeyValueChangeObservationInfoKey];
		
		
		//handle auto observing
		if (object == self)
		{
			// this is always the to many relation self observings
      if (DEBUG_OBSERVING) {
        NSString *objectClassName = nil;
        NSString *selfClassName = nil;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
        objectClassName = NSStringFromClass([object class]);
        selfClassName = NSStringFromClass([self class]);
#else
        objectClassName = [object className];
        selfClassName = [self className];
#endif
        
        NSLog(@"Observing Relation <%p %@> keyPath: %@ object: <%p %@>", self, selfClassName, keyPath, object, objectClassName);
      }
			id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
			id newValue = [change objectForKey:NSKeyValueChangeNewKey];
			
			if (![oldValue isEqual:[NSNull null]] && oldValue != nil)
			{
				// if relation is to-one wrap object into set
				if (![oldValue isKindOfClass:[NSSet class]])
					oldValue = [NSSet setWithObject:oldValue];
				
				// disable observing
				for (id object in oldValue)
				{
					[object removeObserver: self
                      forKeyPath:observationInfo.observedPropertyKeyPath];
				}
			}
			
			if (![newValue isEqual:[NSNull null]] && newValue != nil)
			{
				// if relation is to-one wrap object into set
				if (![newValue isKindOfClass:[NSSet class]])
					newValue = [NSSet setWithObject:newValue];				
				
				//establish observing
				for (id object in newValue)
				{
					[object addObserver: self
                   forKeyPath:observationInfo.observedPropertyKeyPath 
                      options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) 
                      context:observationInfo];	
				}
			}
			if ([managedObjectContext isKindOfClass:[LPManagedObjectContext class]] && managedObjectContext.observingsActive)
			{
				[self performSelector:[observationInfo updateSelector] withObject:observingChanges];
			}
		}
		else
		{
      if (DEBUG_OBSERVING) {
        NSString *objectClassName = nil;
        NSString *selfClassName = nil;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
        objectClassName = NSStringFromClass([object class]);
        selfClassName = NSStringFromClass([self class]);
#else
        objectClassName = [object className];
        selfClassName = [self className];
#endif      
        NSLog(@"Observing Property <%p %@> keyPath: %@ object: <%p %@>", self, selfClassName, keyPath, object, objectClassName);
      }
			if ([managedObjectContext isKindOfClass:[LPManagedObjectContext class]] && managedObjectContext.observingsActive)
			{
				[self performSelector:[observationInfo updateSelector] withObject:observingChanges];
			}
		}
	}
}

@end

