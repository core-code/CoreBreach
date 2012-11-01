//
//  BonusBox.h
//  CoreBreach
//
//  Created by CoreCode on 24.03.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//


@interface BonusBox : CollideableSceneNode
{
	BOOL isSpeedbox;
	BOOL wasVisible;
	vector3f shadowOrientation;
	float slopeAngle, turnAngle;
}

@property (assign, nonatomic) vector3f shadowOrientation;
@property (assign, nonatomic) BOOL isSpeedbox;

@end
