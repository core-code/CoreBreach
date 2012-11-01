//
//  PlasmaShader.h
//  Core3D
//
//  Created by CoreCode on 4.4.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//  Copyright (C) 2010 Apple Inc. Contains Apple Inc. Sample code
//


@interface PlasmaShader : SceneNode
{
	Shader *shader;
	float offset;
	GLuint paletteID, patternID;
	GLint offsetPos;
}

@end
