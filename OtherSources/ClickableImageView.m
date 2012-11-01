//
//  ClickableImageView.m
//  CoreBreach
//
//  Created by CoreCode on 09.06.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "ClickableImageView.h"


@implementation ClickableImageView

#ifndef __COCOTRON__
- (void)awakeFromNib
{
   // NSLog(@"awakeFromNib");

    [self setRefusesFirstResponder:NO];

}

- (void)mouseDown:(NSEvent *)theEvent
{
    //NSLog(@"subclass mouse up");
    NSString *urlStr;
    int tag = 0;
#ifdef GNUSTEP
    if (CONTAINS([[self toolTip] lowercaseString], @"corebreach"))
        tag = 0;
    else if (CONTAINS([[self toolTip] lowercaseString], @"facebook"))
        tag = 10;
    else if (CONTAINS([[self toolTip] lowercaseString], @"twitter"))
        tag = 11;
    else if (CONTAINS([[self toolTip] lowercaseString], @"blogger"))
        tag = 12;
    else if (CONTAINS([[self toolTip] lowercaseString], @"stumbleupon"))
        tag = 13;
    else if (CONTAINS([[self toolTip] lowercaseString], @"reddit"))
        tag = 14;
#else
     tag = [self tag];
#endif    
    if (tag == 0)
        urlStr = @"http://corebreach.corecode.at/CoreBreach/News/News.html";
    else if (tag == 1)
        urlStr = @"http://www.corecode.at/";
    else if (tag == 2)
        urlStr = @"http://www.ncreate.at/";
    else if (tag == 10) // facebook
        urlStr = @"http://www.addthis.com/bookmark.php?v=250&winname=addthis&pub=xa-4d9c855d1cf9ff9a&source=tbx32-250&lng=es&s=facebook&url=http%3A%2F%2Fcorecode.corebreach.at&title=CoreBreach%20Mac%20Racing%20Game&ate=AT-xa-4d9c855d1cf9ff9a/-/-/4ebdb109cde568b1/4/4e2868962f366104&frommenu=1&uid=4e2868962f366104&ct=1&tt=0";
    else if (tag == 11) // twitter
        urlStr = @"http://www.addthis.com/bookmark.php?v=250&winname=addthis&pub=xa-4d9c855d1cf9ff9a&source=tbx32-250&lng=es&s=twitter&url=http%3A%2F%2Fcorecode.corebreach.at&title=CoreBreach%20Mac%20Racing%20Game&ate=AT-xa-4d9c855d1cf9ff9a/-/-/4ebdb109cde568b1/5/4e2868962f366104&frommenu=1&uid=4e2868962f366104&ct=1&template=CoreBreach%20Mac%20Racing%20Game%20{{url}}%20via%20%40AddThis&tt=0";
    else if (tag == 12) // blogger
        urlStr = @"http://www.addthis.com/bookmark.php?v=250&winname=addthis&pub=xa-4d9c855d1cf9ff9a&source=tbx32-250&lng=es&s=blogger&url=http%3A%2F%2Fcorecode.corebreach.at&title=CoreBreach%20Mac%20Racing%20Game&ate=AT-xa-4d9c855d1cf9ff9a/-/-/4ebdb109cde568b1/8/4e2868962f366104&frommenu=1&uid=4e2868962f366104&ct=1&tt=0";
    else if (tag == 13) // stumble
        urlStr = @"http://www.addthis.com/bookmark.php?v=250&winname=addthis&pub=xa-4d9c855d1cf9ff9a&source=tbx32-250&lng=de-de&s=stumbleupon&url=http%3A%2F%2Fcorecode.corebreach.at&title=CoreBreach%20Mac%20Racing%20Game&ate=AT-xa-4d9c855d1cf9ff9a/-/-/4ec149792a8e6eba/1&frommenu=1&uid=4ec149793bfa6d26&ct=1&tt=0";
    else if (tag == 14) // reddit
        urlStr = @"http://www.addthis.com/bookmark.php?v=250&winname=addthis&pub=xa-4d9c855d1cf9ff9a&source=tbx32-250&lng=de-de&s=reddit&url=http%3A%2F%2Fcorecode.corebreach.at&title=CoreBreach%20Mac%20Racing%20Game&ate=AT-xa-4d9c855d1cf9ff9a/-/-/4ec149792a8e6eba/2&frommenu=1&uid=4ec14979b8ded70a&ct=1&tt=0";
    else
        assert(0);
    
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlStr]];
}
#endif
@end
