//
//  Ghostship.h
//  Core3D
//
//  Created by CoreCode on 25.12.10.
//  Copyright 2008 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//


@interface Ghostship : Mesh
{
	NSData *data;
	uint8_t shipNum;
	float umin, umax, vmin, vmax;
}

@property (nonatomic, retain) NSData *data;
@property (nonatomic, assign) uint8_t shipNum;

@end
