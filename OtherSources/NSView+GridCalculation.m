//
//  NSView+GridCalculation.m
//  CoreBreach
//
//  Created by CoreCode on 15.04.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "NSView+GridCalculation.h"


@implementation NSView (NSView_GridCalculation)



+ (CGRect)calculateFrameForGridElementX:(uint8_t)x Y:(uint8_t)y ofX:(uint8_t)maxX ofY:(uint8_t)maxY size:(CGSize)size spacing:(CGSize)spacing indentationTopLeft:(CGSize)topLeftIndent indentationBottomRight:(CGSize)bottomRightIndent
{
    int xSpacings = maxX - 1;
    int ySpacings = maxY - 1;
    float xFreeSpace = xSpacings * spacing.width;
    float yFreeSpace = ySpacings * spacing.height;
    NSSize fullSize =  NSMakeSize(size.width - topLeftIndent.width - bottomRightIndent.width, size.height - topLeftIndent.height - bottomRightIndent.height);
    NSSize elementSize = NSMakeSize((fullSize.width - xFreeSpace) / maxX, (fullSize.height - yFreeSpace) / maxY);
    NSSize elementOffset = NSMakeSize(topLeftIndent.width + x * (elementSize.width + spacing.width), topLeftIndent.height + y * (elementSize.height + spacing.height));

    return CGRectMake(elementOffset.width, elementOffset.height, elementSize.width, elementSize.height);
}

+ (CGRect)calculateFrameForGridElementX:(uint8_t)x Y:(uint8_t)y ofX:(uint8_t)maxX ofY:(uint8_t)maxY size:(CGSize)size spacing:(CGSize)spacing
{
    return [NSView calculateFrameForGridElementX:x Y:y ofX:maxX ofY:maxY size:size spacing:spacing indentationTopLeft:CGSizeMake(0,0) indentationBottomRight:CGSizeMake(0,0)];
}

+ (CGRect)calculateFrameForGridElementX:(uint8_t)x ofX:(uint8_t)maxX size:(CGSize)size spacing:(float)spacing indentationLeft:(float)leftIndent indentationRight:(float)rightIndent
{
   return [NSView calculateFrameForGridElementX:x Y:0 ofX:maxX ofY:1 size:size spacing:CGSizeMake(spacing,0) indentationTopLeft:CGSizeMake(leftIndent,0) indentationBottomRight:CGSizeMake(rightIndent,0)];
}

+ (CGRect)calculateFrameForGridElementX:(uint8_t)x ofX:(uint8_t)maxX size:(CGSize)size spacing:(float)spacing
{
    return [NSView calculateFrameForGridElementX:x Y:0 ofX:maxX ofY:1 size:size spacing:CGSizeMake(spacing,0) indentationTopLeft:CGSizeMake(0,0) indentationBottomRight:CGSizeMake(0,0)];
}
@end
