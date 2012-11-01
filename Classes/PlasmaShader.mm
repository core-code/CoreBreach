//
//  PlasmaShader.m
//  Core3D
//
//  Created by CoreCode on 4.4.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//  Copyright (C) 2010 Apple Inc. Contains Apple Inc. Sample code
//

#import "Game.h"
#import "PlasmaShader.h"


#undef glBindTexture
#undef glEnable
#undef glDisable

@implementation PlasmaShader

- (id)init
{
	if ((self = [super init]))
	{
#ifndef TARGET_OS_IPHONE
        shader = [Shader newShaderNamed:@"plasma" withTexcoordsBound:YES andNormalsBound:YES];


		[shader bind];


		offsetPos = glGetUniformLocation(shader.shaderName, "offset");

		{
			GLfloat palette[256][3];
			/* Create the palette */
			{
				int i;

				for (i=0; i< 256;i++)
				{
					float x = i;
					palette[i][0] = 1.0f - sin(3.1415 * x / 256.0);
					palette[i][1] = (128.0f + 128.0f * sin(3.1415 * x / 128.0))/384.0f;
					palette[i][2] = sin(3.1415 * x / 256.0);
				}
			}
			glActiveTexture(GL_TEXTURE5);
			glGenTextures(1, &paletteID);
			glBindTexture(GL_TEXTURE_1D, paletteID);
			glTexImage1D(GL_TEXTURE_1D, 0, GL_RGBA, 256, 0, GL_RGB, GL_FLOAT, palette);
			glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
			glTexParameteri(GL_TEXTURE_1D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

			/* Create the pattern texture, use symmetry to get rid of the seams */
			{
				int i,j;
				GLfloat *pattern = (GLfloat *) malloc(sizeof(GLfloat) * 128*128);
				for (i = 0; i < 64; i++)
				{
					float y = (float)i;
					for (j=0; j< 64; j++)
					{
						float x = (float) j;
						float f = 0.25*(sin(x/16.0) + sin(y/16.0) + sin((x+y)/16.0) + sin(sqrtf(x*x+y*y)/8.0));
						pattern[i*128+j] = f;
						pattern[i*128+(127-j)] = f;
						pattern[(127-i)*128+j] = f;
						pattern[(127-i)*128+(127-j)] = f;
					}
				}
				glActiveTexture(GL_TEXTURE6);
				glGenTextures(1, &patternID);
				glBindTexture(GL_TEXTURE_2D, patternID);
         
				//glTexImage2D(GL_TEXTURE_2D, 0, GL_R32F, 128, 128, 0, GL_RED, GL_FLOAT, pattern);
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 128, 128, 0, GL_LUMINANCE, GL_FLOAT, pattern);


				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
				free(pattern);
			}
		}

		glActiveTexture(GL_TEXTURE0);

		/* Set the texture units for the samplers */
		glUniform1i(glGetUniformLocation(shader.shaderName, "pattern"), 6);
		glUniform1i(glGetUniformLocation(shader.shaderName, "palette"), 5);
#endif
	}

	return self;
}

- (void)render // override render instead of implementing renderNode
{
#ifndef TARGET_OS_IPHONE
	if ([currentRenderPass settings] & kRenderPassSetMaterial)
	{
		[shader bind];

		myPolygonOffset(-10.0f, -10.0f);
		glEnable(GL_POLYGON_OFFSET_FILL);

//		glActiveTexture(GL_TEXTURE5);
//		glBindTexture(GL_TEXTURE_1D, paletteID);
//		glActiveTexture(GL_TEXTURE6);
//		glBindTexture(GL_TEXTURE_2D, patternID);

		glUniform1f(offsetPos, offset);
		offset = offset + (1.0/256.0);
		if (offset > 1.0)
			offset = 0;


		[children makeObjectsPerformSelector:@selector(render)];


		glDisable(GL_POLYGON_OFFSET_FILL);
//		glActiveTexture(GL_TEXTURE0);
	}
	else
		[children makeObjectsPerformSelector:@selector(render)];
#endif
}

#ifndef TARGET_OS_IPHONE
- (void)dealloc
{
	[shader release];

	glDeleteTextures(1, &patternID);
	glDeleteTextures(1, &paletteID);

	[super dealloc];
}
#endif

@end
