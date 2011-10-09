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
    [description appendFormat:@"<%@: %p> {\n", [self className], self];
	[description appendFormat:@"\t      observerClassName: %@\n", self.observerClassName];
	[description appendFormat:@"\t          observingType: %@\n", self.observingType == LPManagedObjectObservationInfoRelation?@"relation":@"property"];
	[description appendFormat:@"\t  observerObjectKeyPath: %@\n", self.observerObjectKeyPath];
	[description appendFormat:@"\tobservedPropertyKeyPath: %@\n", self.observedPropertyKeyPath];
	[description appendFormat:@"\tobservedRelationKeyPath: %@\n", self.observedRelationKeyPath];
	[description appendFormat:@"\t     updateSelectorName: %@\n", self.updateSelectorName];
    [description appendFormat:@"\t}"];
	return description;
}

-(SEL) updateSelector
{
	NSString *selectorName = [self.updateSelectorName stringByAppendingString:@"ForChange:"];
	return NSSelectorFromString(selectorName);
}

@end
