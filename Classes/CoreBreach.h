//
//  CoreBreach.h
//  CoreBreach
//
//  Created by CoreCode on 09.08.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

// opensource build doesn't use the full datatset
#define NODATA 1



#ifdef SDL
#import "HIDSupport_SDL.h"
#elif defined(TARGET_OS_MAC)
#import "HIDSupport.h"
#endif

typedef enum
{
	kGameModeCareer = 0,
	kGameModeCustomGame,
	kGameModeTimeAttack,
	kGameModeMultiplayer
} gameModeEnum;

typedef enum
{
	kFlightShowStory = 1,
	kFlightShowMap,
	kFlightShowShip,
	kFlightShowCountdown,
	kFlightGame,
	kFlightEpilogue,
} flightModeEnum;

typedef enum
{
	kAwardCorebreach = 0,
	kAwardCleanRound,
	kAwardLeadRound,
	kAwardObtainHit
} awardEnum;

typedef enum
{
	kLittleHit = 0,
	kMediumHit,
	kBigHit,
	kDeadlyHit,
} hitEnum;

typedef enum
{
	kHandling = 0,
	kTopSpeed,
	kAcceleration,
} shipAttributeEnum;

typedef enum
{
	kAccelKey = 0,
	kSteerLeftKey = 1,
	kSteerRightKey = 2,
	kLookBackKey = 3,
	kFireWeaponKey = 4,
	kChangeCameraKey = 5,
	kKeyCount = 6
} keyOffset;


#define CareerPopupToReal(p) ((p % 2 == 0) ? (p / 2) : (5 + ((p+1) / 2)))
#define CareerRealToPopup(p) ((p <= 5) ? (p * 2) : ((p-6)*2+1))


// user defaults keys
#define kShipIUnlocked @"Ship%iUnlocked"
#define kTrackIUnlocked @"Track%iUnlocked"
#define kPlayer1InputDeviceNameKey @"Player1InputDeviceName"
#define kPlayer2InputDeviceNameKey @"Player2InputDeviceName"
#define kPlayer1InputDeviceIndexKey @"player1InputDeviceIndex"
#define kPlayer2InputDeviceIndexKey @"player2InputDeviceIndex"
#define kPlayer1AccelerateInvertedKey @"player1AccelerateInverted"
#define kPlayer2AccelerateInvertedKey @"player2AccelerateInverted"
#define kPlayer1AccelerateHalfKey @"player1AccelerateHalf"
#define kPlayer2AccelerateHalfKey @"player2AccelerateHalf"
#define kDontPlaySireneKey @"dontplaysirene"
#define kGameModeKey @"gameMode"
#define kTrackNumKey @"trackNum"
#define kShipNumKey @"shipNum"
#define kDifficultyKey @"difficulty"
#define kModelQualityKey @"modelQuality"
#define kParticleQualityKey @"particleQuality"
#define kTimeattackTrackNumKey @"timeattackTrackNum"
#define kTimeattackShipNumKey @"timeattackShipNum"
#define kCustomraceTrackNumKey @"customraceTrackNum"
#define kCustomraceShipNumKey @"customraceShipNum"
#define kCustomraceRoundsNumKey @"customraceRoundsNum"
#define kCustomraceEnemiesNumKey @"customraceEnemiesNum"
#define kCustomraceDifficultyKey @"customraceDifficulty"
#define kCareerHighscoreTabSelectionKey @"careerHighscoreTabSelection"
#define kCustomraceHighscoreTabSelectionKey @"customraceHighscoreTabSelection"
#define kTimeattackHighscoreTabSelectionKey @"timeattackHighscoreTabSelection"
#define kMultiplayerShipNumKey @"multiplayerShipNum"
#define kMultiplayerShip2NumKey @"multiplayerShip2Num"
#define kMultiplayerDifficultyKey @"multiplayerDifficulty"
#define kMultiplayerEnemiesNumKey @"multiplayerEnemiesNum"
#define kMultiplayerTrackNumKey @"multiplayerTrackNum"
#define kMultiplayerRoundsNumKey @"multiplayerRoundsNum"
#define kNicknameKey @"nickname"
#define kSecondNicknameKey @"secondNickname"
#define kInternetHighscoresEnabledKey @"internetHighscoresEnabled"
#define kInternetNewsEnabledKey @"internetNewsEnabled"
#define kPostProcessingKey @"postProcessing"
#define kFemaleSoundsetKey @"femaleSoundset"
#define kSoundShipVolumeKey @"soundShipVolume"
#define kSoundEnemyShipsVolumeKey @"soundEnemyShipsVolumeKey"
#define kDisablemultiturbinesKey @"disablemultiturbines"
#define kLightQualityKey @"lightQuality"
#define kFilterQualityKey @"filterQuality"
#define kAvailableCashKey @"availableCash"
#define kBombUpgraded @"bombUpgraded"
#define kMinesUpgraded @"minesUpgraded"
#define kWaveUpgraded @"waveUpgraded"
#define kSpeedupUpgraded @"speedupUpgraded"
#define kDamageUpgraded @"damageUpgraded"
#define kDisplayEnemyNamesKey @"EnemyNames"
#define kMultiplayerEnableCorebreachesKey @"multiplayerEnableCorebreaches"
#define kMusicNamesKey @"musicNames"
#define kShipITopSpeedUpgrades @"Ship%liTopSpeedUpgrades"
#define kShipIHandlingUpgrades @"Ship%liHandlingUpgrades"
#define kShipIAccelerationUpgrades @"Ship%liAccelerationUpgrades"
#define kShipIAUpgrades @"Ship%li%@Upgrades"
#define kTrackISeenKey @"Track%liSeen"
#define kShipISeenKey @"Ship%liSeen"
#define kStoryISeenKey @"Story%iSeen"
#define kStoryMovieISeenKey @"StoryMovie%iSeen"
#define kCameraModeIKey @"cameraMode%i"
#define kDontPresentTrackKey @"dontpresent"
#define kVideoresolutionKey @"videoresolution"
#define kTiltCameraKey @"tiltCamera"
#define kIOSFireAccel @"fireAccel"
#define kIOSControlMethod @"controlMethod"
#define kIOSAccelSensitivity @"accelSens"
#define kIOSTouchfieldWidth @"touchfieldWidth"

// resource names
#define kOverlayNotificationAwardTexture @"overlay_notification_award"
#define kOverlayNotificationMusicTexture @"overlay_notification_music"
#define kOverlayLoadingTexture @"overlay_loading"
#define kOverlayOptionsmenuTexture @"overlay_optionsmenu"
#define kOverlayOptionsmenuTimeattackTexture @"overlay_optionsmenu_timeattack"
#define kEffectDamageTexture @"effect_damage"
#define kEffectSpeedupTexture @"effect_speedup"
#define kEffectBombTexture @"effect_bomb"
#define kEffectWaveTexture @"effect_wave"
#define kEffectShadowTexture @"effect_shadow"
#define kSpriteMissileTexture @"sprite_missile"
#define kSpriteSmokeTexture @"sprite_smoke"
#define kSpriteRocketTexture @"sprite_rocket"
#define kSpriteParticleTexture @"sprite_particle"
#define kSpriteSparkTexture @"sprite_spark"


#ifdef TARGET_OS_IPHONE

#define UNLOCKTRACK(x)          (id)^{ \
    $setdefaulti(1, $stringf(kTrackIUnlocked, (x))); \
    $setdefaulti((x-1), kTrackNumKey); \
    $defaultsync;}
#else

#define UNLOCKTRACK(x)          (id)^{ \
    $setdefaulti(1, $stringf(kTrackIUnlocked, (x))); \
    $setdefaulti(CareerRealToPopup((x-1)), kTrackNumKey); \
    $defaultsync;}

#endif
#define ADDMONEY(x)             (id)^{ \
    $setdefaulti($defaulti(kAvailableCashKey) + (x), kAvailableCashKey); \
    $defaultsync;}
#define UNLOCKSHIP(x)           (id)^{ \
    $setdefaulti(1, $stringf(kShipIUnlocked, (x))); \
    $setdefaulti((x-1), kShipNumKey); \
    $defaultsync;}

#define kNumTracks 6
#define kNumShips 7


#define KEYS $array(@"Player1AccelerateKey", @"Player1SteerLeftKey", @"Player1SteerRightKey", @"Player1LookBackKey", @"Player1FireWeaponKey", @"Player1ChangeCameraKey", \
@"Player2AccelerateKey", @"Player2SteerLeftKey", @"Player2SteerRightKey", @"Player2LookBackKey", @"Player2FireWeaponKey", @"Player2ChangeCameraKey");

#define kWeaponUpgradesKeyNames $array(kBombUpgraded, kMinesUpgraded, kWaveUpgraded, kSpeedupUpgraded, kDamageUpgraded)

#define kDifficultyNamesList    @"Trivial", @"Easy", @"Medium", @"Hard", @"Extreme"
#define kDifficultyNames        $array(kDifficultyNamesList)
#define kEnemyNames             $array(@"Eagle 5", @"Planet Express", @"Millennium Falcon", @"Black Betha", @"Hyperion", @"Aries Ib", @"Buzzbomb", @"KITT", @"TschittyTschittyBaengBaeng", @"Starship Titanic", @"Heart Of Gold", @"SSV Normandy SR-1", @"UESC Marathon", @"Harkonnen Ornithopter", @"Gadgetmobile", @"Manus Celer Dei")


#define kShipOctreeNames        $array(@"ship0_NovaRay", @"ship1_Flare", @"ship2_Venom", @"ship3_Enigma", @"ship4_Carnage", @"ship5_Flavor", @"ship6_Reeper")
#define kShipNames              $array(@"Nova Ray", @"Flare", @"Venom", @"Enigma", @"Carnage", @"Flavor", @"Reeper")
#define kShipHandling           $array(@"8.1", @"7.3", @"6.5", @"5.4", @"4.7", @"3.9", @"7.0")
#define kShipTopspeed           $array(@"3.9", @"4.6", @"5.7", @"6.5", @"7.4", @"8.1", @"9.0")
#define kShipAcceleration       $array(@"6.1", @"5.7", @"4.7", @"4.5", @"3.7", @"3.4", @"8.0")

#define kTrackLength            $array(@"1.2", @"5.4", @"5.1", @"9.2", @"7.5", @"8.1") // tp * 0.55
#define kTrackSpeed             $array(@"3.0", @"5.0", @"7.0", @"6.0", @"6.0", @"9.9")
#define kTrackDifficulty        $array(@"4.5", @"5.4", @"4.7", @"9.5", @"8.9", @"9.0")


#define kTrackSHA1              $array( @"9f46e6c1f4cb167ee9d41309e8b8ae685feab191", \
                                        @"cc4724da07b2db2cbc0775d1f93c5155daa54de4", \
                                        @"d98973145b61adac023ec000138bb51b13fda86e", \
                                        @"20e5e89f36b3418bb19cffe140eef1c4abd28851", \
                                        @"0d4b475e7d5452109e0303a6d8d2d2b1f6ef998c", \
                                        @"bf1562346b920824c025a08524a68fc53f9cd01a")


#define kTrackRounds            $array(@"4", @"2", @"3", @"2", @"2", @"2")
//#define kTrackRounds            $array(@"1", @"1", @"1", @"1", @"1", @"1")
//#warning revert



#define kWeaponUpgradesCosts    $array(@"500", @"800", @"1200", @"2500", @"5000")



#define kAccelUpgradesCosts     $array(@"1000", @"1750", @"2750")
#define kHandlingUpgradesCosts    $array(@"1500", @"2000", @"3000")
#define kTopSpeedUpgradesCosts    $array(@"1500", @"1800", @"2200")

#define kAccelUpgrades          $array(@"1.1", @"0.9", @"0.8")
#define kHandlingUpgrades       $array(@"0.8", @"0.6", @"0.5")
#define kTopSpeedUpgrades       $array(@"0.8", @"0.6", @"0.5")

#ifdef NODATA

#define kTrackObjectsNamesLit			$array( $earray, $earray, $earray, $earray, $earray, $earray, $earray)
#define kTrackObjectsNamesUnlit			$array( $earray, $earray, $earray, $earray, $earray, $earray, $earray)
#define kTrackObjectsNamesLitWithShadow $array( $earray, $earray, $earray, $earray, $earray, $earray, $earray)

#else

#define kTrackObjectsNamesLit   $array( \
$array(@"track1_1", @"track1_2", @"track1_3", @"track1_4", @"track1_5", @"track1_6", @"track1_Felsen", @"track1_Floor", @"track1_Hive", @"track1_Kreisel_Staender"), \
$array(@"track2_01", @"track2_02", @"track2_03", @"track2_04", @"track2_05", @"track2_06", @"track2_floor_2", @"track2_Hive"), \
$array(@"track3_Hive", @"track3_01", @"track3_02", @"track3_03", @"track3_04", @"track3_Sperre", @"track3_BohrturmTurbine", @"track3_Skyline"), \
$array(@"track4_Hive", @"track4_01", @"track4_02", @"track4_03", @"track4_04", @"track4_05", @"track4_06", @"track4_Windraeder_Staender", @"track4_floor"), \
$array(@"track5_01", @"track5_02", @"track5_03", @"track5_04", @"track5_05", @"track5_06", @"track5_07", @"track5_Felsen", @"track5_Hive", @"track5_Standbein_Hammer", @"track5_Floor"), \
$array(@"track6_01", @"track6_02", @"track6_03", @"track6_04", @"track6_05", @"track6_06", @"track6_Hive"), \
$array(@"track7_Array", @"track7_Dome", @"track7_Gitter", @"track7_Landschaft", @"track7_Part1", @"track7_Part2", @"track7_Part3", @"track7_Part4", @"track7_Tunnel_Kurve_BIG", @"track7_Tunnel_Kurve"))

#define kTrackObjectsNamesUnlit $array( \
$earray, \
$earray, \
$earray, \
$earray, \
$earray, \
$earray, \
$array(@"track7_Felsen"))

#define kTrackObjectsNamesLitWithShadow $array( \
$earray, \
$earray, \
$earray, \
$earray, \
$earray, \
$earray, \
$array(@"track7_Hive"))
#endif


#define kTrackNames             $array($stringcu8("Tannhäuser Stargate"), @"Soylent Black", @"Quantum Circuit", @"Blaspheme Quarantine", @"Frogpill Quasar", @"Terminal Velocity")


#define kMusicNames             $array(@"Klez - I Need you to Escape", @"Abstract Audio - L.T.H. (AA's Refix)", @"Alex Beroza - Straight To The Light", @"djguido - The Pharmacy in my head", @"IceSun - Cool_Boy [IceSun Rmx]", @"snowflake - the New Music Mantra", @"vantage600 - F*KING BOUNCE", @"Benjamin Orth - Bustin Out", @"dr_gore2000 - The Right Time", @"Klez - Imperfect World")

#define kObjectiveKey   @"Objective"
#define kRewardKey      @"Reward"
#define kRewardBlockKey @"RewardBlock"
#define kConditionKey   @"Condition"
#define kIconKey        @"Icon"


#define kObjectivesPerTrack     $array( \
$array( $dict(NSLocalizedString(@"Win at track 1", nil), kObjectiveKey, NSLocalizedString(@"unlock track 2!", nil), kRewardKey, @"reward_track", kIconKey, UNLOCKTRACK(7), kRewardBlockKey, $predf(@"endSieg = 1"), kConditionKey), \
        $dict(NSLocalizedString(@"Podiumplace track 1", nil), kObjectiveKey, NSLocalizedString(@"unlock ship 2!", nil), kRewardKey, @"reward_ship", kIconKey, UNLOCKSHIP(2), kRewardBlockKey, $predf(@"endSieg <= 3"), kConditionKey) ), \
$array( $dict(NSLocalizedString(@"Win at track 3", nil), kObjectiveKey, NSLocalizedString(@"unlock track 4!", nil), kRewardKey, @"reward_track", kIconKey, UNLOCKTRACK(8), kRewardBlockKey, $predf(@"endSieg = 1"), kConditionKey), \
        $dict(NSLocalizedString(@"Podiumplace track 2", nil), kObjectiveKey, NSLocalizedString(@"unlock ship 3!", nil), kRewardKey, @"reward_ship", kIconKey, UNLOCKSHIP(3), kRewardBlockKey, $predf(@"endSieg <= 3"), kConditionKey) ), \
$array( $dict(NSLocalizedString(@"Win at track 5", nil), kObjectiveKey, NSLocalizedString(@"unlock track 6!", nil), kRewardKey, @"reward_track", kIconKey, UNLOCKTRACK(9), kRewardBlockKey, $predf(@"endSieg = 1"), kConditionKey), \
        $dict(NSLocalizedString(@"Podiumplace track 3", nil), kObjectiveKey, NSLocalizedString(@"unlock ship 4!", nil), kRewardKey, @"reward_ship", kIconKey, UNLOCKSHIP(4), kRewardBlockKey, $predf(@"endSieg <= 3"), kConditionKey) ), \
$array( $dict(NSLocalizedString(@"Win at track 7", nil), kObjectiveKey, NSLocalizedString(@"unlock track 8!", nil), kRewardKey, @"reward_track", kIconKey, UNLOCKTRACK(10), kRewardBlockKey, $predf(@"endSieg = 1"), kConditionKey), \
        $dict(NSLocalizedString(@"Podiumplace track 4", nil), kObjectiveKey, NSLocalizedString(@"unlock ship 5!", nil), kRewardKey, @"reward_ship", kIconKey, UNLOCKSHIP(5), kRewardBlockKey, $predf(@"endSieg <= 3"), kConditionKey) ), \
$array( $dict(NSLocalizedString(@"Win at track 9", nil), kObjectiveKey, NSLocalizedString(@"unlock track 10!", nil), kRewardKey, @"reward_track", kIconKey, UNLOCKTRACK(11), kRewardBlockKey, $predf(@"endSieg = 1"), kConditionKey), \
        $dict(NSLocalizedString(@"Podiumplace track 5", nil), kObjectiveKey, NSLocalizedString(@"unlock ship 6!", nil), kRewardKey, @"reward_ship", kIconKey, UNLOCKSHIP(6), kRewardBlockKey, $predf(@"endSieg <= 3"), kConditionKey) ), \
$array( $dict(NSLocalizedString(@"Win at track 11", nil), kObjectiveKey, NSLocalizedString(@"unlock track 12!", nil), kRewardKey, @"reward_track", kIconKey, UNLOCKTRACK(12), kRewardBlockKey, $predf(@"endSieg = 1"), kConditionKey) ), \
\
$array( $dict(NSLocalizedString(@"Win at track 2", nil), kObjectiveKey, NSLocalizedString(@"unlock track 3!", nil), kRewardKey, @"reward_track", kIconKey, UNLOCKTRACK(2), kRewardBlockKey, $predf(@"endSieg = 1"), kConditionKey)), \
$array( $dict(NSLocalizedString(@"Win at track 4", nil), kObjectiveKey, NSLocalizedString(@"unlock track 5!", nil), kRewardKey, @"reward_track", kIconKey, UNLOCKTRACK(3), kRewardBlockKey, $predf(@"endSieg = 1"), kConditionKey)), \
$array( $dict(NSLocalizedString(@"Win at track 6", nil), kObjectiveKey, NSLocalizedString(@"unlock track 7!", nil), kRewardKey, @"reward_track", kIconKey, UNLOCKTRACK(4), kRewardBlockKey, $predf(@"endSieg = 1"), kConditionKey)), \
$array( $dict(NSLocalizedString(@"Win at track 8", nil), kObjectiveKey, NSLocalizedString(@"unlock track 9!", nil), kRewardKey, @"reward_track", kIconKey, UNLOCKTRACK(5), kRewardBlockKey, $predf(@"endSieg = 1"), kConditionKey)), \
$array( $dict(NSLocalizedString(@"Win at track 10", nil), kObjectiveKey, NSLocalizedString(@"unlock track 11!", nil), kRewardKey, @"reward_track", kIconKey, UNLOCKTRACK(6), kRewardBlockKey, $predf(@"endSieg = 1"), kConditionKey)), \
$array( $dict(NSLocalizedString(@"Win at track 12", nil), kObjectiveKey, NSLocalizedString(@"finish game!", nil), kRewardKey, @"reward_cash", kIconKey, ADDMONEY(6000), kRewardBlockKey, $predf(@"endSieg = 1"), kConditionKey), \
        $dict(NSLocalizedString(@"Win at level Hard", nil), kObjectiveKey, NSLocalizedString(@"unlock REEPER!", nil), kRewardKey, @"reward_reeper", kIconKey, UNLOCKSHIP(7), kRewardBlockKey, $predf(@"(endSieg = 1) AND (difficulty >= 3)"), kConditionKey)) \
)

#define kObjectivesEveryTrack   $array( \
$dict(NSLocalizedString(@"Win a race", nil), kObjectiveKey, NSLocalizedString(@"get 800 cash!", nil), kRewardKey, @"reward_cash", kIconKey, ADDMONEY(800), kRewardBlockKey, $predf(@"endSieg = 1"), kConditionKey), \
$dict(NSLocalizedString(@"Become 2nd", nil), kObjectiveKey, NSLocalizedString(@"get 400 cash!", nil), kRewardKey, @"reward_cash", kIconKey, ADDMONEY(400), kRewardBlockKey, $predf(@"endSieg = 2"), kConditionKey), \
$dict(NSLocalizedString(@"Become 3rd", nil), kObjectiveKey, NSLocalizedString(@"get 200 cash!", nil), kRewardKey, @"reward_cash", kIconKey, ADDMONEY(200), kRewardBlockKey, $predf(@"endSieg = 3"), kConditionKey), \
$dict(NSLocalizedString(@"Corebreach an enemy", nil), kObjectiveKey, NSLocalizedString(@"get 600 cash!", nil), kRewardKey, @"reward_cash", kIconKey, ADDMONEY(600), kRewardBlockKey, $predf(@"corebreaches >= 1"), kConditionKey), \
$dict(NSLocalizedString(@"Lead a whole round", nil), kObjectiveKey, NSLocalizedString(@"get 200 cash!", nil), kRewardKey, @"reward_cash", kIconKey, ADDMONEY(200), kRewardBlockKey , $predf(@"leadrounds >= 1"), kConditionKey), \
$dict(NSLocalizedString(@"Fly a clean round", nil), kObjectiveKey, NSLocalizedString(@"get 200 cash!", nil), kRewardKey, @"reward_cash", kIconKey, ADDMONEY(200), kRewardBlockKey, $predf(@"cleanrounds >= 1"), kConditionKey) )


#ifdef TARGET_OS_IPHONE

#define topButtonSize (ipad ? 64.0 : 40.0)
#define controlButtonSize (ipad ? 96.0 : 64.0)
#define topButtonSizeHalf (topButtonSize / 2.0)
#define pauseOffset (ipad ? 5 : -40)
#define cameraOffset (ipad ? -69 : -90)

#define kIphoneTrackSpeedModifier 0.85
#define kIphoneEnemySpeedModifier 0.95


typedef enum
{
	kAccelerometer = 0,
	kButtons = 1,
	kTouchpad = 2,
} steeringModeEnum;

#endif

@interface CoreBreach : NSObject
{}

+ (NSDictionary *)fetchResult1 __attribute__((ns_returns_retained));
+ (NSDictionary *)fetchResult2 __attribute__((ns_returns_retained));
+ (NSDictionary *)fetchSettings __attribute__((ns_returns_retained));

@end


