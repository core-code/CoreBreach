//
//  AnimatedTextureShader.m
//  Core3D
//
//  Created by CoreCode on 29.12.07.
//  Copyright 2007 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "Game.h"


@implementation AnimatedTextureShader

- (id)init
{
	if ((self = [super init]))
	{
		shader = [Shader newShaderNamed:@"phong_animated" withTexcoordsBound:YES andNormalsBound:YES];

		[shader bind];
		replacementColorPos = glGetUniformLocation(shader.shaderName, "replacementColor");
	}

	return self;
}

- (void)render // override render instead of implementing renderNode
{
	if ([currentRenderPass settings] & kRenderPassSetMaterial)
	{
		[shader bind];

		vector4f col;

		if (globalInfo.frame % 10 > 5)
			col = vector4f(1.0f, 0.1f, 0.1f, 1.0f);
		else
			col = vector4f(1.0f, 1.0f, 0.4f, 1.0f);

		if (col != savedColor)
		{
			glUniform4fv(replacementColorPos, 1, col.data());
			savedColor = col;
		}
	}

	[children makeObjectsPerformSelector:@selector(render)];
}

- (void)dealloc
{
	[shader release];

	[super dealloc];
}

@end