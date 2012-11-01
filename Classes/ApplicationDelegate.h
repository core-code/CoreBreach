//
//  ApplicationDelegate.h
//  CoreBreach
//
//  Created by CoreCode on 25.01.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#ifdef SDL
    #import "HIDSupport_SDL.h"
#elif defined(TARGET_OS_MAC)
    #import "HIDSupport.h"
#endif

@interface ApplicationDelegate : NSObject
{
	HIDSupport *hid;
}

@property (readonly, nonatomic) HIDSupport *hid;

#ifndef TARGET_OS_MAC
- (IBAction)installRaceTrack:(id)sender;
#endif

@end
