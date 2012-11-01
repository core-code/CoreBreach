//
//  Ghostship.mm
//  Core3D
//
//  Created by CoreCode on 25.12.10.
//  Copyright 2008 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "Game.h"


@implementation Ghostship

@synthesize data, shipNum;


- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithOctree:(NSURL *)file andName:(NSString *)_name
{
	if ((self = [super initWithOctree:file andName:_name]))
	{
	}

	return self;
}

- (void)updateNode
{
#ifndef DEMO
	float t = [game.hud timeInCurrentRound];
	if ([game.ship round] < 1)
		t = 0.0;
	int f = floorf(t * 30.0);

	//NSLog(@"bla start  %i %i %i", (f * 3 * 2 + 9) * 4 + 3, [data length]);

	if ((f * 3 * 2 + 9) * 4 + 3 < (int) [data length])
	{
		float *d = (float *) [data bytes];

		vector3fe pos1 (&d[f * 3 * 2]);
		vector3fe rot1 (&d[f * 3 * 2 + 3]);
		vector3fe pos2 (&d[f * 3 * 2 + 6]);
		vector3fe rot2 (&d[f * 3 * 2 + 9]);

		//	NSLog(@"data start length end %i %i %i", [data bytes], [data length], (char *)[data bytes] + [data length]);
		//	NSLog(@"accessing %i + 12", &d[f * 3 * 2 + 9]);
		//	cout << f << endl;
		//	cout << f * 3 * 2 + 9 << endl;
		//	cout << [data length] << endl;
		//	cout << pos1 << pos2 << rot1 << rot2 << endl;

		[self setPosition:lerp(pos1, pos2, (t * 30.0) - f)];
		[self setRotation:lerp(rot1, rot2, (t * 30.0) - f)];
	}
	//else
	//    NSLog(@"not accessing out of bounds ghostship data");

	[super updateNode];
#endif
}

- (void)setShipNum:(uint8_t)_shipNum
{
	shipNum = _shipNum;
	int _class = MIN(shipNum / 2, 2);
	if (_class == 0)
	{
		umin = 0.0f;
		umax = 0.5f;
		vmin = 0.5f;
		vmax = 1.0f;
	}
	else if (_class == 1)
	{
		umin = 0.5f;
		umax = 1.0f;
		vmin = 0.5f;
		vmax = 1.0f;
	}
	else if (_class == 2)
	{
		umin = 0.0f;
		umax = 0.5f;
		vmin = 0.0f;
		vmax = 0.5f;
	}
}

- (void)renderNode
{
	if (game.flightMode < kFlightGame)
		return;

	if (/*globalSettings.shadowMode < kEverything && */currentRenderPass.settings == kMainRenderPass)
	{
		[currentCamera push];
		[currentCamera identity];
		float rot = rotation[2];
		rotation[2] = 0;
		[self transform];
		rotation[2] = rot;
		matrix44f_c viewMatrix = [currentCamera modelViewMatrix];

		struct octree_node const *const n1 = (struct octree_node *) NODE_NUM(0);
		const float aabbOriginX = n1->aabbOriginX * 1.4f;
		const float aabbExtentX = n1->aabbExtentX * 1.4f;
		const float aabbOriginZ = n1->aabbOriginZ * 1.2f;
		const float aabbExtentZ = n1->aabbExtentZ * 1.2f;
		const float offset = -Y_OFFSET * 0.95f;

		vector4f v1 = viewMatrix * vector4f(aabbOriginX, offset, aabbOriginZ, 1.0f);
		vector4f v2 = viewMatrix * vector4f(aabbOriginX + aabbExtentX, offset, aabbOriginZ, 1.0f);
		vector4f v3 = viewMatrix * vector4f(aabbOriginX, offset, aabbOriginZ + aabbExtentZ, 1.0f);
		vector4f v4 = viewMatrix * vector4f(aabbOriginX + aabbExtentX, offset, aabbOriginZ + aabbExtentZ, 1.0f);

		const vertex vertices[6] = {
				{v1[0], v1[1], v1[2], umin, vmax},
				{v3[0], v3[1], v3[2], umin, vmin},
				{v2[0], v2[1], v2[2], umax, vmax},

				{v2[0], v2[1], v2[2], umax, vmax},
				{v3[0], v3[1], v3[2], umin, vmin},
				{v4[0], v4[1], v4[2], umax, vmin}};


		[[game dynamicNode] addVertices:vertices count:6];

		[currentCamera pop];
	}

	myBlendColor(1.0, 1.0, 1.0, 0.4);

	[super renderNode];
}

- (void)dealloc
{
	[data release];

	[super dealloc];
}

@end
