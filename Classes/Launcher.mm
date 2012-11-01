//
//  Launcher.m
//  Core3D
//
//  Created by CoreCode on 19.05.08.
//  Copyright 2008 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "Core3D.h"
#import "Launcher.h"
#import "Highscores.h"
#import "NSView+Snapshot.h"
#import "NSView+GridCalculation.h"


#ifdef SDL
inline bool gt_rect (SDL_Rect r1, SDL_Rect r2)
{
    if (r1.w == r2.w)
        return ((r1.h) > (r2.h));
    else
        return ((r1.w) > (r2.w));
}
inline bool eq_rect (SDL_Rect r1, SDL_Rect r2) { return ((r1.w == r2.w) && (r1.h == r2.h)); }
#endif

#ifdef __APPLE__
#import <ShortcutRecorder/ShortcutRecorder.h>
#import <QuartzCore/CoreAnimation.h>


#endif

BOOL launcherAlive = NO;

@implementation Launcher

@synthesize customHighscores;
@synthesize timeattackHighscores;
@synthesize carreerHighscores;
@synthesize new_spaceship_hidden;
@synthesize new_spaceship2_hidden;
@synthesize new_racetrack_hidden;



+ (void)initialize
{
	[CoreBreach initialize];
}

- (void)updateShipNew
{
	if ((gameModeEnum) $defaulti(kGameModeKey) == kGameModeCustomGame)
	{
		[self setNew_spaceship_hidden:$defaulti($stringf(kShipISeenKey, $defaulti(kCustomraceShipNumKey)))];
	}
	else if ((gameModeEnum) $defaulti(kGameModeKey) == kGameModeCareer)
	{
		[self setNew_spaceship_hidden:$defaulti($stringf(kShipISeenKey, $defaulti(kShipNumKey)))];
	}
	else if ((gameModeEnum) $defaulti(kGameModeKey) == kGameModeTimeAttack)
	{
		[self setNew_spaceship_hidden:$defaulti($stringf(kShipISeenKey, $defaulti(kTimeattackShipNumKey)))];
	}
	else if ((gameModeEnum) $defaulti(kGameModeKey) == kGameModeMultiplayer)
	{
		[self setNew_spaceship_hidden:$defaulti($stringf(kShipISeenKey, $defaulti(kMultiplayerShipNumKey)))];
		[self setNew_spaceship2_hidden:$defaulti($stringf(kShipISeenKey, $defaulti(kMultiplayerShip2NumKey)))];
	}
}

- (void)updateTrackNew
{
	if ((gameModeEnum) $defaulti(kGameModeKey) == kGameModeCustomGame)
	{
		[self setNew_racetrack_hidden:$defaulti($stringf(kTrackISeenKey, $defaulti(kCustomraceTrackNumKey)))];
	}
	else if ((gameModeEnum) $defaulti(kGameModeKey) == kGameModeCareer)
	{
		[self setNew_racetrack_hidden:$defaulti($stringf(kTrackISeenKey, $defaulti(kTrackNumKey)))];
	}
	else if ((gameModeEnum) $defaulti(kGameModeKey) == kGameModeTimeAttack)
	{
		[self setNew_racetrack_hidden:$defaulti($stringf(kTrackISeenKey, $defaulti(kTimeattackTrackNumKey)))];
	}
	else if ((gameModeEnum) $defaulti(kGameModeKey) == kGameModeMultiplayer)
	{
		[self setNew_racetrack_hidden:$defaulti($stringf(kTrackISeenKey, $defaulti(kMultiplayerTrackNumKey)))];
	}
}

- (void)updateCarreerInformation
{
#ifdef TARGET_OS_MAC
    //    [upgradeWeaponsButton setTitle:$stringf(@"Upgrade Weapons\n☆☆☆☆☆")];

    //    NSMutableString *s = $stringm(@"Upgrade Handling\n");
    //
    //    if ($defaulti($stringf(kTrackISeen)))
    //
    //    [upgradeWeaponsButton setTitle:$stringf(@"Upgrade Weapons\n☆☆☆☆☆")];
    NSView *v = [[NSView alloc] initWithFrame:NSMakeRect(0,0, 125, 13)];

    for (int i = 0; i < 5; i++)
    {
        CGRect r1 = [NSView calculateFrameForGridElementX:i ofX:5 size:CGSizeMake(125,13) spacing:1.0];
        NSLevelIndicator *ind = [[[NSLevelIndicator alloc] initWithFrame:NSRectFromCGRect(r1)] autorelease];
        [ind setMaxValue:1];
        [ind setFloatValue:$defaulti([kWeaponUpgradesKeyNames objectAtIndex:i])];
        [v addSubview:ind];
    }

    [upgradeWeaponsButton setImage:[v snapshotIncludingSubviews]];
    [v release];


    NSLevelIndicator *li = [[[NSLevelIndicator alloc] initWithFrame:NSMakeRect(0,0, 125, 13)] autorelease];
    [li setMaxValue:3];


    [li setFloatValue:$defaulti($stringf(kShipITopSpeedUpgrades, $defaulti(kShipNumKey)))];
    [upgradeTopSpeedButton setImage:[li snapshotFromRect:NSMakeRect(0,0, 125, 13)]];

    [li setFloatValue:$defaulti($stringf(kShipIHandlingUpgrades, $defaulti(kShipNumKey)))];
    [upgradeHandlingButton setImage:[li snapshotFromRect:NSMakeRect(0,0, 125, 13)]];

    [li setFloatValue:$defaulti($stringf(kShipIAccelerationUpgrades, $defaulti(kShipNumKey)))];
    [upgradeAccelerationButton setImage:[li snapshotFromRect:NSMakeRect(0,0, 125, 13)]];
#else
	[upgradeWeaponsButton setImage:[NSImage imageNamed:$stringf(@"upgrade5_%i%i%i%i%i", $defaulti([kWeaponUpgradesKeyNames objectAtIndex:0]), $defaulti([kWeaponUpgradesKeyNames objectAtIndex:1]), $defaulti([kWeaponUpgradesKeyNames objectAtIndex:2]), $defaulti([kWeaponUpgradesKeyNames objectAtIndex:3]), $defaulti([kWeaponUpgradesKeyNames objectAtIndex:4]))]];



	[upgradeTopSpeedButton setImage:[NSImage imageNamed:$stringf(@"upgrade3_%i", $defaulti($stringf(kShipITopSpeedUpgrades, $defaulti(kShipNumKey))))]];

	[upgradeHandlingButton setImage:[NSImage imageNamed:$stringf(@"upgrade3_%i", $defaulti($stringf(kShipIHandlingUpgrades, $defaulti(kShipNumKey))))]];

	[upgradeAccelerationButton setImage:[NSImage imageNamed:$stringf(@"upgrade3_%i", $defaulti($stringf(kShipIAccelerationUpgrades, $defaulti(kShipNumKey))))]];

#endif
}

- (void)updateResolutionLabel
{
#ifndef SDL
	NSSize s = CalculateReducedResolution([[NSScreen mainScreen] frame].size);

	[resolutionLabel setStringValue:$stringf(@"%.0f x %.0f", s.width, s.height)];
#endif
}

- (IBAction)fullscreenResolutionAction:(id)sender
{
#ifdef __APPLE__
	[self updateResolutionLabel];
#endif
}

- (IBAction)songStateChanged:(id)sender
{
	NSInteger i = [sender selectedRow];
	if (i < 0 || i >= (NSInteger) [kMusicNames count])
		return;

	NSString *song = [kMusicNames objectAtIndex:i];
	NSUInteger songIndex = [$default(kMusicNamesKey) indexOfObject:song];

	if (songIndex != NSNotFound) // disable
	{
		NSMutableArray *songs = [NSMutableArray arrayWithArray:$default(kMusicNamesKey)];

		[songs removeObjectAtIndex:songIndex];

		$setdefault(songs, kMusicNamesKey);
	}
	else // enable
	{
		NSMutableArray *songs = [NSMutableArray arrayWithArray:$default(kMusicNamesKey)];

		[songs addObject:song];

		$setdefault(songs, kMusicNamesKey);
	}

	$defaultsync;

	[songListTable reloadData];
}

- (IBAction)sendFeedback:(id)sender
{
	NSString *urlStr = @"mailto:corebreach@corecode.at?subject=CoreBreach Feedback";

	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
}

- (IBAction)visitHomepage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://corebreach.corecode.at/"]];
}

- (IBAction)additionalTracks:(id)sender
{
#ifdef DEMO
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://corebreach.corecode.at/CoreBreach/Buy.html"]];
//    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.macgamestore.com/product/2013"]];
#else
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://corebreach.corecode.at/CoreBreach/Tracks.html"]];
#endif
}

- (IBAction)openVersionHistory:(id)sender
{
	[[NSWorkspace sharedWorkspace] openFile:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"History.rtf"]];
}

- (IBAction)gameManual:(id)sender
{
	if (![[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"Manual" ofType:@"pdf"]])
		NSRunAlertPanel(@"CoreBreach", NSLocalizedString(@"Please install a PDF-Reader to view the manual.\n", nil), NSLocalizedString(@"OK", nil), nil, nil);

#ifndef TARGET_OS_MAC
#ifdef GNUSTEP
    NSString *p = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"README.txt"];
#endif
#ifdef __COCOTRON__
    NSString *p = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"README.rtf"];
#endif
	[[NSWorkspace sharedWorkspace] openFile:p];
#endif
}

- (void)updateInternetHighscores:(int)mode forTrackNum:(uint32_t)trackNum
{
	NSTableView *table;
	if (mode == kGameModeCareer)
		table = careerInternetHighscoresTable;
	else if (mode == kGameModeCustomGame)
		table = customInternetHighscoresTable;
	else if (mode == kGameModeTimeAttack)
		table = timeattackInternetHighscoresTable;
	else
			assert(0);

	[self retain];

#ifdef TARGET_OS_MAC
	dispatch_async(dispatch_get_global_queue(0, 0), ^{
#else
	if (!globalInfo.online)
		return;
#endif
	Highscores *hs = [[Highscores alloc] init];

	NSArray *hsa = [hs getHighscoresForMode:mode forNickname:$default(kNicknameKey) onTrack:trackNum];

	if (mode == kGameModeCareer)
		[self setCarreerHighscores:hsa];
	else if (mode == kGameModeCustomGame)
		[self setCustomHighscores:hsa];
	else if (mode == kGameModeTimeAttack)
		[self setTimeattackHighscores:hsa];

	[hs release];

#ifdef TARGET_OS_MAC
		dispatch_async(dispatch_get_main_queue(), ^{
#endif
	if (launcherAlive)
		[table reloadData]; // TODO: this can crash

#ifdef TARGET_OS_MAC
		});
	});
#endif

	[table reloadData];
}

- (void)openNews
{
#ifdef TARGET_OS_MAC
    //NSLog(@"%f %@ %@",  [$default(@"LatestNewsSeen") timeIntervalSinceDate:[appController latestNews]], [$default(@"LatestNewsSeen") description], [[appController latestNews] description]);
    if (![appController latestNews] ||
        [$default(@"LatestNewsSeen") timeIntervalSinceDate:[appController latestNews]] > 0)
        return;
    
    if (!careerInternetHighscoresTable)
        return;
    
    $setdefault([NSDate date], @"LatestNewsSeen");
    
    //    [bannerImage setImage:[NSImage imageNamed:@"corebreach_poster_noship"]];
    NSImageView *n = [[NSImageView alloc] initWithFrame:[bannerImage frame]];
    [n setImage:[NSImage imageNamed:@"corebreach_poster_noship"]];
    [[contentView animator] replaceSubview:bannerImage with:n];
    [n release];
    bannerImage = n;
    
    NSMutableArray *subvies = [NSMutableArray arrayWithArray:[contentView subviews]];//Get all subviews..
    [newsBox retain]; //Retain the view to be made top view..
    [subvies removeObject:newsBox];//remove it from array
    [subvies addObject:newsBox];//add as last item
    [contentView setSubviews:subvies];//set the new array..
    [newsBox release];
    
    [[newsBox animator] performSelector:@selector(setHidden:) withObject:$numi(0) afterDelay:1.0];
#endif
}

- (IBAction)playAction:(id)sender
{
	//NSLog(@"play action");

//#ifdef GNUSTEP
//    $setdefaulti([difficultyCareer indexOfSelectedItem], kDifficultyKey);
//    $setdefaulti([difficultyCustom indexOfSelectedItem], kCustomraceDifficultyKey);
//    $setdefaulti([difficultyMultiplayer indexOfSelectedItem], kMultiplayerDifficultyKey);
//    $setdefaulti([roundsCustom indexOfSelectedItem], kCustomraceRoundsNumKey);
//    $setdefaulti([roundsMultiplayer indexOfSelectedItem], kMultiplayerRoundsNumKey);
//    $setdefaulti([enemiesCustom indexOfSelectedItem], kCustomraceEnemiesNumKey);
//    $setdefaulti([enemiesMultiplayer indexOfSelectedItem], kMultiplayerEnemiesNumKey);
//    $defaultsync;
//#endif

#ifdef __COCOTRON__ // bug #805
    $setdefaulti([bigTabView indexOfTabViewItem:[bigTabView selectedTabViewItem]], kGameModeKey);
    $defaultsync;
#endif


#ifdef DEMO
     if ((gameModeEnum) $defaulti(kGameModeKey) != kGameModeCustomGame)
     {
         NSRunAlertPanel(@"CoreBreach", NSLocalizedString(@"Sorry, only \"Custom Races\" are enabled in this demo version!\n", nil), NSLocalizedString(@"OK", nil), nil, nil);
         return;
     }
    int demoTrack = 2;
    if ($defaulti(kCustomraceTrackNumKey) != demoTrack)
    {
        NSRunAlertPanel(@"CoreBreach", $stringf(NSLocalizedString(@"Sorry, only Track %i \"%@\" is enabled in this demo version!\n", nil), demoTrack+1, [kTrackNames objectAtIndex:demoTrack]), NSLocalizedString(@"OK", nil), nil, nil);
        return;
    }
#endif


#ifdef TARGET_OS_MAC
    [appController cleanup];
#endif
	[[NSRunLoop currentRunLoop] cancelPerformSelectorsWithTarget:self];
	launching = TRUE;

	[careerInternetHighscoresTable setDataSource:nil];
	[careerLocalHighscoresTable setDataSource:nil];

	careerInternetHighscoresTable = nil;
	timeattackInternetHighscoresTable = nil;
	customInternetHighscoresTable = nil;


	[window close];

	[configureControlsSheet close];
	[configureAudioSheet close];
	[configureVideoSheet close];
	[configureGameSheet close];


#ifdef TARGET_OS_MAC
	[addThisWebview setPolicyDelegate:nil];
	[addThisWebview setUIDelegate:nil];
    addThisWebview = nil;
#endif



	//NSLog(@"play");

	LOAD_NIB(@"Core3D", NSApp);

#ifdef SDL
    [self release];
//    [self release];
#else
	[self autorelease];
#endif
}

- (void)warnOpenGL
{
	NSRunAlertPanel(@"CoreBreach", @"CoreBreach requires up-to-date OpenGL drivers and an OpenGL 2.1 compliant video card with support for EXT_framebuffer_object, i.e \n Radeon HD 2400  or \n GeForce 7300 or \n HD Graphics 3000 or better.\n\n Trying to play the game on your hardware may result in crashes - continue at your own risk!", @"OK", nil, nil);
}

- (void)awakeFromNib
{

	// TODO: we have a unreported gnustep problem here, menu gone on second try

	//NSLog(@"launcher awake");
	launcherAlive = YES;

	if (loaded) return; // avoid double calling through loading of the configure sheet
	loaded = YES;

#ifdef __COCOTRON__
    [cashLabel setIntValue:$defaulti(kAvailableCashKey)];
#endif

#ifndef TARGET_OS_MAC
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"http://corebreach.corecode.at/network_test.txt"]];
	[request setTimeoutInterval:2.0];
	NSData *testData = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:NULL];
	char magic[5] = "blam";
	globalInfo.online = (testData && [testData isEqualToData:[NSData dataWithBytes:magic length:4]]);
	[request release];
#endif



#ifdef TARGET_OS_MAC
    if (globalInfo.VRAM / (1024 * 1024) < 256 &&
        $defaulti(kTextureQualityKey) == 0)
        $setdefaulti(1, kTextureQualityKey);
    

    [(NSNotificationCenter *)[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTrackMenus:) name:@"mapInstalled" object:nil];
#endif


	savedDifficulty = $defaulti(kDifficultyKey);


//    Highscores *hs = [[Highscores alloc] init];
//    int bla = 0xBAFE;
//	[hs sendHighscore:48.666 forMode:kGameModeTimeAttack forNickname:@"XXXXentenraserXXXXXXX" onTrack:0 withShip:1 withData:[NSData dataWithBytes:&bla length:4]];
//    [hs release];




	[NSCursor unhide];

	if (!configureControlsSheet)
#if defined(TARGET_OS_MAC) && defined(SDL)
		[NSBundle loadNibNamed:@"Launcher-ConfigureControlsSheet-windows" owner:self];
#else
		LOAD_NIB(@"Launcher-ConfigureControlsSheet", self);
#endif



#ifdef TARGET_OS_MAC
	[[[addThisWebview mainFrame] frameView] setAllowsScrolling:NO];
	[addThisWebview setDrawsBackground:NO];
	[addThisWebview setMainFrameURL:@"http://corebreach.corecode.at/addthis.html"];
	[addThisWebview alignCenter:self];
#else
#ifdef __COCOTRON__
    

      [bigTabView selectTabViewItemAtIndex:$defaulti(kGameModeKey)];
#endif
//    [shipPopupCareer selectItemAtIndex:$defaulti(kShipNumKey)];
//    [shipPopupTimeAttack selectItemAtIndex:$defaulti(kTimeattackShipNumKey)];
//    [shipPopupCustom selectItemAtIndex:$defaulti(kCustomraceShipNumKey)];
//    [shipPopupMultiplayer1 selectItemAtIndex:$defaulti(kMultiplayerShipNumKey)];
//    [shipPopupMultiplayer2 selectItemAtIndex:$defaulti(kMultiplayerShip2NumKey)];
//    [trackPopupCareer selectItemAtIndex:$defaulti(kTrackNumKey)];
//    [trackPopupTimeAttack selectItemAtIndex:$defaulti(kTimeattackTrackNumKey)];
//    [trackPopupCustom selectItemAtIndex:$defaulti(kCustomraceTrackNumKey)];
//    [trackPopupMultiplayer selectItemAtIndex:$defaulti(kMultiplayerTrackNumKey)];
//
//    [difficultyCareer selectItemAtIndex:$defaulti(kDifficultyKey)];
//    [difficultyCustom selectItemAtIndex:$defaulti(kCustomraceDifficultyKey)];
//    [difficultyMultiplayer selectItemAtIndex:$defaulti(kMultiplayerDifficultyKey)];
//    [roundsCustom selectItemAtIndex:$defaulti(kCustomraceRoundsNumKey)];
//    [roundsMultiplayer selectItemAtIndex:$defaulti(kMultiplayerRoundsNumKey)];
//    [enemiesCustom selectItemAtIndex:$defaulti(kCustomraceEnemiesNumKey)];
//    [enemiesMultiplayer selectItemAtIndex:$defaulti(kMultiplayerEnemiesNumKey)];
#endif



#ifdef DEMO
    [additionalTracksButton setTitle:NSLocalizedString(@"BUY FULL VERSION!", nil)];
#ifdef TARGET_OS_MAC
    CGColorRef c = CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0);
    [additionalTracksButton layer].shadowColor = c;
    [additionalTracksButton layer].shadowOpacity = 1.0;
    [additionalTracksButton layer].shadowOffset = CGSizeMake(0, 0);
    CGColorRelease(c);
#endif
#endif



	NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"Rank" ascending:YES];
	[customInternetHighscoresTable setSortDescriptors:[NSArray arrayWithObject:sd]];
	[customLocalHighscoresTable setSortDescriptors:[NSArray arrayWithObject:sd]];
	[timeattackInternetHighscoresTable setSortDescriptors:[NSArray arrayWithObject:sd]];
	[timeattackLocalHighscoresTable setSortDescriptors:[NSArray arrayWithObject:sd]];
	[careerInternetHighscoresTable setSortDescriptors:[NSArray arrayWithObject:sd]];
	[careerLocalHighscoresTable setSortDescriptors:[NSArray arrayWithObject:sd]];
	[sd release];


	[self updateTrackMenus:nil];

	[self trackAction:self];
	[self shipAction:self];
	[self trackTimeattackAction:self];
	[self shipTimeattackAction:self];
	[self trackCustomAction:self];
	[self shipCustomAction:self];
	[self trackMultiplayerAction:self];
	[self shipMultiplayerAction:self];
	[self shipMultiplayer2Action:self];


	{ // setup saved keys
#ifndef SDL
		NSArray *keyNames = KEYS

		NSMutableArray *views = [NSMutableArray arrayWithArray:[[player1Box contentView] subviews]];
		[views addObjectsFromArray:[[player2Box contentView] subviews]];

		for (NSView *view in views)
		{
			if ([view isKindOfClass:[SRRecorderControl class]])
			{
				[(SRRecorderControl *) view setKeyCombo:SRMakeKeyCombo([$default([keyNames objectAtIndex:[view tag] - 1]) intValue], 0)];
//                [(SRRecorderControl *)view setAllowedFlags:0];
//                [(SRRecorderControl *)view setAllowsKeyOnly:YES escapeKeysRecord:NO];
			}
		}
#endif
	}


	{ // setup input modes and saved inputs
		int i = 1;
#ifdef SDL
        const int tagmin = 1;
#else
		const int tagmin = 0;
#endif
		NSString *keyboardname = [player1InputDevicePopup itemTitleAtIndex:0];
		[player1InputDevicePopup removeAllItems];
		[player2InputDevicePopup removeAllItems];
		[player1InputDevicePopup addItemWithTitle:keyboardname];
		[player2InputDevicePopup addItemWithTitle:keyboardname];


		$setdefaulti(0, kPlayer1InputDeviceIndexKey);
		$setdefaulti(0, kPlayer2InputDeviceIndexKey);
		[player1InputDevicePopup selectItemAtIndex:0];
		[player2InputDevicePopup selectItemAtIndex:0];
		NSString *p1devname = $default(kPlayer1InputDeviceNameKey);
		NSString *p2devname = $default(kPlayer2InputDeviceNameKey);
		for (NSDictionary *hid in [[HIDSupport sharedInstance] hidDevices])
		{

			NSString *newdev = [hid objectForKey:@"name"];
			[player1InputDevicePopup addItemWithTitle:$stringf(@"%i: %@", i, newdev)];
			if ([newdev isEqualToString:p1devname])
			{
				[player1InputDevicePopup selectItemAtIndex:i];
				$setdefaulti(i, kPlayer1InputDeviceIndexKey);
				for (NSView *view in [[player1Box contentView] subviews])
				{
					if ([view isKindOfClass:[NSButton class]] && ([view tag] - tagmin) < kKeyCount * 2)
					{
						NSString *name = [[HIDSupport sharedInstance] nameOfItem:([view tag] - tagmin)];
						if (name)
							[(NSButton *) view setTitle:name];
					}
				}
			}
			[player2InputDevicePopup addItemWithTitle:$stringf(@"%i: %@", i, newdev)];
			if ([newdev isEqualToString:p2devname])
			{
				[player2InputDevicePopup selectItemAtIndex:i];
				$setdefaulti(i, kPlayer2InputDeviceIndexKey);
				for (NSView *view in [[player2Box contentView] subviews])
				{
					if ([view isKindOfClass:[NSButton class]] && ([view tag] - tagmin) < kKeyCount * 2)
					{

						NSString *name = [[HIDSupport sharedInstance] nameOfItem:([view tag] - tagmin)];
						if (name)
							[(NSButton *) view setTitle:name];
					}
				}
			}
			i++;
		}
	}


	{ // setup ship popups
		for (NSPopUpButton *popup in $array(shipPopupCareer, shipPopupCustom, shipPopupTimeAttack, shipPopupMultiplayer1, shipPopupMultiplayer2))
		{
			int previousSelection = [popup indexOfSelectedItem];
			[popup removeAllItems];

			for (NSString *shipname in kShipNames)
				[popup addItemWithTitle:$stringf(@"%@", shipname)];

			[popup selectItemAtIndex:previousSelection];
		}
	}



	[self disableLockedMenuItems];


	[self updateCarreerInformation];



	[NSApp activateIgnoringOtherApps:YES];
	[window center];
	[window makeKeyAndOrderFront:self];


	//[self playAction:self];


	if ($defaulti(kInternetNewsEnabledKey))
		[self performSelector:@selector(openNews) withObject:nil afterDelay:5.0];



	if ($defaulti(@"skipmenu"))
		[self performSelector:@selector(playAction:) withObject:nil afterDelay:1.0];

//#ifdef TEST
//    [self performSelector:@selector(playAction:) withObject:nil afterDelay:cml::random_real(0, 4)];
//    #warning revert
//#endif

#ifndef TARGET_OS_MAC
	if (!globalInfo.properOpenGL)
	{
		[self performSelector:@selector(warnOpenGL) withObject:nil afterDelay:0.1]; // TODO: we have an unreported gnustep bug, fucked up  when doing NSRunAlertPanel during awakefromnib
	}
#endif
}

- (void)disableLockedMenuItems
{
	{ // disable locked ships and tracks
		[trackPopupCareer setAutoenablesItems:NO];
		for (int i = 1; i < kNumTracks * 2; i++)
		{
			if (!$defaulti($stringf(kTrackIUnlocked, i + 1)))
				[[trackPopupCareer itemAtIndex:CareerRealToPopup(i)] setEnabled:NO];
		}

		for (NSPopUpButton *popup in $array(trackPopupCustom, trackPopupTimeAttack, trackPopupMultiplayer))
		{
			[popup setAutoenablesItems:NO];
			for (int i = 6; i < kNumTracks * 2; i++)
				if (!$defaulti($stringf(kTrackIUnlocked, i + 1)))
					[[popup itemAtIndex:i] setEnabled:NO];
		}


		[shipPopupCareer setAutoenablesItems:NO];
		for (int i = 1; i < kNumShips; i++)
			if (!$defaulti($stringf(kShipIUnlocked, i + 1)))
				[[shipPopupCareer itemAtIndex:i] setEnabled:NO];

		for (NSPopUpButton *popup in $array(shipPopupCustom, shipPopupTimeAttack, shipPopupMultiplayer1, shipPopupMultiplayer2))
		{
			[popup setAutoenablesItems:NO];
			for (int i = 6; i < kNumShips; i++)
				if (!$defaulti($stringf(kShipIUnlocked, i + 1)))
					[[popup itemAtIndex:i] setEnabled:NO];
		}
	}
}

- (void)updateTrackMenus:(NSNotification *)notification
{
	for (NSPopUpButton *popup in $array(trackPopupCareer, trackPopupCustom, trackPopupTimeAttack, trackPopupMultiplayer))
	{
		int previousSelection = [popup indexOfSelectedItem];
		[popup removeAllItems];

		if (popup != trackPopupCareer)
		{
			for (NSString *trackname in kTrackNames)
				[popup addItemWithTitle:$stringf(@"%@", trackname)];

			for (NSString *trackname in kTrackNames)
				[popup addItemWithTitle:$stringf(@"%@ (Rev)", trackname)];

			[[popup menu] addItem:[NSMenuItem separatorItem]];
			NSArray *tracks = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:APPLICATION_SUPPORT_DIR error:NULL];

			for (NSString *track in tracks)
			{
				if ([track hasSuffix:@".cbtrack"])
					[popup addItemWithTitle:[[track lastPathComponent] stringByReplacingOccurrencesOfString:@".cbtrack" withString:@""]];
			}
		}
		else
		{
			for (NSString *trackname in kTrackNames)
			{
				[popup addItemWithTitle:$stringf(@"%@", trackname)];

				[popup addItemWithTitle:$stringf(@"%@ (Rev)", trackname)];
			}
		}

//        for (NSMenuItem *i in [popup itemArray])
//        {
//            [i setEnabled:YES];
//            [i setState:NSOnState];
//        }  
		[popup selectItemAtIndex:previousSelection];
	}
}

- (IBAction)careerDifficultyChanged:(id)sender
{
	if ($defaulti(kDifficultyKey) > savedDifficulty)
	{
		if (NSRunAlertPanel(@"CoreBreach", NSLocalizedString(@"You can increase the difficulty while completing the Career Mode, but decreasing the difficulty again will erase all your career-progress!", nil), NSLocalizedString(@"Proceed", nil), NSLocalizedString(@"Cancel", nil), nil) != NSAlertDefaultReturn)
		$setdefaulti(savedDifficulty, kDifficultyKey);
		else
			savedDifficulty = $defaulti(kDifficultyKey);
	}
	else if ($defaulti(kDifficultyKey) < savedDifficulty)
	{
		if (NSRunAlertPanel(@"CoreBreach", NSLocalizedString(@"Decreasing the difficulty while completing the Career Mode will erase all your career-progress!", nil), NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"Proceed", nil), nil) == NSAlertDefaultReturn)
		$setdefaulti(savedDifficulty, kDifficultyKey);
		else
		{
			$setdefaulti(0, kAvailableCashKey);

			$setdefaulti(0, kTrackNumKey);
			$setdefaulti(0, kShipNumKey);
			$setdefaulti(0, @"Story0Seen");
			$setdefaulti(0, @"Story2Seen");
			$setdefaulti(0, @"Story11Seen");
			$setdefaulti(0, @"StoryMovie0Seen");
			$setdefaulti(0, @"StoryMovie11Seen");

			savedDifficulty = $defaulti(kDifficultyKey);

			for (int i = 2; i <= kNumTracks * 2; i++)
					$setdefaulti(0, $stringf(@"Track%iUnlocked", i));

			for (long i = 0; i <= kNumShips; i++)
			{
				$setdefaulti(0, $stringf(@"Ship%liUnlocked", i));
				$setdefaulti(0, $stringf(kShipITopSpeedUpgrades, i));
				$setdefaulti(0, $stringf(kShipIHandlingUpgrades, i));
				$setdefaulti(0, $stringf(kShipIAccelerationUpgrades, i));
			}

			for (int i = 0; i < kNumTracks * 2; i++)
					$setdefaulti(0, $stringf(@"Track%iSeen", i));

			for (int i = 0; i < kNumShips; i++)
					$setdefaulti(0, $stringf(@"Ship%iSeen", i));

			for (NSString *weaponUpgrade in kWeaponUpgradesKeyNames)
					$setdefaulti(0, weaponUpgrade);



			$defaultsync;

#ifdef __COCOTRON__
            [cashLabel setIntValue:$defaulti(kAvailableCashKey)];
#endif

			[self disableLockedMenuItems];
			[self updateCarreerInformation];
			[self updateWeaponsSheet];
		}
	}
}

#ifndef __APPLE__
- (IBAction)clickableImageClicked:(id)sender;
{
   // NSLog(@"clicked");
    NSString *urlStr = @"http://corebreach.corecode.at/CoreBreach/News/News.html";
    
    
    if ([sender tag] == 0)
       urlStr = @"http://corebreach.corecode.at/CoreBreach/News/News.html";
    else if ([sender tag] == 10) // facebook
        urlStr = @"http://www.addthis.com/bookmark.php?v=250&winname=addthis&pub=xa-4d9c855d1cf9ff9a&source=tbx32-250&lng=es&s=facebook&url=http%3A%2F%2Fcorecode.corebreach.at&title=CoreBreach%20Mac%20Racing%20Game&ate=AT-xa-4d9c855d1cf9ff9a/-/-/4ebdb109cde568b1/4/4e2868962f366104&frommenu=1&uid=4e2868962f366104&ct=1&tt=0";
    else if ([sender tag] == 11) // twitter
            urlStr = @"http://www.addthis.com/bookmark.php?v=250&winname=addthis&pub=xa-4d9c855d1cf9ff9a&source=tbx32-250&lng=es&s=twitter&url=http%3A%2F%2Fcorecode.corebreach.at&title=CoreBreach%20Mac%20Racing%20Game&ate=AT-xa-4d9c855d1cf9ff9a/-/-/4ebdb109cde568b1/5/4e2868962f366104&frommenu=1&uid=4e2868962f366104&ct=1&template=CoreBreach%20Mac%20Racing%20Game%20{{url}}%20via%20%40AddThis&tt=0";
    else if ([sender tag] == 12) // blogger
            urlStr = @"http://www.addthis.com/bookmark.php?v=250&winname=addthis&pub=xa-4d9c855d1cf9ff9a&source=tbx32-250&lng=es&s=blogger&url=http%3A%2F%2Fcorecode.corebreach.at&title=CoreBreach%20Mac%20Racing%20Game&ate=AT-xa-4d9c855d1cf9ff9a/-/-/4ebdb109cde568b1/8/4e2868962f366104&frommenu=1&uid=4e2868962f366104&ct=1&tt=0";
    else if ([sender tag] == 13) // stumble
        urlStr = @"http://www.addthis.com/bookmark.php?v=250&winname=addthis&pub=xa-4d9c855d1cf9ff9a&source=tbx32-250&lng=de-de&s=stumbleupon&url=http%3A%2F%2Fcorecode.corebreach.at&title=CoreBreach%20Mac%20Racing%20Game&ate=AT-xa-4d9c855d1cf9ff9a/-/-/4ec149792a8e6eba/1&frommenu=1&uid=4ec149793bfa6d26&ct=1&tt=0";
    else if ([sender tag] == 14) // reddit
            urlStr = @"http://www.addthis.com/bookmark.php?v=250&winname=addthis&pub=xa-4d9c855d1cf9ff9a&source=tbx32-250&lng=de-de&s=reddit&url=http%3A%2F%2Fcorecode.corebreach.at&title=CoreBreach%20Mac%20Racing%20Game&ate=AT-xa-4d9c855d1cf9ff9a/-/-/4ec149792a8e6eba/2&frommenu=1&uid=4ec14979b8ded70a&ct=1&tt=0";

    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlStr]];
}
#endif

- (IBAction)closeNewsButtonAction:(id)sender
{
#ifdef TARGET_OS_MAC
    [bannerImage setImage:[NSImage imageNamed:@"corebreach_poster"]];
    [[newsBox animator] setHidden:YES];
#endif
}

- (void)dealloc
{
	launcherAlive = NO;
	//NSLog(@"launch de");
	[[NSNotificationCenter defaultCenter] removeObserver:self];

#ifdef TARGET_OS_MAC
    [appController release];
#endif

	[customHighscores release];
	[timeattackHighscores release];
	[carreerHighscores release];

	[controlWorkaroundDate release];

	[super dealloc];
}

#pragma mark SHEET methods

- (IBAction)carreerHighscoresAction:(id)sender
{
//	NSLog(@"beginSheet:highscoresSheet %x", highscoresSheet);
	[NSApp beginSheet:highscoresSheet modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)carreerHighscoresFinishedAction:(id)sender
{
	[NSApp endSheet:highscoresSheet];
	[highscoresSheet orderOut:self];
}

- (IBAction)configureVideoFinishedAction:(id)sender
{
	if ([NSColorPanel sharedColorPanelExists])
		[[NSColorPanel sharedColorPanel] close];


	[NSApp endSheet:configureVideoSheet];
	[configureVideoSheet orderOut:self];

#ifndef TARGET_OS_MAC
	if ([resolutionPopup indexOfSelectedItem])
	$setdefault([resolutionPopup titleOfSelectedItem], kVideoresolutionKey);
	else
			$setdefault(@"", kVideoresolutionKey);

//#ifdef GNUSTEP // bug #34492
//    NSArray *keys = $array(@"", kFullscreenKey, kShadowSizeKey, kShadowFilteringKey, kFsaaKey, kTextureQualityKey, kFilterQualityKey, kParticleQualityKey, kLightQualityKey, kPostProcessingKey, kDisplayEnemyNamesKey, kOutlinesKey);
//
//    for (NSView *b in [[configureVideoSheet contentView] subviews])
//        for (NSView *v in [b subviews])
//            if ([v isKindOfClass:[NSPopUpButton class]] && [v tag])
//                $setdefaulti([(NSPopUpButton *)v indexOfSelectedItem], [keys objectAtIndex:[v tag]]);
//#endif
#endif
	$defaultsync;
}

- (IBAction)configureGameFinishedAction:(id)sender
{
//#ifdef GNUSTEP // bug #34751 
//    [configureGameSheet makeFirstResponder:nil];
//#endif
	[NSApp endSheet:configureGameSheet];
	[configureGameSheet orderOut:self];
	$defaultsync;
}

- (IBAction)configureAudioFinishedAction:(id)sender
{
	[NSApp endSheet:configureAudioSheet];
	[configureAudioSheet orderOut:self];
	$defaultsync;
}

- (IBAction)configureAudioAction:(id)sender
{
	[songListTable reloadData]; // TODO: unreported gnustep bug

	[NSApp beginSheet:configureAudioSheet modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)configureVideoAction:(id)sender
{
#if defined(SDL) && !defined(TARGET_OS_MAC)
    if(SDL_Init(SDL_INIT_VIDEO) < 0)
        fatal("Error: video initialization failed: %s\n", SDL_GetError());

    const SDL_VideoInfo *info = NULL;
	info = SDL_GetVideoInfo();

    [resolutionPopup removeAllItems];
    [resolutionPopup addItemWithTitle:$stringf(@"Current (%i x %i)", info->current_w, info->current_h)];
    [[resolutionPopup menu] addItem:[NSMenuItem separatorItem]];
    [resolutionPopup selectItemAtIndex:0];



    SDL_Rect **tmodes = SDL_ListModes( NULL, SDL_HWSURFACE | SDL_FULLSCREEN );
	vector<SDL_Rect> modes;

	// put all dynamic determined modes into the vector
	for( int i = 0; tmodes[i] != NULL; i++ )
	{
		modes.push_back( *tmodes[i] );
	}

	// sort vector by (w,h)
	sort( modes.begin(), modes.end(), gt_rect );
	// make items in vector unique
	vector<SDL_Rect>::iterator new_end = unique( modes.begin(), modes.end(), eq_rect );
	for( vector<SDL_Rect>::iterator mi = modes.begin(); mi != new_end; ++mi )
	{
        NSString *title = $stringf(@"%i x %i", ((SDL_Rect)(*mi)).w, ((SDL_Rect)(*mi)).h);
        [resolutionPopup addItemWithTitle:title];

        if ([$default(kVideoresolutionKey) isEqualToString:title])
            [resolutionPopup selectItemWithTitle:title];
	}

    SDL_Quit();
#else
	[self updateResolutionLabel];
#endif

//#ifdef GNUSTEP // bug #34492
//    NSArray *keys = $array(@"", kFullscreenKey, kShadowSizeKey, kShadowFilteringKey, kFsaaKey, kTextureQualityKey, kFilterQualityKey, kParticleQualityKey, kLightQualityKey, kPostProcessingKey, kDisplayEnemyNamesKey, kOutlinesKey);
//
//    for (NSView *b in [[configureVideoSheet contentView] subviews])
//        for (NSView *v in [b subviews])
//            if ([v isKindOfClass:[NSPopUpButton class]] && [v tag])
//                [(NSPopUpButton *)v selectItemAtIndex:$defaulti([keys objectAtIndex:[v tag]])];
//#endif

	[NSApp beginSheet:configureVideoSheet modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)configureGameAction:(id)sender
{
	[NSApp beginSheet:configureGameSheet modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

#pragma mark UPGRADE methods

- (IBAction)upgradeFinishedAction:(id)sender
{
	//NSLog(@"upgradeFinishedAction");

	[NSApp endSheet:upgradeSheet];
	[upgradeSheet orderOut:self];
}

- (void)updateUpgradeSheet:(shipAttributeEnum)mode
{
	//NSLog(@"updateUpgradeSheet");

	currentUpgradeMode = mode;
	NSArray *costs, *upgrades, *values;
	NSString *name;
	[UpgradeHandler getCosts:&costs upgrades:&upgrades values:&values name:&name forMode:mode];

	float value = [[values objectAtIndex:$defaulti(kShipNumKey)] floatValue];


	[upgradeSheetBox setTitle:$stringf(@"%@ %@ %@", NSLocalizedString(@"Upgrade", nil), [kShipNames objectAtIndex:$defaulti(kShipNumKey)], NSLocalizedString(name, nil))];

	NSView *view = [upgradeSheet contentView];

	for (int i = 1; i <= 3; i++)
	{
		NSButton *b = [view viewWithTag:i];

		[b setTitle:$stringf(NSLocalizedString(@"Buy Upgrade #%i", nil), i)];
		[b setEnabled:YES];

		if (i - 1 < $defaulti($stringf(kShipIAUpgrades, $defaulti(kShipNumKey), name)))
			[b setTitle:NSLocalizedString(@"Upgrade already installed!", nil)];
		if (i - 1 != $defaulti($stringf(kShipIAUpgrades, $defaulti(kShipNumKey), name)))
			[b setEnabled:NO];

//#ifdef __COCOTRON__
//            [b setTitle:NSLocalizedString(@"Upgrade not yet available!", nil)];
//#else
//        
//#endif
	}

	for (int i = 11; i <= 13; i++)
	{
		NSTextField *t = [view viewWithTag:i];
		value += [[upgrades objectAtIndex:i - 11] floatValue];

		[t setStringValue:$stringf(NSLocalizedString(@"Upgrade #%i to %.0f%% for %@$:", nil), i - 10, (value * 10.0), [costs objectAtIndex:i - 11])];
	}

	float upgradedValue = [UpgradeHandler currentUpgradedValue:mode forShip:$defaulti(kShipNumKey)];
	[upgradeSheetCurrentIndicator setDoubleValue:upgradedValue];
	[[view viewWithTag:20] setStringValue:$stringf(@"%.0f%%", upgradedValue * 10.0)];
	[[view viewWithTag:21] setStringValue:$stringf(@"%@ %@", NSLocalizedString(@"Current", nil), NSLocalizedString(name, nil))];
}

- (IBAction)upgradeHandlingAction:(id)sender
{
	//NSLog(@"upgradeHandlingAction");

	[self updateUpgradeSheet:kHandling];

	[NSApp beginSheet:upgradeSheet modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)upgradeTopSpeedAction:(id)sender
{
	//NSLog(@"upgradeTopSpeedAction");

	[self updateUpgradeSheet:kTopSpeed];

	[NSApp beginSheet:upgradeSheet modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)upgradeAccelerationAction:(id)sender
{
	//NSLog(@"upgradeAccelerationAction");

	[self updateUpgradeSheet:kAcceleration];

	[NSApp beginSheet:upgradeSheet modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

#ifdef GNUSTEP
- (void)hideNoMoney
{
    [shipUpgradeNoMoneyText setHidden:YES];
    [weaponUpgradeNoMoneyText setHidden:YES];
}
#endif

- (void)doBuyFeedback:(BOOL)successfull
{
	//NSLog(@"doBuyFeedback");

#ifdef TARGET_OS_MAC
    CGColorRef c = CGColorCreateGenericRGB(1.0, (successfull ? 0.95 : 0.0), (successfull ? 0.95 : 0.0), 1.0);
    [cashBox layer].shadowColor = c;
    CGColorRelease(c);

    CABasicAnimation *theAnimation;
    theAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    theAnimation.duration = 0.5;
    theAnimation.autoreverses = YES;
    theAnimation.fromValue = $num(0.0);
    theAnimation.toValue = $num(1.0);
    theAnimation.repeatCount = 1;
    theAnimation.removedOnCompletion = YES;

    [[cashBox layer] addAnimation:theAnimation forKey:@"animateShadowOpacity"];

    if (successfull)
        [(NSSound *)[NSSound soundNamed:@"antique_cash_register_punching_single_key"] play];
    else
        [(NSSound *)[NSSound soundNamed:@"Basso"] play];
#elif defined(__COCOTRON__) && defined(WIN32)
    if (successfull)
        [(NSSound *)[NSSound soundNamed:@"antique_cash_register_punching_single_key"] play];
    else
    {
        NSSound *snd = [[NSSound alloc] initWithContentsOfFile:@"C:/WINDOWS/Media/chord.wav" byReference:NO];
        [snd play];
        [snd release];
    }
#else
	if (!successfull)
	{
		[shipUpgradeNoMoneyText setHidden:NO];
		[weaponUpgradeNoMoneyText setHidden:NO];
		[self performSelector:@selector(hideNoMoney) withObject:nil afterDelay:1.0 inModes:[NSArray arrayWithObjects:NSDefaultRunLoopMode, NSModalPanelRunLoopMode, nil]];
	}
#endif
}

- (IBAction)buyUpgradeAction:(id)sender
{
	//NSLog(@"buyUpgradeAction");
	NSArray *costs, *upgrades, *values;
	NSString *name;
	[UpgradeHandler getCosts:&costs upgrades:&upgrades values:&values name:&name forMode:currentUpgradeMode];



	NSString *key = $stringf(kShipIAUpgrades, $defaulti(kShipNumKey), name);
	int curr = $defaulti(key);
	int money = $defaulti(kAvailableCashKey);
	int cost = [[costs objectAtIndex:curr] floatValue];

	if (cost > money)
	{
		[self doBuyFeedback:NO];

		return;
	}

	$setdefaulti(curr + 1, key);
	$setdefaulti(money - cost, kAvailableCashKey);

	$defaultsync;
#ifdef __COCOTRON__
    [cashLabel setIntValue:$defaulti(kAvailableCashKey)];
#endif
	[self updateUpgradeSheet:currentUpgradeMode];

	[self shipAction:self];

	[self doBuyFeedback:YES];
}

- (void)updateWeaponsSheet
{
	//NSLog(@"updateWeaponsSheet");
	NSArray *buttons = $array(upgradeBombButton, upgradeMinesButton, upgradeWaveButton, upgradeNitroButton, upgradeDamageButton);



	for (int i = 0; i < 5; i++)
	{
		if ($defaulti([kWeaponUpgradesKeyNames objectAtIndex:i]))
		{
#ifdef TARGET_OS_MAC
            [[buttons objectAtIndex:i] setTitle:NSLocalizedString(@"Installed", nil)];
#else //if defined(__COCOTRON__)
			[[buttons objectAtIndex:i] setHidden:YES]; // TODO: we have a unreported gnustep problem here, the binding should take care of it
#endif
		}
#ifdef TARGET_OS_MAC
        else
        {
            [[buttons objectAtIndex:i] setTitle:[[buttons objectAtIndex:i] alternateTitle]];
        }
#endif
	}


	//NSLog(@"updateWeaponsSheet OUT");
}

- (IBAction)upgradeWeaponsAction:(id)sender
{
	//NSLog(@"upgradeWeaponsAction");

	[self updateWeaponsSheet];
	[NSApp beginSheet:upgradeWeaponSheet modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

- (IBAction)upgradeWeaponsFinishedAction:(id)sender
{
	//NSLog(@"upgradeWeaponsFinishedAction");
	[NSApp endSheet:upgradeWeaponSheet];
	[upgradeWeaponSheet orderOut:self];
}

- (IBAction)upgradeWeaponAction:(id)sender
{
	//NSLog(@"upgradeWeaponAction");
	int money = $defaulti(kAvailableCashKey);
	int cost = [[kWeaponUpgradesCosts objectAtIndex:[sender tag] - 1] floatValue];


	if (cost > money)
	{
		[self doBuyFeedback:NO];

		return;
	}

	$setdefaulti(1, [kWeaponUpgradesKeyNames objectAtIndex:[sender tag] - 1]);
	$setdefaulti(money - cost, kAvailableCashKey);

	$defaultsync;

#ifdef __COCOTRON__
    [cashLabel setIntValue:$defaulti(kAvailableCashKey)];
#endif
	[self updateCarreerInformation];
	[self updateWeaponsSheet];

	[self doBuyFeedback:YES];
}

#pragma mark CONTROLS methods


- (IBAction)configureControlsAction:(id)sender
{
	//NSLog(@"configureControlsAction");

	[controlWorkaroundDate release];
	controlWorkaroundDate = [[NSDate date] copy];

#ifdef SDL    
    [self configureControlsDevivePopupChangedAction:self];
#endif
	[NSApp beginSheet:configureControlsSheet modalForWindow:window modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}

#ifdef SDL
- (IBAction)configureControlsDevivePopupChangedAction:(id)sender // TODO: we have a unreported gnustep problem here with multiple clicks on the button
{
   // NSLog(@"configureControlsDevivePopupChangedAction");
    
    if(SDL_Init(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK) < 0)
        fatal("Error: video initialization failed: %s\n", SDL_GetError());
    
    NSArray *keyNames = KEYS

    
    { // setup saved keys SDL
        int ind = [player1InputDevicePopup indexOfSelectedItem];

        for (NSView *view in [[player1Box contentView] subviews])
        {
     
            if ([view isKindOfClass:[NSButton class]] && [view tag] <= kKeyCount)
            {
                NSString *name;
                
                if (ind)
                    name = [[HIDSupport sharedInstance] nameOfItem:[view tag]-1];
                else
                    name = [NSString stringWithUTF8String:SDL_GetKeyName((SDLKey)($defaulti([keyNames objectAtIndex:[view tag]-1])))];
   
                if (!name)
                    name = @"";
                
                [(NSButton *)view setTitle:name];
            }
        }  
    }
        
    { // setup saved keys SDL
        int ind = [player2InputDevicePopup indexOfSelectedItem];
        
        for (NSView *view in [[player2Box contentView] subviews])
        {
            
            if ([view isKindOfClass:[NSButton class]] && [view tag] <= kKeyCount * 2)
            {
                NSString *name;
                
                if (ind)
                    name = [[HIDSupport sharedInstance] nameOfItem:[view tag]-1];
                else
                    name = [NSString stringWithUTF8String:SDL_GetKeyName((SDLKey)($defaulti([keyNames objectAtIndex:[view tag]-1])))];
                
                if (!name)
                    name = @"";

                [(NSButton *)view setTitle:name];
            }
        }  
    }
    
    SDL_Quit();
}
#endif

- (IBAction)configureControlsHelpAction:(id)sender
{
#ifndef __COCOTRON__
	NSString *toolTip = [sender toolTip];
#else
    NSString *toolTip = @"\t\"Invert\": Invert the input values from the device - this is needed for many \"pedals\" and some \"analog\" sticks. Select this if the ship accelerates although you do nothing, and decelerates although you are pressing accelerate.\n\n\t\"Is analog Stick\": Select this if you are mapping accelerate to an analog stick and want the resting position to be \"no acceleration\" instead of 50% acceleration. Else you would need to press the stick down for no acceleration.";
#endif

#ifndef __COCOTRON__
	NSHelpManager *helpManager = [NSHelpManager sharedHelpManager];
	[helpManager                            setContextHelp:[[[NSAttributedString alloc]
			initWithString:toolTip] autorelease] forObject:sender];
	[helpManager showContextHelpForObject:sender locationHint:[NSEvent mouseLocation]];
	[helpManager removeContextHelpForObject:sender];

#else
    NSRunAlertPanel(@"CoreBreach", toolTip, NSLocalizedString(@"OK", nil), nil, nil);
#endif
}

- (IBAction)configureControlsFinishedAction:(id)sender
{
	// NSLog(@"configureControlsFinishedAction");

	int ind1 = [player1InputDevicePopup indexOfSelectedItem];
	if (ind1)
	{
		NSDictionary *dev1 = [[[HIDSupport sharedInstance] hidDevices] objectAtIndex:ind1 - 1];
		$setdefault([dev1 objectForKey:@"name"], kPlayer1InputDeviceNameKey);
	}
	else
	{
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:kPlayer1InputDeviceNameKey];
		[[HIDSupport sharedInstance] clearItem:0];
		[[HIDSupport sharedInstance] clearItem:1];
		[[HIDSupport sharedInstance] clearItem:2];
		[[HIDSupport sharedInstance] clearItem:3];
		[[HIDSupport sharedInstance] clearItem:4];
		[[HIDSupport sharedInstance] clearItem:5];
	}

	int ind2 = [player2InputDevicePopup indexOfSelectedItem];
	if (ind2)
	{
		NSDictionary *dev2 = [[[HIDSupport sharedInstance] hidDevices] objectAtIndex:ind2 - 1];
		$setdefault([dev2 objectForKey:@"name"], kPlayer2InputDeviceNameKey);
	}
	else
	{
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:kPlayer2InputDeviceNameKey];
		[[HIDSupport sharedInstance] clearItem:6];
		[[HIDSupport sharedInstance] clearItem:7];
		[[HIDSupport sharedInstance] clearItem:8];
		[[HIDSupport sharedInstance] clearItem:9];
		[[HIDSupport sharedInstance] clearItem:10];
		[[HIDSupport sharedInstance] clearItem:11];
	}

	[[HIDSupport sharedInstance] saveConfiguration:self];

	[NSApp endSheet:configureControlsSheet];
	[configureControlsSheet orderOut:self];
	$defaultsync;
}

- (IBAction)configureHIDControl:(id)sender
{
	if ([[NSDate date] timeIntervalSinceDate:controlWorkaroundDate] < 0.5)
	{
		// NSLog(@"configureHIDControl DONTENTER");

		return;
	}
	else
	{
		// NSLog(@"configureHIDControl enter");

		[controlWorkaroundDate release];
		controlWorkaroundDate = [[NSDate distantFuture] copy];
	}

#ifdef SDL
    int ind = [([sender tag] - 1 > (kKeyCount-1) ? player2InputDevicePopup : player1InputDevicePopup) indexOfSelectedItem];
    int times = 0;
    SDL_Event event;
    NSArray *keyNames = KEYS;

    SDL_Init(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK);

    SDL_SetVideoMode(4, 4, 0, SDL_NOFRAME);

    if (ind && [[HIDSupport sharedInstance] hidDevices])
    {
        NSDictionary *dev = [[[HIDSupport sharedInstance] hidDevices] objectAtIndex:ind-1];
        
        NSString *elem = [[HIDSupport sharedInstance] configItem:[sender tag]-1 forDevice:dev];
        
        [sender setTitle:elem];
    }
    else
    {
        while(times < 100)
        {
            //NSLog(@"entering endless loop");

            while (SDL_PollEvent(&event))
            {
                switch( event.type )
                {
                    //NSLog(@"got event %i", event.type);
                    case SDL_KEYDOWN:
                    {
                        $setdefaulti((int)event.key.keysym.sym, [keyNames objectAtIndex:[sender tag]-1]);

                        NSString *name = [NSString stringWithUTF8String:SDL_GetKeyName(event.key.keysym.sym)];


                        [(NSButton *)sender setTitle:name];

                        times = 100;
                        break;
                    }
                    default:
                        break;
                }
            }
            SDL_Delay(50);
        }
    }
    SDL_Quit();
#else
	int ind = [([sender tag] > (kKeyCount - 1) ? player2InputDevicePopup : player1InputDevicePopup) indexOfSelectedItem];
	NSDictionary *dev = [[[HIDSupport sharedInstance] hidDevices] objectAtIndex:ind - 1];

	NSString *elem = [[HIDSupport sharedInstance] configItem:[sender tag] forDevice:dev];

	[sender setTitle:elem];

	{
		for (int i = (([sender tag] < kKeyCount) ? 0 : kKeyCount); i < (([sender tag] < kKeyCount) ? (kKeyCount) : (kKeyCount * 2)); i++)
		{
			if (([sender tag] == i) ||
					(([sender tag] == (([sender tag] < kKeyCount) ? 1 : kKeyCount + 1) ||
							[sender tag] == (([sender tag] < kKeyCount) ? 2 : kKeyCount + 2))
							&& (i == (([sender tag] < kKeyCount) ? 1 : kKeyCount + 1) ||
									i == (([sender tag] < kKeyCount) ? 2 : kKeyCount + 2))))
				continue;
			else
			{
				if ([[HIDSupport sharedInstance] item:[sender tag] identicalToItem:i])
				{
					[[HIDSupport sharedInstance] clearItem:i];

					for (NSView *view in [[(([sender tag] < kKeyCount) ? player1Box : player2Box) contentView] subviews])
					{
						if ([view isKindOfClass:[NSButton class]] && [view tag] < (kKeyCount * 2))
						{
							NSString *name = [[HIDSupport sharedInstance] nameOfItem:[view tag]];
							if (name)
								[(NSButton *) view setTitle:name];
							else
								[(NSButton *) view setTitle:NSLocalizedString(@"Click to record shortcut", nil)];
						}
					}
				}
			}
		}
	}
#endif

	[controlWorkaroundDate release];
	controlWorkaroundDate = [[NSDate date] copy];
	//NSLog(@" configureHIDControl OUT");
}

#pragma mark SHIP/TRACK action methods

- (IBAction)trackAction:(id)sender
{
//#ifdef GNUSTEP // bug #34492
//    if (sender != self)
//        $setdefaulti([sender indexOfSelectedItem], kTrackNumKey);
//    $defaultsync;
//#endif

	uint32_t trackNum = CareerPopupToReal($defaulti(kTrackNumKey));

#ifdef TARGET_OS_MAC
    QTMovie *m = [[QTMovie alloc] initWithURL:[[NSBundle mainBundle] URLForResource:$stringf(@"track%i", trackNum) withExtension:@"m4v"] error:nil];
    [trackMovie setMovie:m];
    [trackMovie setEditable:NO];
    [trackMovie setControllerVisible:NO];
    [trackMovie play:self];
    [m release];
#else
	[trackImage setImage:[NSImage imageNamed:$stringf(@"track%i", trackNum)]];
	[trackImage display];
#endif


	[self updateInternetHighscores:kGameModeCareer forTrackNum:trackNum];

	if (trackNum >= kNumTracks) trackNum -= kNumTracks;
	[trackDif setDoubleValue:[[kTrackDifficulty objectAtIndex:trackNum] doubleValue]];
	[trackLen setDoubleValue:[[kTrackLength objectAtIndex:trackNum] doubleValue]];
	[trackSpe setDoubleValue:[[kTrackSpeed objectAtIndex:trackNum] doubleValue]];

	[objectivesTable reloadData];

	[self updateTrackNew];
}

- (IBAction)trackCustomAction:(id)sender
{
//#ifdef GNUSTEP // bug #34492
//    if (sender != self)
//        $setdefaulti([sender indexOfSelectedItem], kCustomraceTrackNumKey);
//    $defaultsync;
//#endif

	uint32_t trackNum = $defaulti(kCustomraceTrackNumKey);

	NSString *name;
	if (trackNum >= kNumTracks * 2)
	{
		trackNum = [[[trackPopupCustom selectedItem] title] hash];
		name = @"custom_track";
	}
	else
		name = $stringf(@"track%i", trackNum);

#ifdef TARGET_OS_MAC
    QTMovie *m = [[QTMovie alloc] initWithURL:[[NSBundle mainBundle] URLForResource:name withExtension:@"m4v"] error:nil];
    [trackCustomMovie setMovie:m];
    [trackCustomMovie setEditable:NO];
    [trackCustomMovie setControllerVisible:NO];
    [trackCustomMovie play:self];
    [m release];
#else
	[trackCustomImage setImage:[NSImage imageNamed:name]];
	[trackCustomImage display];
#endif

	[self updateInternetHighscores:kGameModeCustomGame forTrackNum:trackNum];


	if (trackNum < kNumTracks * 2)
	{
		if (trackNum >= kNumTracks) trackNum -= kNumTracks;
		[trackCustomDif setDoubleValue:[[kTrackDifficulty objectAtIndex:trackNum] doubleValue]];
		[trackCustomLen setDoubleValue:[[kTrackLength objectAtIndex:trackNum] doubleValue]];
		[trackCustomSpe setDoubleValue:[[kTrackSpeed objectAtIndex:trackNum] doubleValue]];
		$setdefault($numi([[kTrackRounds objectAtIndex:trackNum] intValue] - 1), kCustomraceRoundsNumKey);
	}
	else
	{
		[trackCustomDif setDoubleValue:0];
		[trackCustomLen setDoubleValue:0];
		[trackCustomSpe setDoubleValue:0];
	}

	[self updateTrackNew];
}

- (IBAction)trackTimeattackAction:(id)sender
{
//#ifdef GNUSTEP // bug #34492
//    if (sender != self)
//        $setdefaulti([sender indexOfSelectedItem], kTimeattackTrackNumKey);
//    $defaultsync;
//#endif

	NSString *name;
	uint32_t trackNum = $defaulti(kTimeattackTrackNumKey);
	if (trackNum >= kNumTracks * 2)
	{
		trackNum = [[[trackPopupTimeAttack selectedItem] title] hash];
		name = @"custom_track";
	}
	else
		name = $stringf(@"track%i", trackNum);

#ifdef TARGET_OS_MAC
    QTMovie *m = [[QTMovie alloc] initWithURL:[[NSBundle mainBundle] URLForResource:name withExtension:@"m4v"] error:nil];
    [trackTimeattackMovie setMovie:m];
    [trackTimeattackMovie setEditable:NO];
    [trackTimeattackMovie setControllerVisible:NO];
    [trackTimeattackMovie play:self];
    [m release];
#else
	[trackTimeattackImage setImage:[NSImage imageNamed:name]];
	[trackTimeattackImage display];
#endif


	[self updateInternetHighscores:kGameModeTimeAttack forTrackNum:trackNum];


	if (trackNum < kNumTracks * 2)
	{
		if (trackNum >= kNumTracks) trackNum -= kNumTracks;
		[trackTimeattackDif setDoubleValue:[[kTrackDifficulty objectAtIndex:trackNum] doubleValue]];
		[trackTimeattackLen setDoubleValue:[[kTrackLength objectAtIndex:trackNum] doubleValue]];
		[trackTimeattackSpe setDoubleValue:[[kTrackSpeed objectAtIndex:trackNum] doubleValue]];
	}
	else
	{
		[trackTimeattackDif setDoubleValue:0];
		[trackTimeattackLen setDoubleValue:0];
		[trackTimeattackSpe setDoubleValue:0];
	}

	[self updateTrackNew];
}

- (IBAction)trackMultiplayerAction:(id)sender
{
//#ifdef GNUSTEP // bug #34492
//    if (sender != self)
//        $setdefaulti([sender indexOfSelectedItem], kMultiplayerTrackNumKey);
//    $defaultsync;
//#endif

	NSString *name;
	int trackNum = $defaulti(kMultiplayerTrackNumKey);
	if (trackNum >= kNumTracks * 2)
	{
		trackNum = [[[trackPopupTimeAttack selectedItem] title] hash];
		name = @"custom_track";
	}
	else
		name = $stringf(@"track%i", trackNum);

#ifdef TARGET_OS_MAC
    QTMovie *m = [[QTMovie alloc] initWithURL:[[NSBundle mainBundle] URLForResource:name withExtension:@"m4v"] error:nil];
    [trackMultiplayerMovie setMovie:m];
    [trackMultiplayerMovie setEditable:NO];
    [trackMultiplayerMovie setControllerVisible:NO];
    [trackMultiplayerMovie play:self];
    [m release];
#else
	[trackMultiplayerImage setImage:[NSImage imageNamed:name]];
	[trackMultiplayerImage display];
#endif



	if (trackNum < kNumTracks * 2)
	{
		if (trackNum >= kNumTracks) trackNum -= kNumTracks;
		[trackMultiplayerDif setDoubleValue:[[kTrackDifficulty objectAtIndex:trackNum] doubleValue]];
		[trackMultiplayerLen setDoubleValue:[[kTrackLength objectAtIndex:trackNum] doubleValue]];
		[trackMultiplayerSpe setDoubleValue:[[kTrackSpeed objectAtIndex:trackNum] doubleValue]];
	}
	else
	{
		[trackMultiplayerDif setDoubleValue:0];
		[trackMultiplayerLen setDoubleValue:0];
		[trackMultiplayerSpe setDoubleValue:0];
	}

	[self updateTrackNew];
}

- (IBAction)shipAction:(id)sender
{
//#ifdef GNUSTEP // bug #34492
//    if (sender != self)
//        $setdefaulti([sender indexOfSelectedItem], kShipNumKey);
//    $defaultsync;
//#endif

	int shipNum = $defaulti(kShipNumKey);


#ifdef TARGET_OS_MAC
    QTMovie *m = [[QTMovie alloc] initWithURL:[[NSBundle mainBundle] URLForResource:$stringf(@"ship%i", shipNum) withExtension:@"m4v"] error:nil];
    [shipMovie setMovie:m];
    [shipMovie setEditable:NO];
    [shipMovie setControllerVisible:NO];
    [shipMovie play:self];
    [m release];
#else
	[shipImage setImage:[NSImage imageNamed:$stringf(@"ship%i", shipNum)]];
	[shipImage display];
#endif



	[shipHan setDoubleValue:[UpgradeHandler currentUpgradedValue:kHandling forShip:shipNum]];
	[shipAcc setDoubleValue:[UpgradeHandler currentUpgradedValue:kAcceleration forShip:shipNum]];
	[shipTop setDoubleValue:[UpgradeHandler currentUpgradedValue:kTopSpeed forShip:shipNum]];

	[self updateCarreerInformation];

	[self updateShipNew];
}

- (IBAction)shipCustomAction:(id)sender
{
//#ifdef GNUSTEP // bug #34492
//    if (sender != self)
//        $setdefaulti([sender indexOfSelectedItem], kCustomraceShipNumKey);
//    $defaultsync;
//#endif

	int shipNum = $defaulti(kCustomraceShipNumKey);


#ifdef TARGET_OS_MAC
    QTMovie *m = [[QTMovie alloc] initWithURL:[[NSBundle mainBundle] URLForResource:$stringf(@"ship%i", shipNum) withExtension:@"m4v"] error:nil];
    [shipCustomMovie setMovie:m];
    [shipCustomMovie setEditable:NO];
    [shipCustomMovie setControllerVisible:NO];
    [shipCustomMovie play:self];
    [m release];
#else
	[shipCustomImage setImage:[NSImage imageNamed:$stringf(@"ship%i", shipNum)]];
	[shipCustomImage display];
#endif

	[shipCustomHan setDoubleValue:[[kShipHandling objectAtIndex:shipNum] doubleValue]];
	[shipCustomAcc setDoubleValue:[[kShipAcceleration objectAtIndex:shipNum] doubleValue]];
	[shipCustomTop setDoubleValue:[[kShipTopspeed objectAtIndex:shipNum] doubleValue]];

	[self updateShipNew];
}

- (IBAction)shipTimeattackAction:(id)sender
{
//#ifdef GNUSTEP // bug #34492
//    if (sender != self)
//        $setdefaulti([sender indexOfSelectedItem], kTimeattackShipNumKey);
//    $defaultsync;
//#endif

	int shipNum = $defaulti(kTimeattackShipNumKey);

#ifdef TARGET_OS_MAC
    QTMovie *m = [[QTMovie alloc] initWithURL:[[NSBundle mainBundle] URLForResource:$stringf(@"ship%i", shipNum) withExtension:@"m4v"] error:nil];
    [shipTimeattackMovie setMovie:m];
    [shipTimeattackMovie setEditable:NO];
    [shipTimeattackMovie setControllerVisible:NO];
    [shipTimeattackMovie play:self];
    [m release];
#else
	[shipTimeattackImage setImage:[NSImage imageNamed:$stringf(@"ship%i", shipNum)]];
	[shipTimeattackImage display];
#endif

	[shipTimeattackHan setDoubleValue:[[kShipHandling objectAtIndex:shipNum] doubleValue]];
	[shipTimeattackAcc setDoubleValue:[[kShipAcceleration objectAtIndex:shipNum] doubleValue]];
	[shipTimeattackTop setDoubleValue:[[kShipTopspeed objectAtIndex:shipNum] doubleValue]];

	[self updateShipNew];
}

- (IBAction)shipMultiplayerAction:(id)sender
{
//#ifdef GNUSTEP // bug #34492
//    if (sender != self)
//        $setdefaulti([sender indexOfSelectedItem], kMultiplayerShipNumKey);
//    $defaultsync;
//#endif

	int shipNum = $defaulti(kMultiplayerShipNumKey);
#ifdef TARGET_OS_MAC
    QTMovie *m = [[QTMovie alloc] initWithURL:[[NSBundle mainBundle] URLForResource:$stringf(@"ship%i", shipNum) withExtension:@"m4v"] error:nil];
    [shipMultiplayerMovie setMovie:m];
    [shipMultiplayerMovie setEditable:NO];
    [shipMultiplayerMovie setControllerVisible:NO];
    [shipMultiplayerMovie play:self];
    [m release];
#else
	[shipMultiplayerImage setImage:[NSImage imageNamed:$stringf(@"ship%i", shipNum)]];
	[shipMultiplayerImage display];
#endif
	[shipMultiplayerHan setDoubleValue:[[kShipHandling objectAtIndex:shipNum] doubleValue]];
	[shipMultiplayerAcc setDoubleValue:[[kShipAcceleration objectAtIndex:shipNum] doubleValue]];
	[shipMultiplayerTop setDoubleValue:[[kShipTopspeed objectAtIndex:shipNum] doubleValue]];

	[self updateShipNew];
}

- (IBAction)shipMultiplayer2Action:(id)sender
{
//#ifdef GNUSTEP // bug #34492
//    if (sender != self)
//        $setdefaulti([sender indexOfSelectedItem], kMultiplayerShip2NumKey);
//    $defaultsync;
//#endif

	int shipNum = $defaulti(kMultiplayerShip2NumKey);
#ifdef TARGET_OS_MAC
    QTMovie *m = [[QTMovie alloc] initWithURL:[[NSBundle mainBundle] URLForResource:$stringf(@"ship%i", shipNum) withExtension:@"m4v"] error:nil];
    [shipMultiplayer2Movie setMovie:m];
    [shipMultiplayer2Movie setEditable:NO];
    [shipMultiplayer2Movie setControllerVisible:NO];
    [shipMultiplayer2Movie play:self];
    [m release];
#else
	[shipMultiplayer2Image setImage:[NSImage imageNamed:$stringf(@"ship%i", shipNum)]];
	[shipMultiplayer2Image display];
#endif

	[shipMultiplayer2Han setDoubleValue:[[kShipHandling objectAtIndex:shipNum] doubleValue]];
	[shipMultiplayer2Acc setDoubleValue:[[kShipAcceleration objectAtIndex:shipNum] doubleValue]];
	[shipMultiplayer2Top setDoubleValue:[[kShipTopspeed objectAtIndex:shipNum] doubleValue]];

	[self updateShipNew];
}

#pragma mark NSTabView delegate methods

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
#ifdef __COCOTRON__
    $setdefaulti([bigTabView indexOfTabViewItem:[bigTabView selectedTabViewItem]], kGameModeKey);
    $defaultsync;
#endif

	[self updateShipNew];
	[self updateTrackNew];
}

#pragma mark NSTableViewDataSource protocol methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (aTableView == objectivesTable)
	{
		return [kObjectivesEveryTrack count] + [[kObjectivesPerTrack objectAtIndex:CareerPopupToReal($defaulti(kTrackNumKey))] count];
	}
	else if (aTableView == customInternetHighscoresTable)
	{
		return [customHighscores count];
	}
	else if (aTableView == timeattackInternetHighscoresTable)
	{
		return [timeattackHighscores count];
	}
	else if (aTableView == careerInternetHighscoresTable)
	{
		return [carreerHighscores count];
	}
	else if (aTableView == customLocalHighscoresTable)
	{
		uint32_t tn = $defaulti(kCustomraceTrackNumKey);


		if (tn >= kNumTracks * 4)
			tn = [[[trackPopupCustom selectedItem] title] hash];

		return [$default($stringf(@"HighscoresCustomTrack%i", tn)) count];
	}
	else if (aTableView == timeattackLocalHighscoresTable)
	{
		uint32_t tn = $defaulti(kTimeattackTrackNumKey);

		if (tn >= kNumTracks * 4)
			tn = [[[trackPopupTimeAttack selectedItem] title] hash];

		return [$default($stringf(@"HighscoresTimeAttackTrack%i", tn)) count];
	}
	else if (aTableView == careerLocalHighscoresTable)
	{
		uint32_t tn = CareerPopupToReal($defaulti(kTrackNumKey));

		return [$default($stringf(@"HighscoresCareerTrack%i", tn)) count];
	}
	else if (aTableView == songListTable)
	{
		//NSLog(@"returning %i",   (int)[kMusicNames count]);
		return [kMusicNames count];
	}
	else
	{
		return 0;
	}
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSString *key = [[[aTableColumn headerCell] stringValue] lowercaseString];
	NSString *value = nil;

	if (aTableView == songListTable)
	{
		if ([key isEqualToString:@"state"] || [key isEqualToString:@"activa"])
		{
			NSString *song = [kMusicNames objectAtIndex:rowIndex];
			NSUInteger songIndex = [$default(kMusicNamesKey) indexOfObject:song];

			// NSLog(@"returning s %i",  songIndex != NSNotFound);

			return $numi(songIndex != NSNotFound);
		}
		else
		{
			// NSLog(@"returning n %@",   [kMusicNames objectAtIndex:rowIndex]);

			return [kMusicNames objectAtIndex:rowIndex];
		}
	}
	else if (aTableView == objectivesTable)
	{
		return $numi(0);
	}
	else if (aTableView == customInternetHighscoresTable)
		value = [[customHighscores objectAtIndex:rowIndex] valueForKey:key];
	else if (aTableView == timeattackInternetHighscoresTable)
		value = [[timeattackHighscores objectAtIndex:rowIndex] valueForKey:key];
	else if (aTableView == careerInternetHighscoresTable)
		value = [[carreerHighscores objectAtIndex:rowIndex] valueForKey:key];
	else
	{
		if ([key isEqualToString:@"rank"])
			return $stringf(@"%li", rowIndex + 1);
		else if (aTableView == customLocalHighscoresTable)
		{
			uint32_t tn = $defaulti(kCustomraceTrackNumKey);


			if (tn >= kNumTracks * 4)
				tn = [[[trackPopupCustom selectedItem] title] hash];

			NSString *defaults = $stringf(@"HighscoresCustomTrack%i", tn);
			NSArray *hs = $default(defaults);
			if ([hs count] > (NSUInteger) rowIndex)
				value = [[hs objectAtIndex:rowIndex] valueForKey:key];
		}
		else if (aTableView == timeattackLocalHighscoresTable)
		{
			uint32_t tn = $defaulti(kTimeattackTrackNumKey);

			if (tn >= kNumTracks * 4)
				tn = [[[trackPopupTimeAttack selectedItem] title] hash];

			NSString *defaults = $stringf(@"HighscoresTimeAttackTrack%i", tn);
			NSArray *hs = $default(defaults);
			if ([hs count] > (NSUInteger) rowIndex)
				value = [[hs objectAtIndex:rowIndex] valueForKey:key];
		}
		else if (aTableView == careerLocalHighscoresTable)
		{
			uint32_t tn = CareerPopupToReal($defaulti(kTrackNumKey));

			NSString *defaults = $stringf(@"HighscoresCareerTrack%i", tn);
			NSArray *hs = $default(defaults);
			if ([hs count] > (NSUInteger) rowIndex)
				value = [[hs objectAtIndex:rowIndex] valueForKey:key];
		}
	}

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
}

#pragma mark NSTableViewDelegate delegate methods

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView
{
	if (aTableView == objectivesTable)
		return NO;
	else
		return YES;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)TC row:(int)rowIndex
{
	if (aTableView == objectivesTable)
	{
		NSMutableArray *obj = [NSMutableArray arrayWithArray:[kObjectivesPerTrack objectAtIndex:CareerPopupToReal($defaulti(kTrackNumKey))]];
		[obj addObjectsFromArray:kObjectivesEveryTrack];
		NSDictionary *dict = [obj objectAtIndex:rowIndex];
		[aCell setTitle:$stringf(NSLocalizedString(@"%@\nto %@", nil), [dict valueForKey:kObjectiveKey], [dict valueForKey:kRewardKey])];
#ifdef TARGET_OS_MAC
		[aCell setDrawsBackground:NO];
#endif
		NSImage *image = [NSImage imageNamed:[dict valueForKey:kIconKey]];
		[aCell setImage:image];
	}
	else if ([[self tableView:aTableView objectValueForTableColumn:TC row:rowIndex] isEqualToString:$default(kNicknameKey)])
	{
#ifndef __COCOTRON__
		[aCell setDrawsBackground:YES];
#endif
		[(NSTextFieldCell *) aCell setBackgroundColor:[NSColor colorWithCalibratedRed:0.7 green:0.7 blue:1 alpha:1.0]];
	}
	else
	{
#ifdef TARGET_OS_MAC
		[aCell setDrawsBackground:NO];
#endif
		[(NSTextFieldCell *) aCell setBackgroundColor:[NSColor whiteColor]];
	}
}

#pragma mark SRRecorderControl delegate methods

#ifdef TARGET_OS_MAC
- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason
{
	NSArray *keyNames = KEYS

	for (NSString *key in keyNames)
		if ([$default(key) intValue] == keyCode)
			return YES;

	return NO;
}

- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
	NSArray *keyNames = KEYS

	$setdefault($numi(newKeyCombo.code), [keyNames objectAtIndex:[aRecorder tag]-1]);

	 $defaultsync;
}
#endif

#pragma mark NSWindow delegate methods

- (void)windowWillClose:(NSNotification *)notification
{
	if (!launching)
		[NSApp terminate:self];
}

#pragma mark WebView delegate methods
#ifdef TARGET_OS_MAC
- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id < WebPolicyDecisionListener >)listener
{
    //NSLog(@"wer %@", [[request URL] description]);
    NSString *host = [[request URL] host];
    if (host && [[[request URL] path] rangeOfString:@"bookmark.php"].location != NSNotFound)
    {
   //     NSLog(@"open");

        [[NSWorkspace sharedWorkspace] openURL:[request URL]];
        [[[addThisWebview mainFrame] frameView] setAllowsScrolling:NO];

    } else {
        [listener use];
    }
}

- (void)webView:(WebView *)webView decidePolicyForNewWindowAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request newFrameName:(NSString *)frameName decisionListener:(id < WebPolicyDecisionListener >)listener
{
 //   NSLog(@"blq11242");
	[[NSWorkspace sharedWorkspace] openURL:[request URL]];
}

//- (void)webView:(WebView *)webView decidePolicyForMIMEType:(NSString *)type request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id < WebPolicyDecisionListener >)listener
//{
//    NSLog(@"blq142");
//}
//- (void)webView:(WebView *)webView unableToImplementPolicyWithError:(NSError *)error frame:(WebFrame *)frame
//{
//    NSLog(@"blq12");
//}

- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request
{
    //NSLog(@"create %@", [[request URL] description]);

   	[[NSWorkspace sharedWorkspace] openURL:[request URL]];

    return sender;
}

- (WebView *)webView:(WebView *)sender createWebViewModalDialogWithRequest:(NSURLRequest *)request
{
    //NSLog(@"modal %@", [[request URL] description]);

    [[NSWorkspace sharedWorkspace] openURL:[request URL]];

    return sender;
}

- (BOOL)webViewIsResizable:(WebView *)sender
{
    return NO;
}

- (void)webView:(WebView *)sender setResizable:(BOOL)resizable {}
- (void)webView:(WebView *)sender setFrame:(NSRect)frame {}

#endif
@end

@implementation PercentageIndicator

- (void)startAnimation:(id)sender
{}

- (void)stopAnimation:(id)sender
{}

- (void)animate:(id)sender
{}
@end