#import <Cocoa/Cocoa.h>

static NSString * const LPKeyValueChangeObjectKey = @"LPKeyValueChangeObjectKey";
static NSString * const LPKeyValueChangeKeyPathKey = @"LPKeyValueChangeKeyPathKey";

@interface LPManagedObject : NSManagedObject {

	BOOL observingsActive;
}

@property (assign) BOOL observingsActive;
@end
