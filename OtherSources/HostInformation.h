//
//  HostInformation.h
//
//  Created by CoreCode on 16.01.05.
//  Copyright 2007 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt



@interface HostInformation : NSObject
{
}

+ (NSString *)macAddress;

#ifdef TARGET_OS_MAC
+ (NSString *)ipAddress:(bool)ipv6;
//+ (NSString *)ipName;
//+ (NSString *)machineType;

+ (NSString *)nameForDevice:(NSInteger)deviceNumber;
+ (NSString *)bsdPathForVolume:(NSString *)volume;

+ (BOOL)runsOnBattery;
+ (BOOL)hasBattery;
#endif
@end
