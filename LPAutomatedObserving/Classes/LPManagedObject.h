#import <Cocoa/Cocoa.h>

@interface LPManagedObject : NSManagedObject {

	BOOL observingsActive;
}

@property (assign) BOOL observingsActive;
@end
