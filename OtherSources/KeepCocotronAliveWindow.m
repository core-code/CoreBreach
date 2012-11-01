//
//  KeepCocotronAliveWindow.m
//  NSOpenGLView
//
//  Created by CoreCode on 10.10.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "KeepCocotronAliveWindow.h"


@implementation KeepCocotronAliveWindow

#pragma mark *** NSWindow subclass-methods ***

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)windowStyle backing:(unsigned int)bufferingType defer:(BOOL)deferCreation
{
	self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];

	return self;
}

#pragma mark *** NSNibAwaking protocol-methods ***

- (void)awakeFromNib
{
//
//
//	[self setBackgroundColor: [NSColor clearColor]];
//	[self setOpaque:NO];
//	[self setCanHide:NO];
//	[self setAlphaValue:1.0];
}
@end
