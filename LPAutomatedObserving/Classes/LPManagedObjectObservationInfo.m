#import "LPManagedObjectObservationInfo.h"


@implementation LPManagedObjectObservationInfo

@synthesize observerClassName;
@synthesize observerObjectKeyPath;
@synthesize observedPropertyKeyPath;
@synthesize observedRelationKeyPath;
@synthesize updateSelectorName;
@synthesize observingType;

+(LPManagedObjectObservationInfo*) managedObjectObservationInfo
{
	LPManagedObjectObservationInfo* observationInfo = [[[LPManagedObjectObservationInfo alloc] init] autorelease];
	return observationInfo;
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		self.observingType = LPManagedObjectObservationInfoRelation;
	}
	return self;
}

- (void) dealloc
{
	self.observerClassName = nil;
	self.observerObjectKeyPath = nil;
	self.observedPropertyKeyPath = nil;
	self.observedRelationKeyPath = nil;
	self.updateSelectorName = nil;

	[super dealloc];
}

-(NSString*) description
{
	NSMutableString* description = [NSMutableString stringWithCapacity:128];
	[description appendFormat:@"observerClassName: %@, ", self.observerClassName];
	[description appendFormat:@"observingType: %@, ", self.observingType == LPManagedObjectObservationInfoRelation?@"relation":@"property"];
	[description appendFormat:@"observerObjectKeyPath: %@, ", self.observerObjectKeyPath];
	[description appendFormat:@"observedPropertyKeyPath: %@, ", self.observedPropertyKeyPath];
	[description appendFormat:@"observedRelationKeyPath: %@, ", self.observedRelationKeyPath];
	[description appendFormat:@"updateSelectorName: %@, ", self.updateSelectorName];
	return description;
}

-(SEL) updateSelector
{
	NSString *selectorName = [self.updateSelectorName stringByAppendingString:@"ForChange:"];
	return NSSelectorFromString(selectorName);
}

@end
