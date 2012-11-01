//
//  Highscores.h
//  CoreBreach
//
//  Created by CoreCode on 11.01.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//


@interface Highscores : NSObject
#ifndef __COCOTRON__
		<NSXMLParserDelegate>
#endif
{
	NSMutableArray *highscores;
}

+ (NSString *)sha1:(NSString *)input;

- (void)storeHighscore:(float)time forMode:(int)mode forNickname:(NSString *)nickname onTrack:(uint32_t)track withShip:(uint8_t)ship;
- (void)sendHighscore:(float)time forMode:(int)mode forNickname:(NSString *)nickname onTrack:(uint32_t)track withShip:(uint8_t)ship withData:(NSData *)_data;
- (NSArray *)getHighscoresForMode:(int)mode forNickname:(NSString *)nickname onTrack:(uint32_t)track;

@end
