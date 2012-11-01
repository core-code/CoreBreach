@interface NSView (NSView_Snapshot)

- (NSImage *)snapshotFromRect:(NSRect)sourceRect;
- (NSImage *)snapshotIncludingSubviews;

@end
