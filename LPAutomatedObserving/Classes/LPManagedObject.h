#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#else
#import <Cocoa/Cocoa.h>
#endif


static NSString * const LPKeyValueChangeObjectKey = @"LPKeyValueChangeObjectKey";
static NSString * const LPKeyValueChangeKeyPathKey = @"LPKeyValueChangeKeyPathKey";
static NSString * const LPKeyValueChangeObservationInfoKey = @"LPKeyValueChangeObservationInfoKey";

@interface LPManagedObject : NSManagedObject {

	BOOL observingsActive;
}

@property (assign) BOOL observingsActive;
@end
