//
//  HIDSupport.h
//  CoreBreach
//
//  Created by CoreCode on 08.11.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//


typedef struct action_struct {
    NSString *deviceName;
	int deviceIndex;
	int actionType;
	int actionIndex;
	double value;
} action_rec;

#define kNumActions 12

@interface HIDSupport : NSObject {
@private
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

- (void)handleEvent:(SDL_Event)event;

- (NSString *)configItem:(int)item forDevice:(NSDictionary *)dev;

- (NSString *)nameOfItem:(int)item;
- (double)valueOfItem:(int)item;
- (BOOL)isButton:(int)item;
- (BOOL)item:(uint8_t)item identicalToItem:(uint8_t)otherItem;
- (void)clearItem:(uint8_t)item;

- (void)printItem:(int)actionIndex;

@end
