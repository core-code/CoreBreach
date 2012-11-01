//
//  Playership.h
//  Core3D
//
//  Created by CoreCode on 04.05.08.
//  Copyright 2008 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#define kZ_RBSize 3
#define kX_RBSize 15

@interface Playership : CollideableMeshBullet <Ship>
{
	float umin, umax, vmin, vmax;
	BOOL hasBeenFalling;
	SOUND_TYPE hitSoundArray[5];
	uint8_t hitSoundIndex;
	double lastWallCollision, lastEnemyCollision;
#ifndef TARGET_OS_IPHONE
    HIDSupport *hid;
#else
	float fieldWidth;
#endif

	BOOL alwaysLeftHack, invertAccel, halfAccel, useController, singleSteer, binarySteer, lastFrameFire, lastFrameCamera, lastFrameLookback;
	BOOL isRescuing;
	BOOL alwaysLeading, noWallhit;
	float rotationXRingbuffer[kX_RBSize];
	float rotationZRingbuffer[kZ_RBSize];
	FireParticlesystem *fire1, *fire2;
	FireParticlesystem *spark;

	SceneNode *shieldSphereNode, *damageSphereNode;
	uint8_t playerNumber;
	double fireButtonStart;

	SceneNode *wallSoundNode;//, *hitSoundNode;

	BOOL didntCheat;
	NSMutableData *ghostData;

	short placing;
	Powerup *powerup;
	short round;
	int falling;
	float core;

	uint8_t cameraMode;
	Camera *attachedCamera;
	Light *exhaustLight;

	float shipWallhitAccelerationSlowdownFactor;
	float shipHandling;
	float shipAcceleration;
	float shipTopSpeed;
	float trackSpeedModifier;
	vector3f input;

	int keys[14];

	float weaponSlowdownFactor;
	float weaponYRotAddition;
	float maxpitch;
	vector3f velocity, speed;
	HUD *ourHUD;
	PostprocessingShader *_ourPP;
	int currpoint, currpointfull;
	short shieldVisible, damageVisible;
	SceneNode *collSoundNode;

	double coreModeFinish, slowmoFinish;
	BOOL isHit, coreModeActive, slowmoFired;

	float coreModeIntensity;
	uint8_t shipNum;

	uint16_t _numPoints;

@public
	RenderPass *rp;
}

@property (readonly) double coreModeFinish;
@property (readonly) double slowmoFinish;
@property (readonly) BOOL isRescuing;
@property (readonly) float coreModeIntensity;
@property (readonly) BOOL isHit;
@property (assign) short shieldVisible;
//@property (assign, nonatomic) RenderPass *rp;
@property (assign, nonatomic) Light *exhaustLight;
@property (assign, nonatomic) PostprocessingShader *_ourPP;
@property (assign, nonatomic) HUD *ourHUD;
@property (readonly, nonatomic) BOOL noWallhit;
@property (readonly, nonatomic) BOOL alwaysLeading;
@property (readonly, nonatomic) float core;
@property (readonly, nonatomic) Powerup *powerup;
@property (readonly, nonatomic) FireParticlesystem *spark;
@property (readonly, nonatomic) FireParticlesystem *fire1;
@property (readonly, nonatomic) FireParticlesystem *fire2;
@property (assign, nonatomic) short placing;
@property (assign, nonatomic) short round;
@property (readonly, nonatomic) int currpoint;
@property (readonly, nonatomic) int currpointfull;
@property (readonly, nonatomic) vector3f velocity;
@property (readonly, nonatomic) vector3f speed;
@property (readonly, nonatomic) NSMutableData *ghostData;
@property (nonatomic, assign) Camera *attachedCamera;
@property (assign, nonatomic) uint8_t playerNumber;
@property (assign, nonatomic) BOOL coreModeActive;
@property (readonly, nonatomic) BOOL slowmoFired;

- (void)setShipNum:(int)_shipNum;
- (void)adjustCamera:(BOOL)lookBack;
- (void)resetGhostData;
#ifndef TARGET_OS_IPHONE
- (void)keyDown:(NSEvent *)theEvent;
- (void)keyUp:(NSEvent *)theEvent;
#endif
- (void)resetLapObjectives;
- (void)handleCamera;

- (void)recordGhost;
+ (void)setupFire1:(FireParticlesystem *)fire1 andFire2:(FireParticlesystem *)fire2 forShipNum:(uint8_t)shipNum;
@end
