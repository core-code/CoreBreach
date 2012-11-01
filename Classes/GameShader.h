//
//  GameShader.h
//  Core3D
//
//  Created by CoreCode on 29.12.07.
//  Copyright 2007 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//


@interface GameShader : SceneNode
{
	BOOL shadowsEnabled, lightsEnabled, specularEnabled, additiveEnabled;

	Shader *shader, *shaderCore;
	NSMutableArray *shadowRenderpasses;

	uint8_t lightNum1, lightNum2;
	GLint smPos, smPosCore, coreIntensityPos;
}

- (id)initWithLighting:(BOOL)enableLighting enableSpecular:(BOOL)enableSpecular enableShadows:(BOOL)enableShadows lightNum1:(uint8_t)lightNum1 lightNum2:(uint8_t)lightNum2 isAdditive:(BOOL)additive;

@property (nonatomic, retain) NSMutableArray *shadowRenderpasses;
@end
