#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#else
#import <Cocoa/Cocoa.h>
#endif

@class LPManagedObjectObservationInfo;
@interface LPManagedObjectContext : NSManagedObjectContext
{
	BOOL observingsActive;

	// dictionary ClassName -> NSArray with ObservationInfos
	// used by every class to identify necessary information for establishing observings
	NSMutableDictionary *dependendPropertiesObservationInfo;

}

@property (retain, nonatomic) NSMutableDictionary *dependendPropertiesObservationInfo;
@property (assign) BOOL observingsActive;

-(void) prepareDependentProperties;
@end
