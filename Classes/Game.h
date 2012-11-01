//
//  Game.h
//  Core3D
//
//  Created by CoreCode on 19.11.07.
//  Copyright 2007 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//


#import "Core3D.h"


//#define MICROINIT		uint64_t micro = GetNanoseconds() / 1000;
//#define MICROSINCESIM	(micro - game.simulationStartMicro)
//#define MICROSINCE(x)	(micro - (x))
#ifdef TARGET_OS_IPHONE
#ifdef IPAD
#define BLOB_CONTRIBUTION_CULLING_DISTANCE 100.0f
#define BOX_CONTRIBUTION_CULLING_DISTANCE 250.0f
#else
#define BLOB_CONTRIBUTION_CULLING_DISTANCE 130.0f
#define BOX_CONTRIBUTION_CULLING_DISTANCE 300.0f
#endif
#else
#define BLOB_CONTRIBUTION_CULLING_DISTANCE 170.0f
#define BOX_CONTRIBUTION_CULLING_DISTANCE 650.0f
#endif

#import "SnowParticlesystem.h"
#import "FireParticlesystem.h"
#import "PostprocessingShader.h"
#import "OutlineShader.h"
#import "FocusingCamera.h"
#import "ShadowShader.h"
#import "Skybox.h"
#import "PlasmaShader.h"
#import "AnimatedTextureShader.h"

#import "Powerup.h"
#import "Track.h"
#import "Enemyship.h"
#import "Playership.h"
#import "Ghostship.h"
#import "Simulation.h"
#import "HUD.h"
#import "GameShader.h"
#import "BonusBox.h"
#import "PVSNode.h"


#ifndef TARGET_OS_IPHONE
#import "GameSheetController.h"
#endif

#import "CoreBreach.h"


#define kGameFov 70

#define IS_MULTI (game.gameMode == kGameModeMultiplayer)

typedef struct _Sounds
{
	SOUND_TYPE newTrackVoice;
	SOUND_TYPE first;
	SOUND_TYPE second;
	SOUND_TYPE third;
	SOUND_TYPE bad_result;
	SOUND_TYPE coremode;

	SOUND_TYPE one;
	SOUND_TYPE two;
	SOUND_TYPE three;
	SOUND_TYPE go;
	SOUND_TYPE newship;


	SOUND_TYPE incoming;

	SOUND_TYPE checkpoint;

	SOUND_TYPE elimination1;
	SOUND_TYPE elimination2;
} Sounds;

extern Sounds sounds;

#ifdef TARGET_OS_IPHONE

#define STEERING_ACCELEROMETER                          (game.steeringMode  == kAccelerometer)
#define STEERING_BUTTONS                                (game.steeringMode  == kButtons)
#define STEERING_TOUCHPAD                               (game.steeringMode  == kTouchpad)

#endif

@interface Game : Simulation
{
	uint8_t steeringMode;
	BOOL accelWeapon;
	float accelerometerSensitivity;
	PostprocessingShader *pp;
	PostprocessingShader *pp2;
	HUD *hud;
	HUD *hud2;

	SceneNode *ghostShipGroupNode;


#ifdef SDL
    int8_t                  pauseButtonSelection;
#endif

#ifndef TARGET_OS_MAC
	Texture *pauseTexture;
#endif
	Racetrack *currentTrack;
	CollideableMeshBullet *currentTrackBorder;

	Playership *ship;
	Playership *ship2;

	NSArray *shipNames;
	NSArray *bonusboxen;
	NSArray *enemies;
	NSArray *ships;

	BOOL multiCore;

	Mesh *realTrack;

	DynamicNode *dynamicNode;
	flightModeEnum flightMode;
	float flightStartTime;

	uint8_t lodMode;
	uint8_t aliveShipCount;
	uint8_t enemiesNum;
	gameModeEnum gameMode;
	uint8_t trackNum;
	uint8_t meshTrackNum;
	uint8_t difficulty;
	uint8_t shipNum;
	uint8_t ship2Num;
	uint8_t roundsNum;
	uint8_t postProcessingLevel;
	uint32_t highscoreTrackNum;
#ifndef DISABLE_SOUND
	MusicManager *musicManager;
#endif
	Mesh *shieldSphere;
	Mesh *damageSphere;
	Mesh *mineMesh;
	Mesh *bombMesh;

	NSString *trackName;
	BOOL bombUpgraded, minesUpgraded, waveUpgraded, speedupUpgraded, damageUpgraded;

	NSData *heliData1, *heliData2, *heliData3;
	Mesh *heliMesh;
	SceneNode *heli1, *heli2, *heli3;
	Texture *storyTex;
	NSDictionary *trackProperties;

	ShaderNode *phongShader;
	AnimatedTextureShader *animatedTextureShader;

	SceneNode *damageSphereNode;
	SceneNode *shieldSphereNode;
	SceneNode *particleNode;
	SceneNode *mineNode;
	SceneNode *spriteNode;
}

// scene graph attachment points
@property (nonatomic, readonly) SceneNode *damageSphereNode;
@property (nonatomic, readonly) SceneNode *shieldSphereNode;
@property (nonatomic, readonly) SceneNode *particleNode;
@property (nonatomic, readonly) SceneNode *mineNode;
@property (nonatomic, readonly) SceneNode *spriteNode;
@property (nonatomic, readonly) AnimatedTextureShader *animatedTextureShader;
@property (nonatomic, readonly) ShaderNode *phongShader;

// reuseable mesh nodes for scene graph attachment
@property (nonatomic, readonly) Mesh *bombMesh;
@property (nonatomic, readonly) Mesh *mineMesh;
@property (nonatomic, readonly) Mesh *shieldSphere;
@property (nonatomic, readonly) Mesh *damageSphere;

@property (nonatomic, readonly) DynamicNode *dynamicNode;

@property (nonatomic, readonly) NSDictionary *trackProperties;
@property (nonatomic, readonly) BOOL bombUpgraded;
@property (nonatomic, readonly) BOOL multiCore;
@property (nonatomic, readonly) BOOL waveUpgraded;
@property (nonatomic, readonly) BOOL speedupUpgraded;
@property (nonatomic, readonly) BOOL minesUpgraded;
@property (nonatomic, readonly) BOOL damageUpgraded;
@property (nonatomic, readonly) uint8_t postProcessingLevel;
@property (nonatomic, readonly) flightModeEnum flightMode;
@property (nonatomic, readonly) uint8_t roundsNum;
@property (nonatomic, readonly) uint8_t lodMode;
@property (nonatomic, readonly) BOOL accelWeapon;
@property (nonatomic, readonly) uint8_t steeringMode;

@property (nonatomic, readonly) uint8_t enemiesNum;
@property (nonatomic, readonly) uint8_t trackNum;
@property (nonatomic, readonly) uint8_t meshTrackNum;
@property (nonatomic, readonly) uint8_t difficulty;
@property (nonatomic, readonly) uint8_t shipNum;
@property (nonatomic, readonly) uint8_t ship2Num;
@property (nonatomic, readonly) uint32_t highscoreTrackNum;
@property (nonatomic, readonly) NSString *trackName;
@property (nonatomic, readonly) float accelerometerSensitivity;
@property (nonatomic, readonly) gameModeEnum gameMode;
@property (nonatomic, readonly) uint8_t aliveShipCount;
@property (nonatomic, readonly) SceneNode *ghostShipGroupNode;
@property (nonatomic, readonly) HUD *hud;
@property (nonatomic, readonly) HUD *hud2;
@property (nonatomic, readonly) Racetrack *currentTrack;
@property (nonatomic, readonly) CollideableMeshBullet *currentTrackBorder;
@property (nonatomic, readonly) Playership *ship;
@property (nonatomic, readonly) Playership *ship2;
@property (nonatomic, readonly) NSArray *bonusboxen;
@property (nonatomic, readonly) NSArray *enemies;
@property (nonatomic, readonly) NSArray *ships;
@property (nonatomic, readonly) NSArray *shipNames;

- (void)startPause;
- (void)stopPause;

+ (void)renderSplash;

- (float)flightTime;
- (float)remainingFlightTime;
- (void)setupFlightMode;
- (void)advanceFlightMode;
- (void)willResign:(NSNotification *)noti;
- (void)willBecome:(NSNotification *)noti;
- (void)handleBackground:(NSNotification *)noti;
- (void)pauseSoundAndMusic;

@end

extern Game *game;
