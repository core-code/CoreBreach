//
//  ApplicationSubclass.m
//  CoreBreach
//
//  Created by CoreCode on 14.03.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "ApplicationSubclass.h"


@implementation ApplicationSubclass

#ifdef TARGET_OS_MAC
- (NSInteger)requestUserAttention:(NSRequestUserAttentionType)requestType
{
	return 0;
}

- (void)sendEvent:(NSEvent *)anEvent{
	//This works around an AppKit bug, where key up events while holding
	//down the command key don't get sent to the key window.
	if([anEvent type] == NSKeyUp && ([anEvent modifierFlags] & NSCommandKeyMask))
	{
		[[self keyWindow] sendEvent:anEvent];
	}
	else
	{
		[super sendEvent:anEvent];
	}
}

- (void)terminate:(id)sender
{
  //  NSLog(@"subterm");
    [[self delegate] applicationWillTerminate:nil];

    [super terminate:sender];
}
#endif

- (void)showHelp:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"Manual" ofType:@"pdf"]];
}
@end
