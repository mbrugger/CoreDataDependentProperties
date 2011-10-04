#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <Foundation/Foundation.h>
#else
#import <Cocoa/Cocoa.h>
#endif


enum LPManagedObjectObservationInfoType {LPManagedObjectObservationInfoRelation = 1, LPManagedObjectObservationInfoProperty = 2};

@interface LPManagedObjectObservationInfo : NSObject 
{
	// class responsible for starting/stopping observation on awakeFromInsert/Fetch and willTurnIntoFault
	NSString* observerClassName;	
	
	// keypath for observer object (keypath to the observer relativ to the observed object)
	// in the delivered example "customer"
	NSString* observerObjectKeyPath;
	
	// keypath to property observed
	// in the delivered example "sum" and "alreadyPaid"
	NSString* observedPropertyKeyPath;
	
	// keypath to relation in observing
	NSString* observedRelationKeyPath;
	
	// selector name used to trigger updates
	NSString* updateSelectorName;
	
	// type of observing
		// LPManagedObjectObservationInfoRelation establishes self observing of the relation in the observer
		// LPManagedObjectObservationInfoProperty establishes observing of the relevant property in the observed object
	NSInteger observingType;
}

@property (retain, nonatomic) NSString* observerClassName;
@property (retain, nonatomic) NSString* observerObjectKeyPath;
@property (retain, nonatomic) NSString* observedPropertyKeyPath;
@property (retain, nonatomic) NSString* observedRelationKeyPath;
@property (retain, nonatomic) NSString* updateSelectorName;
@property (assign) NSInteger observingType;

-(SEL) updateSelector;

+(LPManagedObjectObservationInfo*) managedObjectObservationInfo;
@end
