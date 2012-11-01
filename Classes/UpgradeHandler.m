//
//  UpgradeHandler.m
//  CoreBreach
//
//  Created by CoreCode on 08.09.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "UpgradeHandler.h"


@implementation UpgradeHandler

+ (void)getCosts:(NSArray **)costs upgrades:(NSArray **)upgrades values:(NSArray **)values name:(NSString **)name forMode:(shipAttributeEnum)mode
{
	if (mode == kHandling)
	{
		*upgrades = kHandlingUpgrades;
		*costs = kHandlingUpgradesCosts;
		*values = kShipHandling;
		*name = @"Handling";
	}
	else if (mode == kTopSpeed)
	{
		*upgrades = kTopSpeedUpgrades;
		*costs = kTopSpeedUpgradesCosts;
		*name = @"TopSpeed";
		*values = kShipTopspeed;
	}
	else if (mode == kAcceleration)
	{
		*costs = kAccelUpgradesCosts;
		*upgrades = kAccelUpgrades;
		*name = @"Acceleration";
		*values = kShipAcceleration;
	}
}

+ (float)currentUpgradedValue:(shipAttributeEnum)mode forShip:(uint8_t)ship
{
	NSArray *costs, *upgrades, *values;
	NSString *name;
	[UpgradeHandler getCosts:&costs upgrades:&upgrades values:&values name:&name forMode:mode];

	float value = [[values objectAtIndex:ship] floatValue];

	for (int i = 1; i <= $defaulti($stringf(kShipIAUpgrades, (long)ship, name)); i++)
		value += [[upgrades objectAtIndex:i - 1] floatValue];

	return value;
}
@end