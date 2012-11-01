//
//  PostprocessingShader.m
//  Core3D
//
//  Created by CoreCode on 03.01.08.
//  Copyright 2008 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//


#import "Game.h"


#define disableFBO 1

@implementation PostprocessingShader

@synthesize grayEnabled, radialblurEnabled, radialblurSamples, grayIntensity, radialBlur, radialBright, thermalEnabled, glassEnabled, thermalIntensity, glassIntensity, updatesChildren;

- (id)init
{
	if ((self = [super init]))
	{
		shader = [Shader newShaderNamed:@"postprocessing" withTexcoordsBound:YES andNormalsBound:NO];

		[shader bind];

		glUniform1i(glGetUniformLocation(shader.shaderName, "colorTexture"), 0);
//		glUniform1i(glGetUniformLocation(shader.shaderName, "depthTexture"), 1);

		thermalEnabledLoc = glGetUniformLocation(shader.shaderName, "thermalEnabled");
		glassEnabledLoc = glGetUniformLocation(shader.shaderName, "glassEnabled");
		grayEnabledLoc = glGetUniformLocation(shader.shaderName, "grayEnabled");
		radialblurEnabledLoc = glGetUniformLocation(shader.shaderName, "radialblurEnabled");
//        radialblurSamplesLoc = glGetUniformLocation(shader.shaderName, "radialblurSamples");
		grayIntensityLoc = glGetUniformLocation(shader.shaderName, "grayIntensity");
		radialBlurLoc = glGetUniformLocation(shader.shaderName, "radialBlur");
		radialBrightLoc = glGetUniformLocation(shader.shaderName, "radialBright");
		thermalIntensityLoc = glGetUniformLocation(shader.shaderName, "thermalIntensity");
		glassIntensityLoc = glGetUniformLocation(shader.shaderName, "glassIntensity");



//		if (!disableFBO)
		fbo = [[FBO alloc] initWithWidthMultiplier:1.0f andHeightMultiplier:IS_MULTI ? 0.5f : 1.0f];


		nitroTexture = [Texture newTextureNamed:kEffectSpeedupTexture];
		[nitroTexture load];

		glassTexture = [Texture newTextureNamed:kEffectDamageTexture];
		[glassTexture load];

		bombTexture = [Texture newTextureNamed:kEffectBombTexture];
		[bombTexture load];
	}

	return self;
}

- (void)update
{
	[self updateNode];

	if (updatesChildren)
		[children makeObjectsPerformSelector:@selector(update)];
}

- (void)reshapeNode:(CGSize)size
{
	w = (float) size.width;
	h = (float) size.height / (IS_MULTI ? 2.0 : 1.0);

	[fbo reshape:size];



	//vector2f screen = vector2f(w, h);

	[shader bind];
	glUniform2fv(glGetUniformLocation(shader.shaderName, "pixelSize"), 1, vector2f(1.0 / w, 1.0 / h).data());
}

- (void)render // override render instead of implementing renderNode
{
	if (!game.postProcessingLevel ||
			(!grayEnabled && !radialblurEnabled && !glassEnabled && !thermalEnabled))
	{

		[children makeObjectsPerformSelector:@selector(render)];
		if (!radialblurEnabled && !thermalEnabled && !glassEnabled)
			return;

		myEnableBlendParticleCullDepthtestDepthwrite(YES, NO, YES, NO, YES);
		myBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		[[scene textureOnlyShader] bind];

		Texture *t = nil;
		float intensity = 0.0;

		if (radialblurEnabled)
		{
			t = nitroTexture;
			intensity = (radialBlur * 6.0 / M_PI);
		}
		else if (thermalEnabled)
		{
			t = bombTexture;
			intensity = thermalIntensity;
		}
		else if (glassEnabled)
		{
			t = glassTexture;
			intensity = glassIntensity;
		}
		[t bind];

		globalMaterial.color = vector4f(1.0f, 1.0f, 1.0f, intensity);

		if (radialblurEnabled)
			DrawQuadWithCoordinatesRotation(0 - w / 3.0, 0 - h / 3.0,
					w + w / 3.0, 0 - h / 3.0,
					w + w / 3.0, h + h / 3.0,
					0 - w / 3.0, h + h / 3.0, (globalInfo.frame * 3 % 360));
		else if (thermalEnabled)
		{
			float rx = cml::random_real(0.00f, 10.0f);
			float ry = cml::random_real(0.00f, 10.0f);

			DrawQuadWithCoordinates(-10 + rx, -10 + ry,
					w + rx, -10 + ry,
					w + rx, h + ry,
					0 + rx, h + ry);
		}
		else
			DrawCenteredScreenQuad(w, h);

		/*PSEUDO_DRAW_CALL*/
	}
	else
	{
		if (!disableFBO)
		{
			[fbo bind];
			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		}


		[children makeObjectsPerformSelector:@selector(render)];

		if (!disableFBO)
			[fbo unbind];


		myEnableBlendParticleCullDepthtestDepthwrite(NO, NO, YES, !disableFBO, YES);


		[shader bind];

		//glActiveTexture(GL_TEXTURE0);
		[fbo.colorTexture bind];


		if (disableFBO)
			glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, [currentRenderPass frame].origin.y, w, h);


//		glActiveTexture(GL_TEXTURE1);
//        [fbo.depthTexture bind]; // remember we bound depthTexture in the shader to one
//
//		if (disableFBO)
//			glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, 0, w, h); // my driver hates that line
//
//		glActiveTexture(GL_TEXTURE0);

		glUniform1i(thermalEnabledLoc, thermalEnabled);
		glUniform1i(glassEnabledLoc, glassEnabled);
		glUniform1i(grayEnabledLoc, grayEnabled);
		glUniform1i(radialblurEnabledLoc, radialblurEnabled);
//        glUniform1i(radialblurSamplesLoc, radialblurSamples);
		glUniform1f(grayIntensityLoc, grayIntensity);
		glUniform1f(radialBlurLoc, radialBlur);
		glUniform1f(radialBrightLoc, radialBright);
		glUniform1f(thermalIntensityLoc, thermalIntensity);
		glUniform1f(glassIntensityLoc, glassIntensity);
//        glUniform1f(glassFactorLoc, 5.0f);


		DrawCenteredScreenQuad(w, h);

		/*PSEUDO_DRAW_CALL*/
	}
}

- (void)dealloc
{
	[shader release];

//  if (!disableFBO)
	[fbo release];

	[bombTexture release];
	[glassTexture release];
	[nitroTexture release];

	[super dealloc];
}
@end
