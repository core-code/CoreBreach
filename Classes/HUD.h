//
//  HUD.h
//  Core3D
//
//  Created by CoreCode on 28.04.08.
//  Copyright 2008 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "CoreBreach.h"

#include "freetype-gl.h"
#include "font-manager.h"
#include "vertex-buffer.h"
#include "markup.h"


@class Playership;
@class Game;

#define kBufferSize 64

@interface HUD : SceneNode
{
	NSArray *countdownMeshes;
	Shader *pointShader, *colorAttributeTextureShader;
	GLint pointSizePos;

	NSDate *now;
	uint8_t corebreaches, cleanrounds, leadrounds, difficulty;

	BOOL done;
	int enemyNamePref;

	int heightAwardHalf, widthAward;
	Playership *ship;
	NSString *fastestLap;
	NSMutableArray *timeArray;
	uint8_t fontsize, endSieg;
	int8_t runde;
	double endTime, startTime;

	char buf[kBufferSize];

	GLuint minimapTexname;

	vector2f theirCenter;
	vector2f ourCenter;
	float radiusFactor;

	NSString *currentAward;
	NSDate *currentAwardDate;

	NSString *currentMessage;
	NSDate *currentMessageDate;
	BOOL currentMessageUrgent;

	NSString *currentMusic;
	NSDate *currentMusicDate;

	NSMutableArray *weaponMessages;

	vertex_buffer_t *imageBuffer;
	texture_atlas_t *imageAtlas;

	NSArray *weaponTextureNodes;
	BatchingTextureNode *musicNotificationNode;
	BatchingTextureNode *awardNotificationNode;
#ifdef TARGET_OS_IPHONE
	BatchingTextureNode *pauseNode, *steerLeftNode, *steerRightNode, *accelerateNode, *shootNode, *cameraNode;
	BatchingTextureNode *touchCenter, *touchLeft, *touchRight, *touchStretchLeft, *touchStretchRight;
	float fieldWidth, stretchWidth;
#endif

	VBO *minimapVBO;

	texture_font_t *technoFont;
	texture_font_t *plainFont;
	vertex_buffer_t *vbuffer;
	font_manager_t *manager;
}

@property (readonly, nonatomic) NSMutableArray *timeArray;
@property (readonly, nonatomic) uint8_t endSieg;
@property (readonly, nonatomic) uint8_t corebreaches;
@property (readonly, nonatomic) uint8_t cleanrounds;
@property (readonly, nonatomic) uint8_t leadrounds;
@property (readonly, nonatomic) uint8_t difficulty;

- (void)addAward:(awardEnum)award;
- (void)addMessage:(NSString *)message urgent:(BOOL)urgent;
- (void)addWeaponMessage:(NSString *)message;
- (void)removeAllMessages;
- (void)addMusic:(NSString *)music;
- (GLuint)makeMinimap:(int)size;
- (id)initWithPlayership:(Playership *)_ship;
- (float)timeInCurrentRound;

@end
