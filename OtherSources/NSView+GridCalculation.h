//
//  NSView+GridCalculation.h
//  CoreBreach
//
//  Created by CoreCode on 15.04.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//


@interface NSView (NSView_GridCalculation)

+ (CGRect)calculateFrameForGridElementX:(uint8_t)x Y:(uint8_t)y ofX:(uint8_t)maxX ofY:(uint8_t)maxY size:(CGSize)size spacing:(CGSize)spacing indentationTopLeft:(CGSize)topLeftIndent indentationBottomRight:(CGSize)bottomRightIndent;
+ (CGRect)calculateFrameForGridElementX:(uint8_t)x Y:(uint8_t)y ofX:(uint8_t)maxX ofY:(uint8_t)maxY size:(CGSize)size spacing:(CGSize)spacing;
+ (CGRect)calculateFrameForGridElementX:(uint8_t)x ofX:(uint8_t)maxX size:(CGSize)size spacing:(float)spacing indentationLeft:(float)leftIndent indentationRight:(float)rightIndent;
+ (CGRect)calculateFrameForGridElementX:(uint8_t)x ofX:(uint8_t)maxX size:(CGSize)size spacing:(float)spacing;

@end
