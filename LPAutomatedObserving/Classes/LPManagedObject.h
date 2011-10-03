#import <Cocoa/Cocoa.h>

static NSString * const LPKeyValueChangeObjectKey = @"LPKeyValueChangeObjectKey";
static NSString * const LPKeyValueChangeKeyPathKey = @"LPKeyValueChangeKeyPathKey";
static NSString * const LPKeyValueChangeObservationInfoKey = @"LPKeyValueChangeObservationInfoKey";

@interface LPManagedObject : NSManagedObject {

	BOOL observingsActive;
}

@property (assign) BOOL observingsActive;
@end
