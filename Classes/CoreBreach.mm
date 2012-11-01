//
//  CoreBreach.mm
//  CoreBreach
//
//  Created by CoreCode on 13.09.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "CoreBreach.h"
#import "Core3D.h"
#import "HostInformation.h"
#import "Game.h"


@implementation CoreBreach

+ (void)initialize
{
#ifdef DEBUG
#warning THIS_IS_A_DEBUG_BUILD
#endif
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];


	for (long i = 0; i < kNumTracks * 4; i++)
	{
		[defaultValues setObject:$numi(0) forKey:$stringf(kTrackISeenKey, i)];

		[defaultValues setObject:$numi(999) forKey:$stringf(@"FastestTimeAttackTrack%liTime", i)];
		[defaultValues setObject:[NSData data] forKey:$stringf(@"FastestTimeAttackTrack%liData", i)];

		[defaultValues setObject:$earray forKey:$stringf(@"HighscoresTimeAttackTrack%li", i)];
		[defaultValues setObject:$earray forKey:$stringf(@"HighscoresCustomTrack%li", i)];
		[defaultValues setObject:$earray forKey:$stringf(@"HighscoresCareerTrack%li", i)];
	}
	for (long i = 0; i < kNumShips; i++)
		[defaultValues setObject:$numi(0) forKey:$stringf(kShipISeenKey, i)];

#ifndef TARGET_OS_IPHONE
#ifdef SDL
    [defaultValues setObject:$numi(SDLK_UP) forKey:@"Player1AccelerateKey"];
	[defaultValues setObject:$numi(SDLK_LEFT) forKey:@"Player1SteerLeftKey"];
	[defaultValues setObject:$numi(SDLK_RIGHT) forKey:@"Player1SteerRightKey"];
	[defaultValues setObject:$numi(SDLK_DOWN) forKey:@"Player1LookBackKey"];
	[defaultValues setObject:$numi(SDLK_SPACE) forKey:@"Player1FireWeaponKey"];
	[defaultValues setObject:$numi(SDLK_TAB) forKey:@"Player1ChangeCameraKey"];

	[defaultValues setObject:$numi(SDLK_w) forKey:@"Player2AccelerateKey"];
	[defaultValues setObject:$numi(SDLK_a) forKey:@"Player2SteerLeftKey"];
	[defaultValues setObject:$numi(SDLK_d) forKey:@"Player2SteerRightKey"];
	[defaultValues setObject:$numi(SDLK_s) forKey:@"Player2LookBackKey"];
	[defaultValues setObject:$numi(SDLK_q) forKey:@"Player2FireWeaponKey"];
	[defaultValues setObject:$numi(SDLK_e) forKey:@"Player2ChangeCameraKey"];
#else
	[defaultValues setObject:$numi(kVK_UpArrow) forKey:@"Player1AccelerateKey"];
	[defaultValues setObject:$numi(kVK_LeftArrow) forKey:@"Player1SteerLeftKey"];
	[defaultValues setObject:$numi(kVK_RightArrow) forKey:@"Player1SteerRightKey"];
	[defaultValues setObject:$numi(kVK_DownArrow) forKey:@"Player1LookBackKey"];
	[defaultValues setObject:$numi(kVK_Space) forKey:@"Player1FireWeaponKey"];
	[defaultValues setObject:$numi(kVK_Tab) forKey:@"Player1ChangeCameraKey"];

	[defaultValues setObject:$numi(kVK_ANSI_W) forKey:@"Player2AccelerateKey"];
	[defaultValues setObject:$numi(kVK_ANSI_A) forKey:@"Player2SteerLeftKey"];
	[defaultValues setObject:$numi(kVK_ANSI_D) forKey:@"Player2SteerRightKey"];
	[defaultValues setObject:$numi(kVK_ANSI_S) forKey:@"Player2LookBackKey"];
	[defaultValues setObject:$numi(kVK_ANSI_Q) forKey:@"Player2FireWeaponKey"];
	[defaultValues setObject:$numi(kVK_ANSI_E) forKey:@"Player2ChangeCameraKey"];
#endif

 	[defaultValues setObject:[NSDate dateWithString:@"2011-01-01 00:00:00 +0000"] forKey:@"LatestNewsSeen"];
#endif

	[defaultValues setObject:$numi(1) forKey:kInternetHighscoresEnabledKey];

	[defaultValues setObject:$numi(1) forKey:kInternetNewsEnabledKey];

	[defaultValues setObject:$numi(0) forKey:@"lionwarning"];

	[defaultValues setObject:@"EvilOpponent" forKey:kSecondNicknameKey];

#ifdef TARGET_OS_IPHONE
	CFUUIDRef uuidRef = CFUUIDCreate(NULL);
	CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
	NSString *uuidStr = (NSString *) uuidStringRef;
	NSString *nick = $stringf(@"%@_%@", [[[[UIDevice currentDevice] name] componentsSeparatedByString:@"'"] objectAtIndex:0], MAXLENGTH(uuidStr, 4));
	nick = [nick stringByReplacingOccurrencesOfString:@" " withString:@"_"];

	[defaultValues setObject:nick forKey:kNicknameKey];

	CFRelease(uuidStringRef);
	CFRelease(uuidRef);
#else
    NSString *nick = $stringf(@"%@ %@", NSFullUserName(), [HostInformation macAddress]);
	nick = [nick stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	[defaultValues setObject:nick forKey:kNicknameKey];
#endif
	// 	[defaultValues setObject:$numi(0) forKey:@"hidwarned"];

	[defaultValues setObject:$num(0.40) forKey:kTiltCameraKey];

#ifdef TARGET_OS_IPHONE
	[defaultValues setObject:$num(0.45) forKey:kIOSAccelSensitivity];
	[defaultValues setObject:$num(0.5) forKey:kIOSTouchfieldWidth];
	[defaultValues setObject:$numi(1) forKey:kIOSControlMethod];
#endif

#ifdef TARGET_OS_IPHONE
	globalInfo.gpuSuckynessClass = 3;
	[defaultValues setObject:$numi(1) forKey:kTextureQualityKey];
#elif defined(TARGET_OS_MAC)
    if (globalInfo.VRAM / (1024 * 1024) < 256)
        [defaultValues setObject:$numi(1) forKey:kTextureQualityKey];
    else
        [defaultValues setObject:$numi(0) forKey:kTextureQualityKey];
#else
    [defaultValues setObject:$numi(0) forKey:kTextureQualityKey];
#endif

	[defaultValues setObject:$numi(1) forKey:kFullscreenKey];

	if (!globalInfo.gpuSuckynessClass && (globalInfo.gpuVendor != kVendorMesa))
		[defaultValues setObject:$numi(2) forKey:kFsaaKey];
	else
		[defaultValues setObject:$numi(0) forKey:kFsaaKey];

	if (!globalInfo.gpuSuckynessClass)
		[defaultValues setObject:$numi(0) forKey:kParticleQualityKey];
	else if (globalInfo.gpuSuckynessClass == 1)
		[defaultValues setObject:$numi(1) forKey:kParticleQualityKey];
	else
		[defaultValues setObject:$numi(2) forKey:kParticleQualityKey];

#ifdef TARGET_OS_IPHONE
	[defaultValues setObject:$numi(0) forKey:kShadowsEnabledKey];
#else
    [defaultValues setObject:$numi(1) forKey:kShadowsEnabledKey];
#endif

	if (!globalInfo.gpuSuckynessClass)
		[defaultValues setObject:$numi(2) forKey:kShadowSizeKey];
	else if (globalInfo.gpuSuckynessClass == 1)
		[defaultValues setObject:$numi(1) forKey:kShadowSizeKey];
	else
		[defaultValues setObject:$numi(0) forKey:kShadowSizeKey];

	if (!globalInfo.gpuSuckynessClass)
		[defaultValues setObject:$numi(3) forKey:kShadowFilteringKey];
	else if (globalInfo.gpuSuckynessClass == 1)
		[defaultValues setObject:$numi(2) forKey:kShadowFilteringKey];
	else
		[defaultValues setObject:$numi(1) forKey:kShadowFilteringKey];


#ifdef TARGET_OS_IPHONE
	[defaultValues setObject:$numi(2) forKey:kModelQualityKey];
#else
    [defaultValues setObject:$numi(1) forKey:kModelQualityKey];
#endif

	if (!globalInfo.gpuSuckynessClass)
		[defaultValues setObject:$numi(3) forKey:kFilterQualityKey];
	else if (globalInfo.gpuSuckynessClass == 1)
		[defaultValues setObject:$numi(2) forKey:kFilterQualityKey];
	else if (globalInfo.gpuSuckynessClass == 2)
		[defaultValues setObject:$numi(1) forKey:kFilterQualityKey];
	else if (globalInfo.gpuSuckynessClass == 3)
		[defaultValues setObject:$numi(1) forKey:kFilterQualityKey];


	if (!globalInfo.gpuSuckynessClass)
		[defaultValues setObject:$numi(1) forKey:kLightQualityKey];
	else
		[defaultValues setObject:$numi(0) forKey:kLightQualityKey];

	if (globalInfo.gpuSuckynessClass == 3)
		[defaultValues setObject:$numi(1) forKey:kOutlinesKey];
	else
		[defaultValues setObject:$numi(2) forKey:kOutlinesKey];

#ifndef TARGET_OS_IPHONE
    if (globalInfo.gpuSuckynessClass == 3)
        [defaultValues setObject:$numi(1) forKey:kPostProcessingKey];
    else
        [defaultValues setObject:$numi(2) forKey:kPostProcessingKey];
#else
	[defaultValues setObject:$numi(0) forKey:kPostProcessingKey];
#endif

//    if (globalInfo.gpuVendor == kVendorMesaDRIR600)
//        [defaultValues setObject:$numi(0) forKey:kPostProcessingKey];


	[defaultValues setObject:$numi(0) forKey:kFullscreenResolutionFactorKey];

	[defaultValues setObject:$num(0.316) forKey:kSoundShipVolumeKey];
	[defaultValues setObject:$num(0.95) forKey:kSoundEnemyShipsVolumeKey];
	[defaultValues setObject:$numi(1) forKey:kSoundEnabledKey];
	[defaultValues setObject:$num(0.95) forKey:kSoundVolumeKey];

	[defaultValues setObject:$numi(1) forKey:kMusicEnabledKey];
	[defaultValues setObject:$num(0.60) forKey:kMusicVolumeKey];
	[defaultValues setObject:kMusicNames forKey:kMusicNamesKey];

#ifdef DEMO
    [defaultValues setObject:$numi(1) forKey:kGameModeKey];
	[defaultValues setObject:$numi(2) forKey:kCustomraceTrackNumKey];
#else
	[defaultValues setObject:$numi(0) forKey:kGameModeKey];
	[defaultValues setObject:$numi(0) forKey:kCustomraceTrackNumKey];
#endif
	[defaultValues setObject:$numi(0) forKey:kTrackNumKey];

	[defaultValues setObject:$numi(0) forKey:kShipNumKey];
	[defaultValues setObject:$numi(1) forKey:kDifficultyKey];

	[defaultValues setObject:$numi(0) forKey:kAvailableCashKey];


	[defaultValues setObject:$numi(0) forKey:kTimeattackTrackNumKey];
	[defaultValues setObject:$numi(0) forKey:kTimeattackShipNumKey];
	[defaultValues setObject:$numi(0) forKey:kCustomraceShipNumKey];
	[defaultValues setObject:$numi(2) forKey:kCustomraceRoundsNumKey];
	[defaultValues setObject:$numi(7) forKey:kCustomraceEnemiesNumKey];
	[defaultValues setObject:$numi(1) forKey:kCustomraceDifficultyKey];
	[defaultValues setObject:$numi(1) forKey:kCustomraceHighscoreTabSelectionKey];
	[defaultValues setObject:$numi(1) forKey:kTimeattackHighscoreTabSelectionKey];
	[defaultValues setObject:$numi(1) forKey:kCareerHighscoreTabSelectionKey];
	[defaultValues setObject:$numi(0) forKey:kMultiplayerShipNumKey];
	[defaultValues setObject:$numi(0) forKey:kMultiplayerShip2NumKey];
	[defaultValues setObject:$numi(1) forKey:kMultiplayerDifficultyKey];
	[defaultValues setObject:$numi(7) forKey:kMultiplayerEnemiesNumKey];
	[defaultValues setObject:$numi(0) forKey:kMultiplayerTrackNumKey];
	[defaultValues setObject:$numi(2) forKey:kMultiplayerRoundsNumKey];

	[defaultValues setObject:$numi(0) forKey:kFemaleSoundsetKey];
	[defaultValues setObject:$numi(0) forKey:kPlayer1InputDeviceIndexKey];
	[defaultValues setObject:$numi(0) forKey:kPlayer2InputDeviceIndexKey];
	[defaultValues setObject:$numi(0) forKey:kDontPlaySireneKey];
	[defaultValues setObject:$numi(0) forKey:kBombUpgraded];
	[defaultValues setObject:$numi(0) forKey:kMinesUpgraded];
	[defaultValues setObject:$numi(0) forKey:kWaveUpgraded];
	[defaultValues setObject:$numi(0) forKey:kSpeedupUpgraded];
	[defaultValues setObject:$numi(0) forKey:kDamageUpgraded];
	[defaultValues setObject:$numi(0) forKey:kDisplayEnemyNamesKey];
	[defaultValues setObject:$numi(0) forKey:kMultiplayerEnableCorebreachesKey];


#if !defined(__COCOTRON__) && !defined(TARGET_OS_IPHONE)
    [defaultValues setObject:[NSArchiver archivedDataWithRootObject:$color(0,0,0,1)] forKey:kOutlinesColorKey];
#endif

	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

+ (NSDictionary *)fetchResult1
{
	return [[NSDictionary alloc] initWithObjectsAndKeys:game.hud.timeArray, @"timeArray",
	                                                    $numi(game.hud.endSieg), @"endSieg",
	                                                    $numi(game.hud.corebreaches), @"corebreaches",
	                                                    $numi(game.hud.cleanrounds), @"cleanrounds",
	                                                    $numi(game.hud.leadrounds), @"leadrounds",
	                                                    $numi(game.hud.difficulty), @"difficulty", nil];
}

+ (NSDictionary *)fetchResult2
{
	if (game.hud2)
		return [[NSDictionary alloc] initWithObjectsAndKeys:game.hud2.timeArray, @"timeArray",
		                                                    $numi(game.hud2.endSieg), @"endSieg",
		                                                    $numi(game.hud2.corebreaches), @"corebreaches",
		                                                    $numi(game.hud2.cleanrounds), @"cleanrounds",
		                                                    $numi(game.hud2.leadrounds), @"leadrounds",
		                                                    $numi(game.hud2.difficulty), @"difficulty", nil];

	return nil;
}

+ (NSDictionary *)fetchSettings
{
	if (game.trackName)
		return [[NSDictionary alloc] initWithObjectsAndKeys:[[game.trackName copy] autorelease], @"trackName",
		                                                    $numi(game.gameMode), @"gameMode",
		                                                    $numi(game.trackNum), @"trackNum",
		                                                    $numi(game.shipNum), @"shipNum", nil];
	else
		return [[NSDictionary alloc] initWithObjectsAndKeys:
				                             $numi(game.gameMode), @"gameMode",
				                             $numi(game.trackNum), @"trackNum",
				                             $numi(game.shipNum), @"shipNum", nil];
}
@end