#import "NSView+Snapshot.h"


@implementation NSView (NSView_Snapshot)

- (NSImage *)snapshotFromRect:(NSRect)sourceRect
{
    NSImage *snapshot = [[NSImage alloc] initWithSize:sourceRect.size];

    [snapshot lockFocus];

    [self drawRect:sourceRect];

    [snapshot unlockFocus];

    return [snapshot autorelease];
}

- (NSImage *)snapshotIncludingSubviews
{
    NSBitmapImageRep *imageRep = [self bitmapImageRepForCachingDisplayInRect:self.bounds];
    NSImage *renderedImage = [[NSImage alloc] initWithSize:[imageRep size]];

    [self cacheDisplayInRect:self.bounds toBitmapImageRep:imageRep];
    [renderedImage addRepresentation:imageRep];

    return [renderedImage autorelease];
}
@end
