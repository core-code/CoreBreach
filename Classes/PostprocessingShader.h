//
//  PostprocessingShader.h
//  Core3D
//
//  Created by CoreCode on 03.01.08.
//  Copyright 2008 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//


@interface PostprocessingShader : SceneNode
{
//	GLuint fbo, colorTexture, depthTexture;
	Shader *shader;
	FBO *fbo;
	GLuint w, h;

	GLuint grayEnabledLoc, radialblurEnabledLoc, //radialblurSamplesLoc,
			grayIntensityLoc, radialBlurLoc, radialBrightLoc, thermalEnabledLoc, glassEnabledLoc, thermalIntensityLoc, glassIntensityLoc;

	BOOL grayEnabled, radialblurEnabled, thermalEnabled, glassEnabled;
	int radialblurSamples;
	float grayIntensity, radialBlur, radialBright, thermalIntensity, glassIntensity;

	BOOL updatesChildren;

	Texture *glassTexture, *nitroTexture, *bombTexture;
}

@property (nonatomic, assign) BOOL updatesChildren;
@property (nonatomic, assign) BOOL glassEnabled;
@property (nonatomic, assign) BOOL thermalEnabled;
@property (nonatomic, assign) BOOL grayEnabled;
@property (nonatomic, assign) BOOL radialblurEnabled;
@property (nonatomic, assign) int radialblurSamples;
@property (nonatomic, assign) float grayIntensity;
@property (nonatomic, assign) float radialBlur;
@property (nonatomic, assign) float radialBright;
@property (nonatomic, assign) float thermalIntensity;
@property (nonatomic, assign) float glassIntensity;

@end
