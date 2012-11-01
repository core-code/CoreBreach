//
//  GameSheetController.m
//  CoreBreach
//
//  Created by CoreCode on 07.11.10.
//  Copyright 2010 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "GameSheetController.h"
#import "Game.h"
#import "Highscores.h"
#import "NSTextField+AutoFontsize.h"


GameSheetController *gpc = nil;

@implementation GameSheetController

@synthesize highscores;

+ (GameSheetController *)sharedController
{
	if (gpc == nil)
		fatal("GameSheetController not allocated");
	//[[self alloc] init];

	return gpc;
}

- (id)init
{
	if ((self = [super init]))
	{
		gpc = self;
		//NSLog(@"GameSheetController init");
	}
	return self;
}

#ifndef SDL
- (void)presentPauseSheet
{
	if (game.gameMode == kGameModeTimeAttack)
	{
		[viewScoreButton setHidden:NO];
		[viewScoreButton setEnabled:[game.hud.timeArray count] >= 2];
	}
	else
		[viewScoreButton setHidden:YES];

	[NSCursor unhide];

	[NSApp beginSheet:pauseSheet modalForWindow:[renderViewController window] modalDelegate:nil didEndSelector:nil contextInfo:NULL];
}

- (void)movieDidEnd:(id)bla
{
	if (storyMovieView && skipMovieButton)
	{
		//        NSLog([storyMovieView description]);
		[storyMovieView removeFromSuperview];
		[skipMovieButton removeFromSuperview];

		storyMovieView = nil;
		skipMovieButton = nil;
		[self showResults];
	}
}

- (IBAction)continueAction:(id)sender
{
	[NSApp endSheet:pauseSheet];
	[pauseSheet orderOut:self];

	if ([renderViewController isInFullScreenMode])
		[NSCursor hide];

	[game stopPause];
}
#endif

- (void)dealloc
{
	//NSLog(@"game sheet controlelr dealloc");
#ifndef SDL
	[[NSNotificationCenter defaultCenter] removeObserver:self];
#endif
	[newhighscoreindices release];
	[highscores release];
	[laptimes release];
	[reallaptimes release];
	[awards release];
	[awards2 release];
	[result release];
	[result2 release];
	[settings release];

	[careerBox release];
	[customBox release];
	[timeattackBox release];
	[multiplayerBox release];
	[finishSheet release];

	if (gpc == self)
		gpc = nil;

	[super dealloc];
}

- (void)analyseHighscores
{
	NSMutableArray *i = [NSMutableArray array];
	bestnewplace = 999999;

	for (NSDictionary *hs in highscores)
	{

		float time = [[hs objectForKey:@"time"] floatValue];

		for (NSNumber *lap in reallaptimes)
		{
			float lapf = [lap floatValue];

			float diff = fabsf(time - lapf);

			if (diff < 0.000001 &&
					[[hs objectForKey:@"nickname"] isEqualToString:$default(kNicknameKey)] &&
					[[hs objectForKey:@"ship"] intValue] == [[settings objectForKey:@"shipNum"] intValue])
			{
//                printf(" %f %f", lapf, diff);
//                NSLog(@"%@", hs);

				if ([[hs objectForKey:@"rank"] intValue] < bestnewplace)
					bestnewplace = [[hs objectForKey:@"rank"] intValue];

				[i addObject:$numi([highscores indexOfObjectIdenticalTo:hs])];
			}
		}
	}

	newhighscoreindices = [[NSArray alloc] initWithArray:i];
	//  NSLog(@"%@", [highscores description]);
}

- (void)fetchResults
{
	result = [CoreBreach fetchResult1];
	result2 = [CoreBreach fetchResult2];
	settings = [CoreBreach fetchSettings];
}

- (BOOL)isVideoNeccessary
{
	return !(game.trackName ||
			game.gameMode != kGameModeCareer ||
			(game.trackNum != 0 && game.trackNum != 11) ||
			$defaulti($stringf(kStoryMovieISeenKey, game.trackNum)) ||
			[[result objectForKey:@"endSieg"] intValue] != 1);
}

#ifndef SDL
- (IBAction)viewScoreAction:(id)sender
{
	[self fetchResults];

	[NSApp endSheet:pauseSheet];
	[pauseSheet orderOut:self];

	[NSCursor unhide];


	[NSApp beginSheet:finishSheet modalForWindow:[renderViewController window] modalDelegate:nil didEndSelector:nil contextInfo:NULL];


	if (![self isVideoNeccessary])
	{
		[self movieDidEnd:self];
	}
	else
	{
		$setdefaulti(YES, $stringf(kStoryMovieISeenKey, game.trackNum));
		$defaultsync;

		@synchronized (scene)
		{
			[game pauseSoundAndMusic];
			QTMovie *m = [[QTMovie alloc] initWithURL:[[NSBundle mainBundle] URLForResource:$stringf(@"story_%i", game.trackNum + 1) withExtension:@"mp4"] error:nil];


			if ([[m tracksOfMediaType:QTMediaTypeSubtitle] count])
			{
				QTTrack *subtitle = [[m tracksOfMediaType:QTMediaTypeSubtitle] objectAtIndex:0];
				BOOL spanish = FALSE;
				NSArray *languages = $default(@"AppleLanguages");
				if ([languages indexOfObject:@"es"] != NSNotFound &&
						((([languages indexOfObject:@"es"] < [languages indexOfObject:@"en"]) && ([languages indexOfObject:@"en"] != NSNotFound)) || ([languages indexOfObject:@"en"] == NSNotFound)))
					spanish = TRUE;

				[subtitle setEnabled:spanish];
			}
			[skipMovieButton setHidden:NO];

			[storyMovieView setHidden:NO];
			[storyMovieView setMovie:m];
			[storyMovieView setEditable:NO];
			[storyMovieView setControllerVisible:NO];
			[storyMovieView play:self];

			[(NSNotificationCenter *) [NSNotificationCenter defaultCenter] addObserver:self selector:@selector(movieDidEnd:) name:QTMovieDidEndNotification object:nil];

			[m release];
		}
	}
}
#else
- (IBAction)viewScoreAction:(id)sender
{
    [self performSelector:@selector(showResults) withObject:nil afterDelay:0.1];
}
#endif

- (void)showResults
{
#ifdef SDL
    [finishSheet center];
    [finishSheet makeKeyAndOrderFront:self];
#endif

	int endSieg = [[result objectForKey:@"endSieg"] intValue];
	int endSieg2 = [[result2 objectForKey:@"endSieg"] intValue];
	NSArray *timeArray = [result objectForKey:@"timeArray"];
	NSArray *timeArray2 = [result2 objectForKey:@"timeArray"];
	gameModeEnum gameMode = (gameModeEnum) [[settings objectForKey:@"gameMode"] intValue];
	int trackNum = [[settings objectForKey:@"trackNum"] intValue];
	NSString *trackName = [settings objectForKey:@"trackName"];

	id boxes[] = {careerBox, customBox, timeattackBox, multiplayerBox};
	NSBox *b = boxes[gameMode];

	//    CATransition *transition = [CATransition animation];
	//    [transition setType:kCATransitionPush];
	//    [transition setDuration:2.0];
	//    [transition setSubtype:kCATransitionFromRight];
	//    [[finishSheet contentView] setAnimations:[NSDictionary
	//                                dictionaryWithObject:transition forKey:@"subviews"]];



	//    [NSAnimationContext beginGrouping];
	//    [[NSAnimationContext currentContext] setDuration:2.0];
	//
	//    [[[finishSheet contentView] animator] addSubview:b];
	//    [NSAnimationContext endGrouping];


	[[finishSheet contentView] addSubview:b];
	[b setFrameOrigin:NSMakePoint(12, 75)];


	int unlockedTracksPre = 0;
	for (uint32_t i = 1; i <= kNumTracks * 2; i++)
		if ($defaulti($stringf(kTrackIUnlocked, i)))
			unlockedTracksPre++;
	int unlockedShipsPre = 0;
	for (uint32_t i = 1; i <= kNumShips; i++)
		if ($defaulti($stringf(kShipIUnlocked, i)))
			unlockedShipsPre++;

	if (gameMode != kGameModeTimeAttack)
	{
		NSMutableArray *indices = [NSMutableArray array];
		if (!trackName)
		{
			NSMutableArray *objs = [NSMutableArray arrayWithArray:[kObjectivesPerTrack objectAtIndex:trackNum]];
			[objs addObjectsFromArray:kObjectivesEveryTrack];

			for (uint32_t i = 0; i < [objs count]; i++)
			{
				NSDictionary *obj = [objs objectAtIndex:i];
				NSPredicate *p = [obj objectForKey:kConditionKey];
				BOOL res = [p evaluateWithObject:result];
				if (res)
				{
					//            NSLog([obj description]);
					if (gameMode == kGameModeCareer)
					{
#ifndef DEMO
						BasicBlock block = [obj objectForKey:kRewardBlockKey];

						block();
#endif
					}
					[indices addObject:$numi(i)];
				}
			}
		}
		awards = [[NSArray alloc] initWithArray:indices];
	}


	int unlockedTracksPost = 0;
	for (uint32_t i = 1; i <= kNumTracks * 2; i++)
		if ($defaulti($stringf(kTrackIUnlocked, i)))
			unlockedTracksPost++;
	int unlockedShipsPost = 0;
	for (uint32_t i = 1; i <= kNumShips; i++)
		if ($defaulti($stringf(kShipIUnlocked, i)))
			unlockedShipsPost++;

	[withNewShipTextField setHidden:YES];
	if (unlockedTracksPre != unlockedTracksPost)
		[tryAgainButton setTitle:NSLocalizedString(@"Next race", nil)];
	if (unlockedShipsPre != unlockedShipsPost)
		[withNewShipTextField setHidden:NO];


	NSMutableArray *a = [NSMutableArray array];
	NSMutableArray *rt = [NSMutableArray array];
	float time = 0;
	float besttime = FLT_MAX;
	for (uint32_t i = 0; i < [timeArray count]; i++)
	{
		if (i > 0)
		{
			float r = [[timeArray objectAtIndex:i] doubleValue] - [[timeArray objectAtIndex:i - 1] doubleValue];
			[a addObject:$stringf(@"Lap %i: %.2f sec", i, r)];
			[rt addObject:$num(r)];
			time += r;
			if (r < besttime)
				besttime = r;
		}
	}
	[a addObject:$stringf(@"Race: %.2f sec", time)];
	laptimes = [[NSArray alloc] initWithArray:a];
	reallaptimes = [[NSArray alloc] initWithArray:rt];

	if ((gameMode == kGameModeCareer) || (gameMode == kGameModeCustomGame))
	{
		if (endSieg == 1)
			[finishBanner setImage:[NSImage imageNamed:@"finish_won"]];
		else
			[finishBanner setImage:[NSImage imageNamed:@"finish_lost"]];


		if (endSieg == 1)
			[finishResultText setStringValue:NSLocalizedString(@"You won the race!", nil)];
		else if (endSieg == 2)
			[finishResultText setStringValue:NSLocalizedString(@"You made the second place!", nil)];
		else if (endSieg == 3)
			[finishResultText setStringValue:NSLocalizedString(@"You got the third place!", nil)];
		else
			[finishResultText setStringValue:$stringf(NSLocalizedString(@"You placed at position %i!", nil), endSieg)];
	}

	if (gameMode == kGameModeMultiplayer)
	{
		[finishBanner setImage:[NSImage imageNamed:@"finish_multi"]];

		if (endSieg < endSieg2)
			[finishResultText setStringValue:$stringf(NSLocalizedString(@"%@ has won!", nil), $default(kNicknameKey))];
		else
			[finishResultText setStringValue:$stringf(NSLocalizedString(@"%@ has won!", nil), $default(kSecondNicknameKey))];

		[multiplayerP1ResultText setStringValue:$stringf(@"'%@' position: %i", $default(kNicknameKey), endSieg)];
		[multiplayerP2ResultText setStringValue:$stringf(@"'%@' position: %i", $default(kSecondNicknameKey), endSieg2)];

		[multiplayerP1ResultText adjustFontSize];
		[multiplayerP2ResultText adjustFontSize];

		NSImage *win = [NSImage imageNamed:@"winner"];
		NSImage *loose = [NSImage imageNamed:@"looser"];
		[player1Image setImage:(endSieg < endSieg2) ? win : loose];
		[player2Image setImage:(endSieg > endSieg2) ? win : loose];

		NSMutableArray *array = [NSMutableArray array];
		float raceTime = 0;
		for (uint32_t i = 0; i < [timeArray2 count]; i++)
		{
			if (i > 0)
			{
				float r = [[timeArray2 objectAtIndex:i] doubleValue] - [[timeArray2 objectAtIndex:i - 1] doubleValue];
				// printf("laptime %f", r);
				[array addObject:$stringf(@"Lap %i: %.2f sec", i, r)];
				raceTime += r;
			}
		}
		[array addObject:$stringf(@"Race: %.2f sec", raceTime)];
		laptimes2 = [[NSArray alloc] initWithArray:array];

		NSMutableArray *indices = [NSMutableArray array];
		if (!trackName)
		{
			NSMutableArray *objs = [NSMutableArray arrayWithArray:[kObjectivesPerTrack objectAtIndex:trackNum]];
			[objs addObjectsFromArray:kObjectivesEveryTrack];
			for (uint32_t i = 0; i < [objs count]; i++)
			{
				NSDictionary *obj = [objs objectAtIndex:i];
				NSPredicate *p = [obj objectForKey:kConditionKey];
				BOOL res = [p evaluateWithObject:result2];
				if (res)
				{
					//            NSLog([obj description]);

					[indices addObject:$numi(i)];
				}
			}
		}
		awards2 = [[NSArray alloc] initWithArray:indices];
	}
	else if (gameMode == kGameModeTimeAttack)
	{
		[finishBanner setImage:[NSImage imageNamed:@"finish_time"]];

		[finishResultText setStringValue:$stringf(NSLocalizedString(@"Best round: %.2fsec", nil), besttime)];
	}


	if (!IS_MULTI && !trackName
#ifndef __APPLE__
        && globalInfo.online
#endif
			)
	{
#ifdef __APPLE__
		dispatch_async(dispatch_get_global_queue(0, 0), ^
		{
#endif
			Highscores *hs = [[Highscores alloc] init];
			self.highscores = [hs getHighscoresForMode:gameMode forNickname:$default(kNicknameKey) onTrack:trackNum];
			[hs release];
			[self analyseHighscores];
#ifdef __APPLE__
			dispatch_async(dispatch_get_main_queue(), ^
			{
#endif
				if (highscoresCareerTable && gameMode == kGameModeCareer)
					[highscoresCareerTable reloadData];
				if (highscoresCustomTable && gameMode == kGameModeCustomGame)
					[highscoresCustomTable reloadData];
				if (highscoresTimeattackTable && gameMode == kGameModeTimeAttack)
					[highscoresTimeattackTable reloadData];

				if (bestnewplace < 999999)
				{
					[carrerHighscoreResult setStringValue:$stringf(NSLocalizedString(@"Highscores (New Position: %i):", nil), bestnewplace)];
					[customHighscoreResult setStringValue:$stringf(NSLocalizedString(@"Highscores (New Position: %i):", nil), bestnewplace)];
					[timeattackHighscoreResult setStringValue:$stringf(NSLocalizedString(@"Highscores (New Position: %i):", nil), bestnewplace)];
				}

				if ([newhighscoreindices count])
				{
					int i = [[newhighscoreindices objectAtIndex:0] intValue];
					[highscoresCareerTable scrollRowToVisible:i];
					[highscoresCustomTable scrollRowToVisible:i];
					[highscoresTimeattackTable scrollRowToVisible:i];
				}
#ifdef __APPLE__
			});
		});
#endif
	}

	[finishResultText adjustFontSize];

	[laptimesTimeattackTable reloadData];
	[laptimesCustomTable reloadData];
	[laptimesMultiplayer1Table reloadData];
	[laptimesMultiplayer2Table reloadData];
	[statusCareerTable reloadData];
	[objectivesCareerTable reloadData];
	[objectivesMultiplayer1Table reloadData];
	[objectivesMultiplayer2Table reloadData];
	[objectivesCustomTable reloadData];
	[awardsCareerTable reloadData];
}

- (IBAction)quitFromScoresAction:(id)sender
{
	[NSApp endSheet:finishSheet];
	[finishSheet orderOut:self];
	[NSApp terminate:self];
}

- (IBAction)retryAction:(id)sender
{
#ifndef SDL
	[renderViewController release];
#else
    [finishSheet orderOut:self];
    [finishSheet close];
#endif
	LOAD_NIB(@"Core3D", NSApp);
	[self autorelease];
}

- (IBAction)mainmenuAction:(id)sender
{
#ifndef SDL
	[renderViewController release];
#else
    [finishSheet orderOut:self];
    [finishSheet close];
#endif
	LOAD_NIB(@"Launcher", NSApp);
	[self autorelease];
}

- (IBAction)quitAction:(id)sender
{
#ifdef SDL
    fatal("CoreBreach proper termination\n");
#else
	[NSApp endSheet:pauseSheet];
	[pauseSheet orderOut:self];
	[NSApp terminate:self];
#endif
}

#pragma mark NSTableViewDataSource protocol methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (aTableView == statusCareerTable)
		return 3;
	else if (aTableView == objectivesCareerTable ||
			aTableView == objectivesMultiplayer1Table ||
			aTableView == objectivesCustomTable ||
			aTableView == awardsCareerTable)
		return [awards count];
	else if (aTableView == objectivesMultiplayer2Table)
		return [awards2 count];
	else if (aTableView == laptimesTimeattackTable ||
			aTableView == laptimesCustomTable ||
			aTableView == laptimesMultiplayer1Table)
		return [laptimes count];
	else if (aTableView == laptimesMultiplayer2Table)
		return [laptimes2 count];
	else if ((aTableView == highscoresCareerTable) ||
			(aTableView == highscoresCustomTable) ||
			(aTableView == highscoresTimeattackTable))
		return [highscores count];
	else
		return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *key = [[[aTableColumn headerCell] stringValue] lowercaseString];
	NSString *value = nil;

	if (aTableView == objectivesCareerTable ||
			aTableView == objectivesCustomTable ||
			aTableView == objectivesMultiplayer1Table ||
			aTableView == objectivesMultiplayer2Table ||
			aTableView == statusCareerTable ||
			aTableView == awardsCareerTable ||
			aTableView == laptimesTimeattackTable ||
			aTableView == laptimesCustomTable ||
			aTableView == laptimesMultiplayer1Table ||
			aTableView == laptimesMultiplayer2Table)
	{
		return $numi(0);
	}
	else if ((aTableView == highscoresCareerTable) ||
			(aTableView == highscoresCustomTable) ||
			(aTableView == highscoresTimeattackTable))
		value = [[highscores objectAtIndex:rowIndex] valueForKey:key];


	if (!value)
		return nil;

	if (![value isKindOfClass:[NSString class]])
		value = [(NSNumber *) value stringValue];

	if ([key isEqualToString:@"ship"])
		return ([value intValue] < kNumShips) ? [kShipNames objectAtIndex:[value intValue]] : @"";
	else if ([key isEqualToString:@"time"])
		return MAXLENGTH(value, 5);
	else
		return value;

	return nil;
}

#pragma mark NSTableViewDelegate delegate methods

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView
{
	if (aTableView == objectivesCareerTable ||
			aTableView == objectivesCustomTable ||
			aTableView == objectivesMultiplayer1Table ||
			aTableView == objectivesMultiplayer2Table ||
			aTableView == awardsCareerTable ||
			aTableView == statusCareerTable ||
			aTableView == laptimesTimeattackTable ||
			aTableView == laptimesCustomTable ||
			aTableView == laptimesMultiplayer1Table ||
			aTableView == laptimesMultiplayer2Table)
		return NO;
	else
		return YES;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)TC row:(int)rowIndex
{
	if ([settings objectForKey:@"trackName"])
		return;

	if (aTableView == objectivesCareerTable ||
			aTableView == objectivesCustomTable ||
			aTableView == objectivesMultiplayer1Table ||
			aTableView == objectivesMultiplayer2Table)
	{
		NSMutableArray *objs = [NSMutableArray arrayWithArray:[kObjectivesPerTrack objectAtIndex:[[settings objectForKey:@"trackNum"] intValue]]];
		[objs addObjectsFromArray:kObjectivesEveryTrack];
		NSDictionary *dict = [objs objectAtIndex:[[(aTableView == objectivesMultiplayer2Table ? awards2 : awards) objectAtIndex:rowIndex] intValue]];
		[aCell setTitle:$stringf(@"%@", [dict valueForKey:kObjectiveKey])];
#ifdef TARGET_OS_MAC
		[aCell setDrawsBackground:NO];
#endif
		//		NSImage *image = [NSImage imageNamed:[dict valueForKey:@"Icon"]];
		//		[aCell setImage:image];
	}
	else if (aTableView == awardsCareerTable)
	{
		NSMutableArray *objs = [NSMutableArray arrayWithArray:[kObjectivesPerTrack objectAtIndex:[[settings objectForKey:@"trackNum"] intValue]]];
		[objs addObjectsFromArray:kObjectivesEveryTrack];
		NSDictionary *dict = [objs objectAtIndex:[[awards objectAtIndex:rowIndex] intValue]];
		[aCell setTitle:$stringf(@"%@", [dict valueForKey:kRewardKey])];
#ifdef TARGET_OS_MAC
		[aCell setDrawsBackground:NO];
#endif
		NSImage *image = [NSImage imageNamed:[dict valueForKey:kIconKey]];
		[aCell setImage:image];
	}
	else if (aTableView == statusCareerTable)
	{
		if (rowIndex == 0)
		{
			[aCell setTitle:$stringf(NSLocalizedString(@"Money: %i", nil), $defaulti(kAvailableCashKey))];
#ifdef TARGET_OS_MAC
            [aCell setDrawsBackground:NO];
#endif
			NSImage *image = [NSImage imageNamed:@"reward_cash.png"];
			[aCell setImage:image];
		}
		else if (rowIndex == 1)
		{
			int unlocked = 0;
			for (uint32_t i = 1; i <= kNumShips; i++)
				if ($defaulti($stringf(kShipIUnlocked, i)))
					unlocked++;

			[aCell setTitle:$stringf(NSLocalizedString(@"Unlocked Ships: %i", nil), unlocked)];
#ifdef TARGET_OS_MAC
            [aCell setDrawsBackground:NO];
#endif
			NSImage *image = [NSImage imageNamed:@"reward_ship.png"];
			[aCell setImage:image];
		}
		else if (rowIndex == 2)
		{
			int unlocked = 0;
			for (uint32_t i = 1; i <= kNumTracks * 2; i++)
				if ($defaulti($stringf(kTrackIUnlocked, i)))
					unlocked++;

			[aCell setTitle:$stringf(NSLocalizedString(@"Unlocked Tracks: %i", nil), unlocked)];
#ifdef TARGET_OS_MAC
            [aCell setDrawsBackground:NO];
#endif
			NSImage *image = [NSImage imageNamed:@"reward_track.png"];
			[aCell setImage:image];
		}
	}
	else if (aTableView == laptimesTimeattackTable ||
			aTableView == laptimesCustomTable ||
			aTableView == laptimesMultiplayer1Table ||
			aTableView == laptimesMultiplayer2Table)
	{
		[aCell setTitle:[(aTableView == laptimesMultiplayer2Table ? laptimes2 : laptimes) objectAtIndex:rowIndex]];
#ifdef TARGET_OS_MAC
		[aCell setDrawsBackground:NO];
#endif
		NSImage *image = [NSImage imageNamed:([self numberOfRowsInTableView:aTableView] - 1 == rowIndex) ? @"icon_flag" : @"icon_stopwatch"];
		[aCell setImage:image];
	}
	else if ([newhighscoreindices indexOfObject:$numi(rowIndex)] != NSNotFound)
	{
#ifndef __COCOTRON__
		[aCell setDrawsBackground:YES];
#endif
		[(NSTextFieldCell *) aCell setBackgroundColor:[NSColor colorWithCalibratedRed:0.7 green:0.7 blue:1.0 alpha:1.0]];
	}
	else if ([[self tableView:aTableView objectValueForTableColumn:TC row:rowIndex] isEqualToString:$default(kNicknameKey)])
	{
#ifndef __COCOTRON__
		[aCell setDrawsBackground:YES];
#endif
		[(NSTextFieldCell *) aCell setBackgroundColor:[NSColor colorWithCalibratedRed:0.8 green:0.8 blue:0.8 alpha:1.0]];
	}
	else
	{
#ifdef TARGET_OS_MAC
		[aCell setDrawsBackground:NO];
#endif
		[(NSTextFieldCell *) aCell setBackgroundColor:[NSColor whiteColor]];
	}
}
@end