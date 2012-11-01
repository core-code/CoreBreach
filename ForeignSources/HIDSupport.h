

#include "HID_Utilities_External.h"

typedef struct action_struct {
	IOHIDDeviceRef fDeviceRef;
	IOHIDElementRef fElementRef;
	double cValue, lValue, pValue;
	double lMin, lMax, pMin, pMax, lRange, pRange;
} action_rec, *action_ptr;


#define kNumActions 12

@interface HIDSupport : NSObject 
{
@private
    CFMutableArrayRef ioHIDQueueRefsCFArrayRef;
    action_rec actionRecs[kNumActions];
    NSArray *hidDevices;
    BOOL started;
}

@property (readonly, nonatomic) NSArray *hidDevices;
@property (readonly, nonatomic) BOOL started;

+ (HIDSupport *)sharedInstance;
- (IBAction)saveConfiguration:(id)inSender;
- (IBAction)restoreConfiguration:(id)inSender;

- (void)startHID;
- (void)stopHID;

- (NSString *)configItem:(int)item forDevice:(NSDictionary *)dev;

- (NSString *)nameOfItem:(int)item;
- (double)valueOfItem:(int)item;
- (BOOL)isButton:(int)item;
- (BOOL)item:(uint8_t)item identicalToItem:(uint8_t)otherItem;
- (void)clearItem:(uint8_t)item;
- (void)printItem:(int)actionIndex;

@end
