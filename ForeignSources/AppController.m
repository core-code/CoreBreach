//
//  AppController.m
//  FeedViewer
//
//  Created by Colin Wheeler on 1/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AppController.h"

static NSString * const kRSSNewsFeed = @"http://corebreach.corecode.at/CoreBreach/News/rss.xml";
BOOL CreatePubSubSymlink();

@implementation AppController

@synthesize rssQueue;
@synthesize newsFeed;
@synthesize feedError;
@synthesize psNotification;
@synthesize latestNews;

- (id)init
{
	if ((self = [super init]))
    {
		CreatePubSubSymlink();

		NSURL *feedURL = [NSURL URLWithString:kRSSNewsFeed];
		newsFeed = [[PSFeed alloc] initWithURL:feedURL];
		rssQueue = [[NSOperationQueue alloc] init];
		[rssQueue setName:@"com.FeedViewer.rssQueue"];
		feedError = nil;
		psNotification = nil;

	}
	return self;
}

- (void)doubleClick
{
  //  NSLog(@"double");
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://corebreach.corecode.at/CoreBreach/News/News.html"]];
}

- (void)awakeFromNib
{
    [rssTable setDoubleAction:@selector(doubleClick)];
    [rssTable setTarget:self];

	NSNotificationCenter *notifyCenter = [NSNotificationCenter defaultCenter];
	self.psNotification = [notifyCenter addObserverForName:PSFeedRefreshingNotification
													  object:newsFeed
													   queue:rssQueue
												  usingBlock:^(NSNotification *arg1)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self];

		if ([newsFeed isRefreshing]) return;

        if (!rssTable) return;


        [[NSOperationQueue mainQueue] addOperationWithBlock:
         ^{

			if (nil != feedError)
            {
			//	[NSApp presentError:feedError];
				return;
			}

			//inform our KVO Controllers that we now have
			//RSS entries to display
			[self willChangeValueForKey:@"newsFeed"];
			[self didChangeValueForKey:@"newsFeed"];

            if (!rssTable) return;

			NSSortDescriptor * sd = [[NSSortDescriptor alloc] initWithKey:@"dateForDisplay" ascending:NO];
			[rssTable setSortDescriptors:[NSArray arrayWithObject:sd]];
			[sd release];

            [arrayController setSelectionIndex:0];

            if ([[arrayController arrangedObjects] count])
                 latestNews = [[[[arrayController arrangedObjects] objectAtIndex:0] dateForDisplay] copy];
		}];
	}];

	[newsFeed refresh:&feedError];
}

- (void)cleanup
{
    rssTable = nil;
    [arrayController release];
    [objectController release];
}

- (void)dealloc
{
    [latestNews release];
    latestNews = nil;
    [self setRssQueue:nil];
    [self setNewsFeed:nil];
    [self setFeedError:nil];
    [self setPsNotification:nil];
    
    [super dealloc];
}

@end

BOOL CreatePubSubSymlink()
{
    NSString* libraryDirectory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    NSString* pubSubDirectory = [libraryDirectory stringByAppendingPathComponent:@"PubSub"];
    NSString* pubSubTarget = @"../../../../PubSub";
    NSFileManager* fileManager = [NSFileManager defaultManager];
	
    BOOL isDirectory  = NO;
    NSString* realPubSubDirectory = [libraryDirectory stringByAppendingPathComponent:pubSubTarget];
    if ([fileManager fileExistsAtPath:realPubSubDirectory isDirectory:&isDirectory]) {
        if (isDirectory) {
            int success = symlink([pubSubTarget UTF8String], [pubSubDirectory UTF8String]);
            if (success != 0) {
                if (errno != EEXIST) {
                    return NO;
                }
            }
        }
    }
    return YES;
}