//
//  Racetrack.h
//  Core3D
//
//  Created by CoreCode on 07.05.08.
//  Copyright 2008 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#define Y_OFFSET 1.0f
#define Y_EXTRABB_OFFSET 0.5f
#define MAX_ENEMIES 12

@interface Racetrack : CollideableMeshBullet
{
	float *trackPath;
	uint16_t trackPoints;

	float *enemyPath[MAX_ENEMIES];
	uint16_t enemyPoints[MAX_ENEMIES];
//    NSBitmapImageRep *trackLightBitmap;
	char *trackLightBuffer;
	uint8_t tracknum, meshnum;
}

@property (assign, nonatomic) uint16_t trackPoints;

- (id)initWithTracknumber:(uint8_t)tracknum andMeshtracknumber:(uint8_t)meshnum;
- (vector3f)positionAtIndex:(int)index;
- (vector3f)positionAtIndex:(int)index forEnemy:(uint8_t)enemy;
- (vector3f)interpolatedPositionAtIndex:(float)indexf forEnemy:(uint8_t)enemy;
- (uint16_t)enemyPointsForEnemy:(uint8_t)enemy;
- (float)lightAtPoint:(CGPoint)point;

@end