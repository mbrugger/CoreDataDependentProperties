#import "LPManagedObject_ObservationInfo.h"
#import <objc/objc-runtime.h>
#import <objc/runtime.h>
#import "LPManagedObjectObservationInfo.h"


static NSString* const LPManagedObjectInterestingSelectorPrefix = @"keyPathsForValuesAffectingDerived";


@interface LPManagedObject (ObservationInfoPrivate)

// can be made private
// returns a list of keyPaths with dependency information for a given property name
+(NSArray*) dependencyKeyPathsForProperty:(NSString*) propertyName;

// returns the update selector name for given property name
+(NSString*) updateSelectorNameForProperty:(NSString*) propertyName;

// returns the property name of a given selector
// requires the selector to follow keyPathsForValuesAffectingDerived<Key>
+(NSString*) propertyNameFromInterestingSelector:(SEL) interestingSelector;



// checks if givenSelector is matching naming convention with given prefix
+(BOOL) selector:(SEL) givenSelector matchesPrefix:(NSString*) prefix;
@end

#pragma mark -

@implementation LPManagedObject (ObservationInfo)


+(NSArray*) propertiesWithDependencyInformation
{
	NSMutableArray* propertiesWithDependencyInformation = nil;
	
	unsigned int total_method_count = 0;
	Method * method_list = class_copyMethodList(object_getClass([self class]), &total_method_count);
	@try
	{
		int method_counter = 0;
		for (method_counter = 0; method_counter < total_method_count; method_counter++)
		{
			Method method = method_list[method_counter];
			if ([LPManagedObject selector:method_getName(method) matchesPrefix:LPManagedObjectInterestingSelectorPrefix])
			{
				// only create array if dependency information is found
				if (propertiesWithDependencyInformation == nil)
					propertiesWithDependencyInformation = [NSMutableArray array];
				
				NSLog(@"foundPrefix");
				NSString* propertyName = [LPManagedObject propertyNameFromInterestingSelector:method_getName(method)];
				[propertiesWithDependencyInformation addObject:propertyName];
			}
		}
	}
	@catch (NSException * e)
	{
		@throw(e);
	}
	@finally
	{
		if (method_list != NULL)
		{
			free(method_list);
			method_list = NULL;
		}
	}
	
	return propertiesWithDependencyInformation;
}

+(NSArray*) observerInformationForProperty:(NSString*) propertyName withEntityDescription:(NSEntityDescription*) entityDescription
{
	NSMutableArray* observerInformation = [NSMutableArray array];
	NSString* updateSelectorName = [[self class] updateSelectorNameForProperty:propertyName];
	
	// as with standard KVO each property might be dependend on multiple keyPaths
	NSArray* dependencyKeyPaths = [[self class] dependencyKeyPathsForProperty:propertyName];			
	for (NSString* dependencyKeyPath in dependencyKeyPaths)
	{
		NSArray* keyPathComponents = [dependencyKeyPath componentsSeparatedByString:@"."];
		// limitation for simplicity, could also work with additional keyPath elements if they are to-one relations
		if (keyPathComponents.count != 2)
			[NSException raise:@"LPManagedObject - keyPathsForValuesAffectingDerived<Key>"  format:@"invalid keyPath: \"%@\" keyPath components.count == 2",dependencyKeyPath];
		
		NSString* relationPathComponent = [keyPathComponents objectAtIndex:0];
		NSRange remainingKeyPathRange = NSMakeRange(1, keyPathComponents.count -1);
		NSArray* remainingKeyPathComponents = [keyPathComponents subarrayWithRange:remainingKeyPathRange];
		NSString* remainingKeyPath = [remainingKeyPathComponents componentsJoinedByString:@"."];
		
		NSRelationshipDescription* relationshipDescription = [[entityDescription relationshipsByName] objectForKey:relationPathComponent];
		if (relationshipDescription == nil)
			[NSException raise:@"LPManagedObject - keyPathsForValuesAffectingDerived<Key>"  format:@"invalid keyPath: \"%@\", \"%@\" is not a valid relation",dependencyKeyPath, relationPathComponent];
		
		// create property observing established by observed class
		// observed object responsible for informing superclass of changed properties
		// if observed object turns into fault observing is deactivated as it could not be changed anyways
		// turning into fault would issue a change notification which can not be handled on context teardown
		LPManagedObjectObservationInfo* propertyObservingInfo = [LPManagedObjectObservationInfo managedObjectObservationInfo];
		
		propertyObservingInfo.observerClassName = [[relationshipDescription destinationEntity] managedObjectClassName];
		propertyObservingInfo.observerObjectKeyPath = [[relationshipDescription inverseRelationship] name];				
		propertyObservingInfo.observedPropertyKeyPath = remainingKeyPath;
		propertyObservingInfo.observedRelationKeyPath = relationPathComponent;
		propertyObservingInfo.observingType = LPManagedObjectObservationInfoProperty;
		propertyObservingInfo.updateSelectorName = updateSelectorName;
		
		[observerInformation addObject:propertyObservingInfo];
		
		// create relation observing established by observer
		// observer responsible for observing additional objects in its relation
		LPManagedObjectObservationInfo* relationObservingInfo = [LPManagedObjectObservationInfo managedObjectObservationInfo];
		
		relationObservingInfo.observerClassName = [entityDescription managedObjectClassName];
		relationObservingInfo.observerObjectKeyPath = @"self";
		relationObservingInfo.observedPropertyKeyPath = remainingKeyPath;
		relationObservingInfo.observedRelationKeyPath = relationPathComponent;
		relationObservingInfo.observingType = LPManagedObjectObservationInfoRelation;
		relationObservingInfo.updateSelectorName = updateSelectorName;
		
		[observerInformation addObject:relationObservingInfo];
		
	}
	return observerInformation;
}

+(BOOL) isInheritedFromClass:(Class) baseClass
{
	Class currentClass = [self class];
	do
	{
		currentClass = class_getSuperclass(currentClass);
	} while (currentClass != nil && currentClass != baseClass);
	
	if (currentClass == baseClass)
	{
		return YES;
	}
	
	return NO;
}

@end

#pragma mark -

@implementation LPManagedObject (ObservationInfoPrivate)

+(NSString*) uppercaseFirstLetterPropertyName:(NSString*) propertyName
{
	NSString* firstCharacter = [propertyName substringToIndex:1];
	NSString* remainingCharacters = [propertyName substringFromIndex:1];
	return [NSString stringWithFormat:@"%@%@", [firstCharacter uppercaseString], remainingCharacters];
}

+(NSArray*) dependencyKeyPathsForProperty:(NSString*) propertyName
{
	NSString* upperCasePropertyName = [self uppercaseFirstLetterPropertyName:propertyName];
	// create selector keyPathsForValuesAffectingDerived<Key>
	NSString* dependencyKeyPathSelectorName = [NSString stringWithFormat:@"%@%@", LPManagedObjectInterestingSelectorPrefix, upperCasePropertyName];
	SEL dependencyKeyPathSelector = NSSelectorFromString(dependencyKeyPathSelectorName);
	
	// check if class responds to selector
	
	if ([self respondsToSelector: dependencyKeyPathSelector])
		return [self performSelector: dependencyKeyPathSelector];
	
	return nil;
}

+(NSString*) propertyNameFromInterestingSelector:(SEL) interestingSelector
{	
	NSString* selectorAsString = NSStringFromSelector(interestingSelector);
	NSString* dirtyPropertyName = [selectorAsString substringFromIndex:LPManagedObjectInterestingSelectorPrefix.length];
	NSString* firstCharacter = [dirtyPropertyName substringToIndex:1];
	NSString* cleanPropertyName = [NSString stringWithFormat:@"%@%@", [firstCharacter lowercaseString], [dirtyPropertyName substringFromIndex:1]];
	return cleanPropertyName;								   
}


+(NSString*) updateSelectorNameForProperty:(NSString*) propertyName
{
	NSString* upperCasePropertyName = [self uppercaseFirstLetterPropertyName:propertyName];
	NSString* updateSelectorName = [NSString stringWithFormat:@"%@%@", @"updateDerived", upperCasePropertyName];
	return updateSelectorName;								   
}


+(BOOL) selector:(SEL) givenSelector matchesPrefix:(NSString*) prefix
{
	NSString* selectorAsString = NSStringFromSelector(givenSelector);
	if ([selectorAsString hasPrefix:prefix])
	{
		return YES;
	}
	return NO;
	
}

@end

