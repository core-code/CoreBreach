//
//  UpgradeHandler.h
//  CoreBreach
//
//  Created by CoreCode on 08.09.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "CoreBreach.h"


@interface UpgradeHandler : NSObject
{}

+ (void)getCosts:(NSArray **)costs upgrades:(NSArray **)upgrades values:(NSArray **)values name:(NSString **)name forMode:(shipAttributeEnum)mode;
+ (float)currentUpgradedValue:(shipAttributeEnum)mode forShip:(uint8_t)ship;
@end