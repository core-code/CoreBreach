//
//  ApplicationDelegate.m
//  CoreBreach
//
//  Created by CoreCode on 25.01.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "ApplicationDelegate.h"


@class Launcher;

@implementation ApplicationDelegate

@synthesize hid;

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{

	//   NSLog(@"applicationDidFinishLaunching");


#ifdef SDL
    SDL_Init(SDL_INIT_JOYSTICK);
#endif


	hid = [[HIDSupport alloc] init];

	[hid restoreConfiguration:self];
	//    [hid startHID];


#ifdef SDL
    SDL_Quit();
#endif


#ifdef TIMEDEMO
	LOAD_NIB(@"Core3D", NSApp);
	
#else

#ifdef __COCOTRON__
    LOAD_NIB(@"KeepCocotronAlive", NSApp);
    
#endif

#if defined(TARGET_OS_MAC) && defined(SDL)
	LOAD_NIB(@"Launcher-windows", NSApp);
#else


	if (!LOAD_NIB(@"Launcher", NSApp))
		NSLog(@"Error: could not load Launcher NIB");
#endif
#endif
}

#if defined(SDL) && defined(TARGET_OS_MAC)
- (void)awakeFromNib
{
    [self applicationDidFinishLaunching:nil];
}
#endif

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
//    NSLog(@"applicationWillTerminate");
	if (hid)
	{
		//[[HIDSupport sharedInstance] stopHID];
		[hid release];
		hid = nil;
	}
}

#ifdef GNUSTEP
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return NO; // neccessary when NSMenuInterfaceStyle = NSWindows95InterfaceStyle 
}
#endif

//- (void)applicationWillResignActive:(NSNotification *)aNotification
//{
//	NSLog(@"res del");
//	[[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationWillResignActiveNotification object:self];
//
//}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	if (NSRunAlertPanel(@"CoreBreach", $stringf(@"%@\n%@",
	NSLocalizedString(@"Do you really want to install this 3rd party track? Please only install tracks from the official site or from people you can trust.", nil),
	[filename lastPathComponent]),
			NSLocalizedString(@"Install", nil),
			NSLocalizedString(@"Cancel", nil), nil) != 0)
	{
		NSString *appsupp = APPLICATION_SUPPORT_DIR;
#ifdef __COCOTRON__ // bug #821
        [[NSFileManager defaultManager] createDirectoryAtPath:[appsupp stringByAppendingPathComponent:[filename lastPathComponent]] withIntermediateDirectories:YES attributes:nil error:NULL];
        
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filename error:NULL];
        for (NSString *file in contents)
        {
           // BOOL succ =
            [[NSFileManager defaultManager] copyItemAtPath:[filename stringByAppendingPathComponent:file]
                                                    toPath:[[appsupp stringByAppendingPathComponent:[filename lastPathComponent]] stringByAppendingPathComponent:file]
                                                     error:NULL];
           // NSLog(@" copy from to %@ %@ %i", [appsupp stringByAppendingPathComponent:file], [[appsupp stringByAppendingPathComponent:[filename lastPathComponent]] stringByAppendingPathComponent:file], succ);
        }

#else

		[[NSFileManager defaultManager] createDirectoryAtPath:appsupp withIntermediateDirectories:YES attributes:nil error:NULL];

		[[NSFileManager defaultManager] copyItemAtPath:filename
		                                        toPath:[appsupp stringByAppendingPathComponent:[filename lastPathComponent]]
			                                     error:NULL];
#endif
#ifdef TARGET_OS_MAC
        [(NSNotificationCenter *)[NSNotificationCenter defaultCenter] postNotificationName:@"mapInstalled" object:nil];
#else
		NSRunAlertPanel(@"CoreBreach", @"The 3rd party track was successfully installed, please quit and re-launch CoreBreach.", @"OK", nil, nil);
#endif

		return YES;
	}

	return NO;
}

#ifndef TARGET_OS_MAC
- (IBAction)installRaceTrack:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setAllowedFileTypes:$array(@"cbtrack")];
	[panel setCanChooseFiles:NO];
	[panel setCanChooseDirectories:YES];


	if ([panel runModalForDirectory:NSHomeDirectory() file:nil types:$array(@"cbtrack")] == NSOKButton)
		[self application:nil openFile:[[panel filenames] objectAtIndex:0]];
}
#endif

//- (void)dealloc
//{
//    NSLog(@"appdelegate dealloc");
//
//	[super dealloc];
//}
@end
