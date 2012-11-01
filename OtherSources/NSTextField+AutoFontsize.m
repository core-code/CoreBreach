//
//  NSTextField+NSTextField_AutoFontsize.m
//  CoreBreach
//
//  Created by CoreCode on 17.08.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//


#import "NSTextField+AutoFontsize.h"


@implementation NSTextField (NSTextField_AutoFontsize)

- (void)adjustFontSize
{
    NSFont *currentFont = [self font];
    int currentFontSize = [currentFont pointSize];
	float fieldWidth = self.frame.size.width;
	NSSize newSize;

    do
    {
        NSDictionary* fontAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont fontWithName:[currentFont fontName] size:currentFontSize], NSFontAttributeName, nil];
        newSize = [[self stringValue] sizeWithAttributes:fontAttributes];
        [fontAttributes release];
        currentFontSize --;
    } while (newSize.width > fieldWidth);


    [self setFont:[NSFont fontWithName:[currentFont fontName] size:currentFontSize+1]];
}
@end