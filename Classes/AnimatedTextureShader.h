//
//  AnimatedTextureShader.h
//  Core3D
//
//  Created by CoreCode on 29.12.07.
//  Copyright 2007 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//


@interface AnimatedTextureShader : SceneNode
{
	Shader *shader;
	GLuint replacementColorPos;
	vector4f savedColor;
}

@end