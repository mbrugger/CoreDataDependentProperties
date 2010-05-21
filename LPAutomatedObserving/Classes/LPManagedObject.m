#import "LPManagedObject.h"
#import "LPManagedObjectContext.h"
#import "LPManagedObjectObservationInfo.h"

#ifndef DEBUG_OBSERVING
#define DEBUG_OBSERVING 0
#endif

@implementation LPManagedObject
@synthesize observingsActive;

#pragma mark -
#pragma mark NSManagedObject overridden methods

-(void) startObserving
{	
	if (!self.observingsActive)
	{
		self.observingsActive = YES;
		LPManagedObjectContext* context = (LPManagedObjectContext*)[self managedObjectContext];
		NSAssert1([context isKindOfClass:[LPManagedObjectContext class]], @"error expected LPManagedObjectContext got %@", context);
		
		NSArray* customObservationInfos = [context.dependendPropertiesObservationInfo objectForKey:[self className]];
		for (LPManagedObjectObservationInfo* customObservationInfo in customObservationInfos)
		{
			id observer = [self valueForKey:customObservationInfo.observerObjectKeyPath];
			
			NSString* observationKeyPath = nil;
			if (customObservationInfo.observingType == LPManagedObjectObservationInfoRelation)
				observationKeyPath = customObservationInfo.observedRelationKeyPath;
			else
				observationKeyPath = customObservationInfo.observedPropertyKeyPath;
			
			if (observer != nil)
			{
				if (DEBUG_OBSERVING) NSLog(@"startObserving <%p %@> observes <%p %@> keyPath: %@", observer, [observer className], self, [self className], observationKeyPath);
				[self addObserver: observer
					   forKeyPath:observationKeyPath
						  options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) 
						  context:customObservationInfo];
			}
		}
	}
}

-(void) stopObserving
{
	if (self.observingsActive)
	{
		LPManagedObjectContext* context = (LPManagedObjectContext*)[self managedObjectContext];
		NSAssert1([context isKindOfClass:[LPManagedObjectContext class]], @"error expected LPManagedObjectContext got %@", context);
		
		NSArray* customObservationInfos = [context.dependendPropertiesObservationInfo objectForKey:[self className]];
		for (LPManagedObjectObservationInfo* customObservationInfo in customObservationInfos)
		{	
			id observer = [self valueForKey:customObservationInfo.observerObjectKeyPath];
			
			NSString* observationKeyPath = nil;
			if (customObservationInfo.observingType == LPManagedObjectObservationInfoRelation)
				observationKeyPath = customObservationInfo.observedRelationKeyPath;
			else
				observationKeyPath = customObservationInfo.observedPropertyKeyPath;
			
			if (observer != nil)
			{
				if (DEBUG_OBSERVING) NSLog(@"stopObserving <%p %@> observes <%p %@> keyPath: %@", observer, [observer className], self, [self className], observationKeyPath);
				[self removeObserver:observer
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
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
	#if !(__MAC_OS_X_VERSION_MIN_REQUIRED < 1060)
- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
	[super awakeFromSnapshotEvents:flags];
	[self startObserving];
}
	#endif
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
		//handle auto observing
		if (object == self)
		{
			// this is always the to many relation self observings
			if (DEBUG_OBSERVING) NSLog(@"Observing Relation <%p %@> keyPath: %@ object: <%p %@>", self, [self className], keyPath, object, [object className]);
			id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
			id newValue = [change objectForKey:NSKeyValueChangeNewKey];
			
			if (![oldValue isEqual:[NSNull null]] && oldValue != nil)
			{
				// disable observing
				for (id object in oldValue)
				{
					[object removeObserver: self
								forKeyPath:observationInfo.observedPropertyKeyPath];
				}
			}
			
			if (![newValue isEqual:[NSNull null]] && newValue != nil)
			{
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
				[self performSelector:NSSelectorFromString(observationInfo.updateSelectorName)];
		}
		else
		{
			if (DEBUG_OBSERVING) NSLog(@"Observing Property <%p %@> keyPath: %@ object: <%p %@>", self, [self className], keyPath, object, [object className]);
			if ([managedObjectContext isKindOfClass:[LPManagedObjectContext class]] && managedObjectContext.observingsActive)
				[self performSelector:NSSelectorFromString(observationInfo.updateSelectorName)];
		}
	}
}

@end

