//
//  SDLRenderViewController.h
//  CoreBreach
//
//  Created by CoreCode on 24.10.10.
//  Copyright 2008 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//



@class Scene;

@interface RenderViewController : NSObject
{
	Scene *scene;
	BOOL done;
	NSString *nib;
}

+ (RenderViewController *)sharedController;

- (void)quitAndLoadNib:(NSString *)nib;

@end
