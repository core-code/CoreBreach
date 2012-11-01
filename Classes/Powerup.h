//
//  Powerup.h
//  Core3D
//
//  Created by CoreCode on 04.06.08.
//  Copyright 2008 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "SphereParticlesystem.h"
#import "HUD.h"


extern short qdEnabled;
extern float qdTrackpoint;

@class Playership;

typedef enum
{
	kNoWeaponLoaded = 0,
	kFirstWeaponIndex = 1,
	kRockets = 1,
	kMines,
	kMissile,
	kBomb,
	kWave,
	kPlasma,
	kLastWeaponIndex = 6,
	kSpeedup = 7,
} weaponTypeEnum;

#define kWeaponNames    $array(@"", @"Photon Torpedos", @"Proximity Mines", @"Fusion Missile", @"Tachion Bomb", @"Carpet Wave", @"Zeus Plasma Cannon", @"Space Nitro")


@protocol Ship;

@interface Powerup : SceneNode
{
	weaponTypeEnum loadedWeapon;
	BOOL nitroLoaded;

	weaponTypeEnum activePowerup;


	//  BOOL hasSpeedup, hasAdditionalSpeedup;


	Shader *additionalBlendTextureShader;
	SceneNode *rocketSoundNode, *mineSoundNode, *missileSoundNode, *bombSoundNode, *waveSoundNode, *plasmaSoundNode, *speedSoundNode;
	SceneNode <Ship> *masterShip;
	Light *weaponLight;
	NSMutableArray *missileSmoke;
	AnimatedTextureShader *mines;
	SceneNode <Ship> *explodingShip;
	SpriteNode *missileSprite;
	NSMutableSet *smokeNodes;
	SpriteNode *rocketSprite1, *rocketSprite2, *rocketSprite3;

	float speedUp;
	double deployTime;
	BOOL missileSmokeEnabled;
	Texture *wavetex;
	vector3f velocity;
	SphereParticlesystem *plasmaBolt;
	Mesh *wave, *mine;
	CollideableMeshBullet *missile;
	SceneNode *bomb;
	SceneNode *bombSphere;
//	GLuint qdfireTexName[5];
	Shader *waveshader;
	GLint qdposPos;
	float trackSpeedModifier;
}

@property (readonly, nonatomic) Light *weaponLight;
@property (assign, nonatomic) float speedUp;
@property (assign, nonatomic) vector3f velocity;
@property (readonly, nonatomic) weaponTypeEnum activePowerup;
@property (readonly, nonatomic) BOOL nitroLoaded;

- (id)initWithOwner:(SceneNode <Ship> *)owner;

- (BOOL)loaded;
- (BOOL)canPickupWeapon;
- (BOOL)canPickupNitro;
- (BOOL)canDeploy;
- (weaponTypeEnum)activePowerupOrLoadedPowerup; // returns the active powerupo if there is an active powerup else the *primary* loaded powerup is returnes, which is a weapon if there is a weapon else nitro. returns null (kNoWeaponLoaded) if nothing is loaded
- (void)deploy:(BOOL)nitro;
- (void)pickup:(BOOL)nitro forShip:(SceneNode <Ship> *)ship;

@end

@protocol Ship <Collideable>

- (void)hit:(hitEnum)severity;
- (void)hasHit:(BOOL)_deadly;

@property (readonly, nonatomic) BOOL coreModeActive;
@property (readonly, nonatomic) Powerup *powerup;
@property (readonly) BOOL isHit;
@property (assign, nonatomic) PostprocessingShader *_ourPP;
@property (assign, nonatomic) HUD *ourHUD;
@property (readonly, nonatomic) vector3f speed;
@property (assign) short shieldVisible;
@property (assign) short damageVisible;
@property (readonly, nonatomic) int currpoint;
@property (readonly, nonatomic) int currpointfull;
@property (assign, nonatomic) short round;
@property (nonatomic, readonly) SceneNode *collSoundNode;
@property (readonly, nonatomic) FireParticlesystem *fire1;
@property (readonly, nonatomic) FireParticlesystem *fire2;

@end