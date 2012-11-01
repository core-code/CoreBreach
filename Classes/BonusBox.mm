//
//  BonusBox.m
//  CoreBreach
//
//  Created by CoreCode on 24.03.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "Game.h"


@implementation BonusBox

@synthesize shadowOrientation, isSpeedbox;

- (id)init
{
	if ((self = [super init]))
	{
	}
	return self;
}

- (void)setShadowOrientation:(vector3f)_so
{
	shadowOrientation = _so;

	vector3f shadowOrientationWithoutSlope = vector3f(shadowOrientation[0], 0, shadowOrientation[2]);
	slopeAngle = cml::deg(unsigned_angle(shadowOrientationWithoutSlope, shadowOrientation));
	turnAngle = cml::deg(signed_angle(vector3f(1.0f, 0.0f, 0.0f), shadowOrientationWithoutSlope, vector3f(0.0f, 1.0f, 0.0f)));
	if (shadowOrientation[1] < 0.0f)
		slopeAngle = -slopeAngle;
}

- (void)renderNode
{
	if (currentRenderPass.settings == kMainRenderPass && wasVisible && (length(position - [currentCamera aggregatePosition]) < BLOB_CONTRIBUTION_CULLING_DISTANCE))
	{
		[currentCamera push];
		[currentCamera identity];
		[self transform];
		[currentCamera rotate:vector3f(0.0f, -rotation[1] + turnAngle, slopeAngle) withConfig:kXYZRotation];

		matrix44f_c viewMatrix = [currentCamera modelViewMatrix];

		struct octree_node *n1 = (struct octree_node *) _NODE_NUM([[children objectAtIndex:0] octree], 0);
		const float aabbOriginX = n1->aabbOriginX * 1.1f;
		const float aabbExtentX = n1->aabbExtentX * 1.1f;
		const float aabbOriginZ = n1->aabbOriginZ * 1.1f;
		const float aabbExtentZ = n1->aabbExtentZ * 1.1f;
		const float offset = -(Y_OFFSET + Y_EXTRABB_OFFSET);

		vector4f v1 = viewMatrix * vector4f(aabbOriginX, offset, aabbOriginZ, 1.0f);
		vector4f v2 = viewMatrix * vector4f(aabbOriginX + aabbExtentX, offset, aabbOriginZ, 1.0f);
		vector4f v3 = viewMatrix * vector4f(aabbOriginX, offset, aabbOriginZ + aabbExtentZ, 1.0f);

		vector4f v4 = viewMatrix * vector4f(aabbOriginX + aabbExtentX, offset, aabbOriginZ + aabbExtentZ, 1.0f);

		const vertex vertices[6] = {
				{v1[0], v1[1], v1[2], 0.5f, 0.5f},
				{v3[0], v3[1], v3[2], 0.5f, 0.0f},
				{v2[0], v2[1], v2[2], 1.0f, 0.5f},

				{v2[0], v2[1], v2[2], 1.0f, 0.5f},
				{v3[0], v3[1], v3[2], 0.5f, 0.0f},
				{v4[0], v4[1], v4[2], 1.0f, 0.0f}};



		[[game dynamicNode] addVertices:vertices count:6];

		[currentCamera pop];
	}

	[super renderNode];
}

- (void)render
{
	[super render];

	if (currentRenderPass.settings == kMainRenderPass)
		wasVisible = [[children objectAtIndex:0] visibleNodeStackTop];
}

- (void)dealloc
{
	[super dealloc];
}
@end
