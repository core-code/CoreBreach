//
//  HIDSupport_SDL.m
//  CoreBreach
//
//  Created by CoreCode on 08.11.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "HIDSupport_SDL.h"
#include <strings.h>

HIDSupport *sharedhid = nil;

@implementation HIDSupport

@synthesize hidDevices, started;

+ (HIDSupport *)sharedInstance
{
	if (sharedhid == nil)
		fatal("HIDSupport not allocated");
    
	return sharedhid;
}

- (void)dealloc
{
    //NSLog(@"hid dealloc");
    sharedhid = nil;

    
    for (int i = 0; i < kNumActions; i++)
    {
        [actionRecs[i].deviceName release];                
    }
    
    [hidDevices release];
    [super dealloc];
}

- (IBAction)saveConfiguration:(id)inSender
{
    for (int i = 0; i < kNumActions; i++)
    {   
        if (actionRecs[i].deviceName)
            $setdefault(actionRecs[i].deviceName, $stringf(@"HID_%i_deviceName", i));
        else
            $remdefault($stringf(@"HID_%i_deviceName", i));
        $setdefaulti(actionRecs[i].actionIndex, $stringf(@"HID_%i_actionIndex", i));
        $setdefaulti(actionRecs[i].actionType, $stringf(@"HID_%i_actionType", i));
    }
}

- (IBAction)restoreConfiguration:(id)inSender
{
    for (int i = 0; i < kNumActions; i++)
    {
        NSString *deviceName = $default($stringf(@"HID_%i_deviceName", i));
        int actionType = $defaulti($stringf(@"HID_%i_actionType", i));
        int actionIndex =  $defaulti($stringf(@"HID_%i_actionIndex", i));
        
        actionRecs[i].deviceIndex = -1;
        
        for (NSDictionary *dev in hidDevices)
        {
            if ([[dev objectForKey:@"name"] isEqualToString:deviceName])
            {
                actionRecs[i].deviceName = [deviceName copy];
                actionRecs[i].actionType = actionType;
                actionRecs[i].actionIndex = actionIndex;                
                actionRecs[i].deviceIndex = [[dev objectForKey:@"index"] intValue];                
            }    
        }
    }
}

- (BOOL)isButton:(int)item
{
   if (actionRecs[item].actionType == SDL_JOYBUTTONDOWN)
       return YES;
    else
        return NO;
}

- (NSString *)configItem:(int)item forDevice:(NSDictionary *)dev
{
    assert(SDL_WasInit(SDL_INIT_JOYSTICK));

    int devindex = [[dev objectForKey:@"index"] intValue];
    int times = 0;
    SDL_Event event;
    SDL_Joystick *joystick = SDL_JoystickOpen(devindex);   
 
    
    while (times < 100)
    {
        while (SDL_PollEvent(&event))
        {
            switch( event.type )
            {
                case SDL_JOYBUTTONDOWN:  /* Handle Joystick Button Presses */ // we save the type for buttons as SDL_JOYBUTTONDOWN
                case SDL_JOYAXISMOTION:  /* Handle Joystick Motion */
                {
//                    NSLog(@"got event %i", event.type);

                    if (((event.type == SDL_JOYAXISMOTION) && (event.jaxis.which == devindex)) ||
                        ((event.type == SDL_JOYBUTTONDOWN) && (event.jbutton.which == devindex)))
                    {
                        actionRecs[item].deviceName = [[dev objectForKey:@"name"] copy];
                        actionRecs[item].deviceIndex = devindex;      
                        actionRecs[item].actionType = event.type;
                        actionRecs[item].actionIndex = (event.type == SDL_JOYAXISMOTION) ? event.jaxis.axis : event.jbutton.button;                
                        
                        SDL_JoystickClose(joystick);   

                        return [self nameOfItem:item];
                    }
                }
                default:
                    break;
            }
        }
        SDL_Delay(50);
    }
    SDL_JoystickClose(joystick);   

    return nil;
}

- (NSString *)nameOfItem:(int)item
{
    if (actionRecs[item].deviceIndex >= 0 && 
        (actionRecs[item].actionType == SDL_JOYBUTTONDOWN || actionRecs[item].actionType == SDL_JOYAXISMOTION))
    {
        return $stringf(@"%@ %i", (actionRecs[item].actionType == SDL_JOYBUTTONDOWN) ? @"Button" : @"Axis", actionRecs[item].actionIndex);
    }
    else 
        return nil;
}

- (double)valueOfItem:(int)item
{
    return actionRecs[item].value;
}


- (BOOL)item:(uint8_t)item identicalToItem:(uint8_t)otherItem
{
    return ((actionRecs[item].deviceIndex == actionRecs[otherItem].deviceIndex) &&
            (actionRecs[item].actionIndex == actionRecs[otherItem].actionIndex) && 
            (actionRecs[item].actionType == actionRecs[otherItem].actionType));
}

- (void)printItem:(int)item
{
    NSLog(@"item number %i name %@ deviceName %@ deviceIndex %i actionType %i actionIndex %i", item, [self nameOfItem:item], actionRecs[item].deviceName, actionRecs[item].deviceIndex, actionRecs[item].actionType, actionRecs[item].actionIndex);
}

- (void)clearItem:(uint8_t)item
{    
    actionRecs[item].deviceName = nil;
    actionRecs[item].deviceIndex = 0;
    actionRecs[item].actionType = 0;
    actionRecs[item].actionIndex = -1;
    actionRecs[item].value = 0.0;
}

- (void)handleEvent:(SDL_Event)event
{
   // NSLog(@"got handleevent %i", event.type);

    switch( event.type )
    {
        case SDL_JOYBUTTONDOWN:  /* Handle Joystick Button Presses */
        case SDL_JOYBUTTONUP:  /* Handle Joystick Button Presses */
        case SDL_JOYAXISMOTION:  /* Handle Joystick Motion */
        {
            int actionIndex = (event.type == SDL_JOYAXISMOTION) ? event.jaxis.axis : event.jbutton.button;
            int deviceIndex = (event.type == SDL_JOYAXISMOTION) ? event.jaxis.which : event.jbutton.which;
            int actionType = (event.type == SDL_JOYAXISMOTION) ? event.type : SDL_JOYBUTTONDOWN; // we save the type for buttons as SDL_JOYBUTTONDOWN
            
            for (int i = 0; i < kNumActions; i++)
            {
                if ((actionRecs[i].actionIndex == actionIndex) && // same action
                    (actionRecs[i].deviceIndex == deviceIndex) && // same device
                    (actionRecs[i].actionType == actionType)) // same kind
                {
                    if (event.type == SDL_JOYAXISMOTION)
                        actionRecs[i].value = ((double)event.jaxis.value / 65536.0) + 0.5;
                    else
                        actionRecs[i].value = event.jbutton.state;
                }
            }
        } 
        break;
    }
}

- (void)startHID
{
    assert(hidDevices);
    assert(SDL_WasInit(SDL_INIT_JOYSTICK));

    started = YES;
    
    
    SDL_JoystickEventState(SDL_ENABLE);
    
    for (int i = 0; i < kNumActions; i++)
    {
        
        for (NSMutableDictionary *dict in hidDevices)
        {
            if ([[dict objectForKey:@"index"] intValue] == actionRecs[i].deviceIndex) // this device needs opening
            {
                if (![dict objectForKey:@"sdljoystick"]) // and it aint opened
                {
                    SDL_Joystick *joystick = SDL_JoystickOpen(actionRecs[i].deviceIndex);   

                    [dict setValue:[NSValue valueWithPointer:joystick] forKey:@"sdljoystick"];
                }
            }
        }
    }
}

- (void)stopHID
{
    started = NO;
        
    for (NSMutableDictionary *dict in hidDevices)
    {
        SDL_Joystick *joystick = (SDL_Joystick *)[[dict objectForKey:@"sdljoystick"] pointerValue];

        SDL_JoystickClose(joystick);
        
        [dict removeObjectForKey:@"sdljoystick"];
    }
    
    SDL_JoystickEventState(SDL_DISABLE);
}

- (id)init
{
	if ((self = [super init]))
	{
        if (sharedhid)
            fatal("HID inited twice");
        sharedhid = self;
        
        assert(SDL_WasInit(SDL_INIT_JOYSTICK));

        NSMutableArray *tmpDevices = [[NSMutableArray alloc] init];

        
        for(int i = 0; i < SDL_NumJoysticks(); i++ ) 
        {
            
            NSMutableDictionary *dev = [[NSMutableDictionary alloc] init];
            
            [dev setObject:$stringf(@"%s", SDL_JoystickName(i)) forKey:@"name"];
            [dev setObject:$numi(i) forKey:@"index"];
            
            [tmpDevices addObject:dev];
            [dev release];
            
//            SDL_Joystick *joystick;
//            
//            joystick = SDL_JoystickOpen(0);
//          printf("buttons axis etc %i %i %i",  SDL_JoystickNumButtons(joystick), SDL_JoystickNumAxes(joystick), SDL_JoystickNumHats(joystick));
//            
//            SDL_JoystickClose(joystick);

        }
        
        hidDevices = [[NSArray alloc] initWithArray:tmpDevices];
        [tmpDevices release];
 //       NSLog(@"%@", [hidDevices description]);        
	}
    
	return self;
}
@end