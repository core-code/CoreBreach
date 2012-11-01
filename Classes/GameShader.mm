//
//  GameShader.m
//  Core3D
//
//  Created by CoreCode on 29.12.07.
//  Copyright 2007 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "Game.h"
#import "GameShader.h"
#import "Powerup.h"

//extern GLfloat shadowMatrix[16];

@implementation GameShader

@synthesize shadowRenderpasses;


- (id)initWithLighting:(BOOL)enableLighting enableSpecular:(BOOL)enableSpecular enableShadows:(BOOL)enableShadows lightNum1:(uint8_t)_lightNum1 lightNum2:(uint8_t)_lightNum2 isAdditive:(BOOL)additive
{
	if ((self = [super init]))
	{
		shadowsEnabled = enableShadows;
		lightsEnabled = enableLighting;
		specularEnabled = enableSpecular;
		additiveEnabled = additive;
		lightNum1 = _lightNum1;
		lightNum2 = _lightNum2;

		shadowRenderpasses = [[NSMutableArray alloc] init];
		NSMutableString *defines = [NSMutableString string];

		if (globalSettings.shadowMode && enableShadows)
		{
			//	if (globalSettings.shadowMode == kShipOnly && !IS_MULTI)
			[defines appendString:@"#define SHADOW\n#define S_1\n"];
			//	else
			//		[defines appendString:@"#define SHADOW\n#define S_2\n"];
		}

		if (globalSettings.shadowFiltering == kPCF4)
			[defines appendString:@"#define PCF_4\n"];
		if (globalSettings.shadowFiltering == kPCF16)
			[defines appendString:@"#define PCF_16\n"];
		if (globalSettings.shadowFiltering == kPCSS)
			[defines appendString:@"#define PCSS\n"];
		if (additive)
			[defines appendString:@"#define ADDITIVE_LIGHT\n"];
		[defines appendString:@"#define TEXTURING\n"];

		if (enableLighting) [defines appendString:@"#define LIGHT\n"];
		if (!enableSpecular) [defines appendString:@"#define NO_SPECULAR\n"];

		shader = [Shader newShaderNamed:@"phong_shadow" withDefines:defines withTexcoordsBound:YES andNormalsBound:YES];

		[defines appendString:@"#define COREMODE\n"];
		shaderCore = [Shader newShaderNamed:@"phong_shadow" withDefines:defines withTexcoordsBound:YES andNormalsBound:YES];


		for (int i = 0; i < 2; i++)
		{
			Shader *s = (i == 0) ? shader : shaderCore;

			[s bind];


			int values[4] = {1, 2};
			glUniform1iv(glGetUniformLocation(s.shaderName, "shadowMap"), 2, values);


			if (!i)
			{
				smPos = glGetUniformLocation(s.shaderName, "shadowMatrix");
			}
			else
			{
				smPosCore = glGetUniformLocation(s.shaderName, "shadowMatrix");
				coreIntensityPos = glGetUniformLocation(s.shaderName, "coreIntensity");
			}
		}
	}

	return self;
}

- (void)render // override render instead of implementing renderNode
{
	if (![children count])
		return;

	if ([currentRenderPass settings] & kRenderPassSetMaterial)
	{
		Shader *s = (game.ship.coreModeActive) ? shaderCore : shader;

		[s bind];
		if (lightsEnabled)
		{
			globalMaterial.activeLightIndices[0] = lightNum1;
			globalMaterial.activeLightIndices[1] = lightNum2;
		}

		if (globalSettings.shadowMode && shadowsEnabled)
		{
			int i = 0;

			//	if ((globalSettings.shadowMode == kShipOnly) && !IS_MULTI && ([shadowRenderpasses count] != 1)) fatal("Error: shadowMode == 1 needs one shadowMap");
			//	if ((globalSettings.shadowMode != kShipOnly) && ([shadowRenderpasses count] != 2)) fatal("Error: shadowMode > 1 needs two shadowMaps");


			matrix44f_c finalMatrix[2];
			matrix44f_c inverseView = inverse([currentCamera viewMatrix]);
			matrix44f_c m;
			matrix_scale(m, 0.5f, 0.5f, 0.5f);
			matrix44f_c bias = cml::identity_transform<4, 4>();
			matrix_set_translation(bias, 0.5f, 0.5f, 0.5f);
			bias *= m;

			for (RenderPass *shadowPass in shadowRenderpasses)
			{

				assert([[(FBO *) [shadowPass renderTarget] depthTexture] permanentTextureUnit] == i + 1);
				//				glActiveTexture(GL_TEXTURE1+i);
				//				[[(FBO *)[shadowPass renderTarget] depthTexture] bind];


				finalMatrix[i] = bias * [[shadowPass camera] projectionMatrix];
				finalMatrix[i] *= [[shadowPass camera] modelViewMatrix];
				finalMatrix[i] *= inverseView;

				i++;

				glUniformMatrix4fv((s == shaderCore) ? smPosCore : smPos, i, GL_FALSE, finalMatrix[0].data());
			}


			//			glActiveTexture(GL_TEXTURE0);
		}

		if (s == shaderCore)
			glUniform1f(coreIntensityPos, game.ship.coreModeIntensity);


		[children makeObjectsPerformSelector:@selector(render)];


		if (lightsEnabled)
		{
			globalMaterial.activeLightIndices[0] = 0;
			globalMaterial.activeLightIndices[1] = -1;
		}
	}
	else
		[children makeObjectsPerformSelector:@selector(render)];
}

- (void)dealloc
{
	[shadowRenderpasses release];
	[shader release];
	[shaderCore release];

	[super dealloc];
}
@end
