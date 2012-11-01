//
//  AppController.h
//  FeedViewer
//
//  Created by Colin Wheeler on 1/31/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <PubSub/PubSub.h>

@interface AppController : NSObject
{
    IBOutlet NSTableView *rssTable;
    IBOutlet NSObjectController *objectController;
    IBOutlet NSArrayController *arrayController;
	PSFeed *newsFeed;
	NSOperationQueue *rssQueue;
	NSError *feedError;
	id psNotification;
    NSDate *latestNews;
}

- (void)cleanup;

@property (readonly) NSDate *latestNews;
@property (retain) NSOperationQueue *rssQueue;
@property (retain) PSFeed *newsFeed;
@property (retain) NSError *feedError;
@property (retain) id psNotification;

@end
