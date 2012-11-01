//
//  Enemyship.h
//  Core3D
//
//  Created by CoreCode on 08.05.08.
//  Copyright 2008 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//


#import "Powerup.h"


@interface Enemyship : CollideableSceneNode <Ship>
{
//    BOOL dead;
	float umin, umax, vmin, vmax;
	BOOL dontplaysirene;
	float trackSpeedFactor;
	float angleRingbuffer[10];

	Mesh *meshToRender;
	Mesh *realmesh;
	Mesh *realmesh_lod;
	short round, enemyIndex;
	float nearestTrackpoint;
	float weaponSlowdownFactor;
	float weaponYRotAddition;
	FireParticlesystem *fire1, *fire2;
	SceneNode *shieldSphereNode, *damageSphereNode;

	short shieldVisible, damageVisible;

	BOOL wasVisible, isHit;

	Powerup *powerup;

	Camera *attachedCamera;

	SceneNode *hitSoundNode;

	SceneNode *collSoundNode;

	uint16_t _numPoints;

	BOOL isCameraShip;
}

@property (readonly, nonatomic) Powerup *powerup;
@property (assign, nonatomic) float nearestTrackpoint;
@property (assign, nonatomic) short round;
@property (assign) short shieldVisible;
@property (assign) short damageVisible;
@property (assign, nonatomic) short enemyIndex;
@property (readonly) BOOL isHit;
@property (readonly, nonatomic) BOOL coreModeActive;
@property (nonatomic, assign) Camera *attachedCamera;
@property (readonly, nonatomic) FireParticlesystem *fire1;
@property (readonly, nonatomic) FireParticlesystem *fire2;

- (id)initWithOctreeNamed:(NSString *)_name;
- (void)setShipNum:(int)shipNum;
- (void)setColor:(vector4f)newColor;
//- (Mesh *)shadowmesh;

@end


