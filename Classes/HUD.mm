//
//  HUD.m
//  Core3D
//
//  Created by CoreCode on 28.04.08.
//  Copyright 2008 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "Game.h"
#import "Highscores.h"


uint64_t micro;

int w, h;
void add_text(vertex_buffer_t *buffer, texture_font_t *font, const char *text, vec2 pen, vec3 fg_color_1, vec3 fg_color_2);


#define kMusicNotDuration 3.0
#define kAwardNotDuration 1.5


#ifdef IPAD
#define BOTTOMOFFSET 96
#elif defined(IPHONE)
#define BOTTOMOFFSET 64
#else
#define BOTTOMOFFSET 0
#endif

#undef glBindTexture

@implementation HUD

@synthesize timeArray, endSieg, corebreaches, leadrounds, cleanrounds, difficulty;

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithPlayership:(Playership *)_ship
{
	if ((self = [super init]))
	{
		colorAttributeTextureShader = [Shader newShaderNamed:@"texture" withDefines:@"#define ATTRIBUTECOLOR 1\n" withTexcoordsBound:YES andNormalsBound:YES];
		pointShader = [Shader newShaderNamed:@"pointsprite" withDefines:@"#define COLOR 1\n" withTexcoordsBound:NO andNormalsBound:NO];

		[pointShader bind];
		glUniform1i(glGetUniformLocation(pointShader.shaderName, "pointspriteTexture"), 0);
		glUniform1f(glGetUniformLocation(pointShader.shaderName, "size"), 1.0);

		pointSizePos = glGetUniformLocation(pointShader.shaderName, "pointSize");


		difficulty = game.difficulty;

		endSieg = 222;
		//		enabled = FALSE;
		assert(_ship);
		ship = _ship;
		[ship retain];
		weaponMessages = [[NSMutableArray alloc] init];
		timeArray = [[NSMutableArray alloc] init];
		countdownMeshes = [[NSArray alloc] initWithObjects:
				                                   [[[Mesh alloc] initWithOctreeNamed:@"item_countdown_3"] autorelease],
				                                   [[[Mesh alloc] initWithOctreeNamed:@"item_countdown_2"] autorelease],
				                                   [[[Mesh alloc] initWithOctreeNamed:@"item_countdown_1"] autorelease],
				                                   [[[Mesh alloc] initWithOctreeNamed:@"item_countdown_GO"] autorelease], nil];
		for (Mesh *m in countdownMeshes)
		{
			[m setDontDepthtest:YES];
			[m setColor:vector4f(0.82f, 0.90f, 0.30f, 1.0f)];
			[m setShininess:10.0f];
		}
		fontsize = 45;
		[self removeAllMessages];
		currentAward = [[NSString alloc] initWithString:@"Die Schönheit dieser Erden - Sie wird rauchend Asche werden"];
		currentAwardDate = [[NSDate distantPast] retain];
		currentMusic = [[NSString alloc] initWithString:@"So wie ich die Sache sehe ist die Intelligenz bereits ausgerottet und es leben nur noch die Idioten."];
		currentMusicDate = [[NSDate distantPast] retain];
		[ship addObserver:self forKeyPath:@"round" options:NSKeyValueObservingOptionNew context:NULL];
		runde = -1;

		fastestLap = [$stringf(@"Best. %.1f", $defaultf($stringf(@"FastestTimeAttackTrack%iTime", game.highscoreTrackNum))) retain];

		enemyNamePref = $defaulti(kDisplayEnemyNamesKey);


		[now release];
		now = [[NSDate date] retain];



		imageBuffer = vertex_buffer_new("0g3f:1g2f");
		imageAtlas = texture_atlas_new(512, 512, 4);

		musicNotificationNode = [[BatchingTextureNode alloc] initWithVertexBuffer:imageBuffer andTextureAtlas:imageAtlas andTextureNamed:kOverlayNotificationMusicTexture];
		awardNotificationNode = [[BatchingTextureNode alloc] initWithVertexBuffer:imageBuffer andTextureAtlas:imageAtlas andTextureNamed:kOverlayNotificationAwardTexture];

		NSMutableArray *tmp = $emarray;
		for (NSString *n in kWeaponNames)
		{
			if ([n length])
			{
				BatchingTextureNode *node = [[BatchingTextureNode alloc] initWithVertexBuffer:imageBuffer
				                                                              andTextureAtlas:imageAtlas
							                                                  andTextureNamed:[n stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
				[node setPosition:vector3f(6, BOTTOMOFFSET + 6, 0)];
				[node setSize:vector2f(64, 64)];
				[tmp addObject:node];
				[node release];
			}
		}
		weaponTextureNodes = [[NSArray alloc] initWithArray:tmp];

#ifdef TARGET_OS_IPHONE
		pauseNode = [[BatchingTextureNode alloc] initWithVertexBuffer:imageBuffer andTextureAtlas:imageAtlas andTextureNamed:@"icon_pause"];
		[pauseNode setSize:vector2f(topButtonSize, topButtonSize)];

		cameraNode = [[BatchingTextureNode alloc] initWithVertexBuffer:imageBuffer andTextureAtlas:imageAtlas andTextureNamed:@"icon_camera"];
		[cameraNode setSize:vector2f(topButtonSize, topButtonSize)];



		if (STEERING_BUTTONS)
		{

			steerLeftNode = [[BatchingTextureNode alloc] initWithVertexBuffer:imageBuffer andTextureAtlas:imageAtlas andTextureNamed:@"icon_steerleft"];
			[steerLeftNode setSize:vector2f(controlButtonSize, controlButtonSize)];

			steerRightNode = [[BatchingTextureNode alloc] initWithVertexBuffer:imageBuffer andTextureAtlas:imageAtlas andTextureNamed:@"icon_steerright"];
			[steerRightNode setSize:vector2f(controlButtonSize, controlButtonSize)];
		}
		else if (STEERING_TOUCHPAD)
		{
			touchCenter = [[BatchingTextureNode alloc] initWithVertexBuffer:imageBuffer andTextureAtlas:imageAtlas andTextureNamed:@"iconTouchpadCenter"];
			[touchCenter setSize:vector2f(34, 64)];

			touchLeft = [[BatchingTextureNode alloc] initWithVertexBuffer:imageBuffer andTextureAtlas:imageAtlas andTextureNamed:@"iconTouchpadLeft"];
			[touchLeft setSize:vector2f(34, 64)];

			touchRight = [[BatchingTextureNode alloc] initWithVertexBuffer:imageBuffer andTextureAtlas:imageAtlas andTextureNamed:@"iconTouchpadRight"];
			[touchRight setSize:vector2f(34, 64)];

			const float fieldWidthMax = (IOS_SCREEN_WIDTH - 2 * 64);
			const float fieldWidthMin = (34 + 34 + 34 + 48 + 48);

			fieldWidth = fieldWidthMin + $defaultf(kIOSTouchfieldWidth) * (fieldWidthMax - fieldWidthMin);
			stretchWidth = (fieldWidth - 34 - 34 - 34) / 2.0;

			touchStretchLeft = [[BatchingTextureNode alloc] initWithVertexBuffer:imageBuffer andTextureAtlas:imageAtlas andTextureNamed:@"iconTouchpadLeftstretch"];
			[touchStretchLeft setSize:vector2f(stretchWidth, 64)];

			touchStretchRight = [[BatchingTextureNode alloc] initWithVertexBuffer:imageBuffer andTextureAtlas:imageAtlas andTextureNamed:@"iconTouchpadRightstretch"];
			[touchStretchRight setSize:vector2f(stretchWidth, 64)];
		}

		accelerateNode = [[BatchingTextureNode alloc] initWithVertexBuffer:imageBuffer andTextureAtlas:imageAtlas andTextureNamed:@"icon_accel"];
		[accelerateNode setSize:vector2f(controlButtonSize, controlButtonSize)];

		shootNode = [[BatchingTextureNode alloc] initWithVertexBuffer:imageBuffer andTextureAtlas:imageAtlas andTextureNamed:@"icon_deploy"];
		[shootNode setSize:vector2f(controlButtonSize, controlButtonSize)];
#endif

		texture_atlas_upload(imageAtlas);
		currentTexture = nil; // texture_atlas_upload binds another texture

		manager = font_manager_new(512, 512, 1);
		vbuffer = vertex_buffer_new("0g3f:1g2f:2g3f");

		{ // setup minimap VBO
			const GLushort indices[] = {0, 1, 3, 1, 2, 3};
			const GLshort vbuf[16] = {0, 0, 1, 0, 1, 1, 0, 1,
					0, 0, 0, 0, 0, 0, 0, 0}; // bogus vertex coordinates until reshape

			minimapVBO = [[VBO alloc] init];
			[minimapVBO setIndexBuffer:indices withSize:6 * sizeof(GLushort)];
			[minimapVBO setVertexBuffer:vbuf withSize:(8 + 8) * sizeof(GLshort)];

			[minimapVBO setVertexAttribPointer:(const GLvoid *) (sizeof(GLshort) * 8)
			                          forIndex:VERTEX_ARRAY withSize:2 withType:GL_SHORT shouldNormalize:GL_FALSE withStride:0];
			[minimapVBO setVertexAttribPointer:(const GLvoid *) 0
			                          forIndex:TEXTURE_COORD_ARRAY withSize:2 withType:GL_SHORT shouldNormalize:GL_FALSE withStride:0];
			[minimapVBO load];
		}
	}

	return self;
}

- (void)dealloc
{
	if (minimapTexname)
		glDeleteTextures(1, &minimapTexname);


	[musicNotificationNode release];
	[awardNotificationNode release];
	[weaponTextureNodes release];

	vertex_buffer_delete(imageBuffer);
	texture_atlas_delete(imageAtlas);
//    texture_font_delete(technoFont);
//    texture_font_delete(plainFont);
	vertex_buffer_delete(vbuffer);
	font_manager_delete(manager);


	[colorAttributeTextureShader release];
	[pointShader release];
	[now release];
	[weaponMessages release];
	[ship removeObserver:self forKeyPath:@"round"];
	[ship release];
	[currentAwardDate release];
	[currentAward release];
	[currentMusicDate release];
	[currentMusic release];
	[currentMessageDate release];
	[currentMessage release];
	[fastestLap release];
	[timeArray release];
	[countdownMeshes release];

	[minimapVBO release];

#ifdef TARGET_OS_IPHONE
	[pauseNode release];
	[steerLeftNode release];
	[steerRightNode release];
	[accelerateNode release];
	[shootNode release];
#endif


	[super dealloc];
}

- (void)reshapeNode:(CGSize)size
{
	float _w = size.width, _h = size.height;


	{ // update minimap
		if (minimapTexname)
			glDeleteTextures(1, &minimapTexname);
		minimapTexname = [self makeMinimap:((int) (_w / 40.0)) * 8];

		const int msize = ((int) (_w / 40.0)) * 8;
		const GLshort vbuf[16] = {0, 0, 1, 0, 1, 1, 0, 1,
				_w - msize, BOTTOMOFFSET, _w, BOTTOMOFFSET, _w, BOTTOMOFFSET + msize, _w - msize, BOTTOMOFFSET + msize};

		[minimapVBO setVertexBuffer:vbuf withSize:(8 + 8) * sizeof(GLshort)];
	}


	{ // update overlay bitmaps
		float clampedWidth = CLAMP(_w, 900, 2025);
		heightAwardHalf = clampedWidth / 14;
		widthAward = heightAwardHalf * 4;

		[musicNotificationNode setPosition:vector3f(_w - widthAward, MIN(_h / 2.0, _h - 70 - heightAwardHalf * 2), 0)];
		[musicNotificationNode setSize:vector2f(widthAward, heightAwardHalf * 2)];

		[awardNotificationNode setPosition:vector3f(0, MIN(_h / 2.0, _h - 110 - heightAwardHalf * 2), 0)];
		[awardNotificationNode setSize:vector2f(widthAward, heightAwardHalf * 2)];



#ifdef TARGET_OS_IPHONE
		[pauseNode setPosition:vector3f(_w / 2.0 + pauseOffset, _h - topButtonSize, 0)];
		[cameraNode setPosition:vector3f(_w / 2.0 + cameraOffset, _h - topButtonSize, 0)];


		if (STEERING_BUTTONS)
		{
			[steerLeftNode setPosition:vector3f(_w - controlButtonSize * 2, 0, 0)];
			[steerRightNode setPosition:vector3f(_w - controlButtonSize, 0, 0)];

			[accelerateNode setPosition:vector3f(0, 0, 0)];
			[shootNode setPosition:vector3f(controlButtonSize, 0, 0)];
		}
		else if (STEERING_ACCELEROMETER)
		{
			[shootNode setPosition:vector3f(0, 0, 0)];
			[accelerateNode setPosition:vector3f(_w - controlButtonSize, 0, 0)];
		}
		else if (STEERING_TOUCHPAD)
		{
			[accelerateNode setPosition:vector3f(0, 0, 0)];
			[shootNode setPosition:vector3f(controlButtonSize, 0, 0)];

			[touchRight setPosition:vector3f(_w - 34, 0, 0)];
			[touchStretchRight setPosition:vector3f(_w - 34 - stretchWidth, 0, 0)];
			[touchCenter setPosition:vector3f(_w - 34 - stretchWidth - 34, 0, 0)];
			[touchStretchLeft setPosition:vector3f(_w - 34 - stretchWidth - 34 - stretchWidth, 0, 0)];
			[touchLeft setPosition:vector3f(_w - 34 - stretchWidth - 34 - stretchWidth - 34, 0, 0)];
		}
#endif
	}


	{ // update fonts
		fontsize = (_w / 45);
		if (fontsize > 45) fontsize = 45;  // res 2025
		if (fontsize < 20) fontsize = 20; // res 900

//        texture_font_delete(technoFont);
//        texture_font_delete(plainFont);
//        font_manager_delete(manager)
//        manager = font_manager_new(512, 512, 3);

		if (technoFont)
			font_manager_delete_font(manager, technoFont);
		if (plainFont)
			font_manager_delete_font(manager, plainFont);

		texture_atlas_clear(manager->atlas);

		technoFont = font_manager_get_from_filename(manager, [[[NSBundle mainBundle] pathForResource:@"N-Gage" ofType:@"ttf"] UTF8String], fontsize);

#ifdef TARGET_OS_MAC
        plainFont = font_manager_get_from_filename(manager, "/System/Library/Fonts/LucidaGrande.ttc", fontsize / 1.7);
#else
		plainFont = font_manager_get_from_filename(manager, [[[NSBundle mainBundle] pathForResource:@"FreeSans" ofType:@"ttf"] UTF8String], fontsize / 1.7);
#endif


		int m;
		m = texture_font_load_glyphs(plainFont,
				L" -!'*_[]().01256"
		L"ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]"
		L"abcdefghijklmnopqrstuvwxyz" );
		if (m)
			NSLog(@"Error: couldn't pre-cache all glyphs");
		technoFont->outline_type = 0;
		technoFont->outline_thickness = 0;

		m = texture_font_load_glyphs(technoFont,
				L" -.0123456789"
		L"ABCDEFGHIJKLMNOPQRSTUVWXYZ");
		if (m)
			NSLog(@"Error: couldn't pre-cache all glyphs");

		technoFont->outline_type = 1;
		technoFont->outline_thickness = 0.3;

		m = texture_font_load_glyphs(technoFont,
				L" -.0123456789"
		L"ABCDEFGHIJKLMNOPQRSTUVWXYZ");
		if (m)
			NSLog(@"Error: couldn't pre-cache all glyphs");
	}
}

- (void)renderCountdown:(short)countdownIndex atDistance:(short)zDistance
{
	vector3f scp = [currentCamera position];
	vector3f scr = [currentCamera rotation];
	matrix44f_c svm = [currentCamera viewMatrix];
	SceneNode *st = [currentCamera relativeModeTarget];
	vector3f slp = [(Light *) [[[[scene renderpasses] lastObject] lights] objectAtIndex:0] position];


	[[scene phongOnlyShader] bind];

	[(Light *) [[[[scene renderpasses] lastObject] lights] objectAtIndex:0] setPosition:vector3f(-100.0, 300.0, 100.0)];
	[currentCamera push];
	[currentCamera setRelativeModeTarget:nil];

	[currentCamera setPosition:vector3f(0.0f, 0.0f, 0.0f)];
	[currentCamera setRotation:vector3f(0.0f, 0.0f, 0.0f)];
	[currentCamera identity];
	[currentCamera transform];



	Mesh *m = [countdownMeshes objectAtIndex:countdownIndex];
	[m setPosition:vector3f(0.0f, 0.0f, zDistance)];
	[m render];


	[currentCamera pop];
	[currentCamera setPosition:scp];
	[currentCamera setRotation:scr];
	[currentCamera setViewMatrix:svm];
	[currentCamera setRelativeModeTarget:st];

	[(Light *) [[[[scene renderpasses] lastObject] lights] objectAtIndex:0] setPosition:slp];

	/*PSEUDO_DRAW_CALL*/
	globalInfo.drawCalls++;
}

- (void)queueBitmapOverlays
{
	uint8_t powerup = [[ship powerup] activePowerupOrLoadedPowerup];
	if (powerup)
	{
		[[weaponTextureNodes objectAtIndex:powerup - 1] renderNode];

		if (powerup != kSpeedup && [[ship powerup] nitroLoaded])
		{
			BatchingTextureNode *nitro = [weaponTextureNodes objectAtIndex:kSpeedup - 1];

			[nitro setPosition:vector3f(6 + 64, BOTTOMOFFSET + 6, 0)];
			[nitro renderNode];
			[nitro setPosition:vector3f(6, BOTTOMOFFSET + 6, 0)];
		}
	}

	if ([now timeIntervalSinceDate:currentAwardDate] < kAwardNotDuration)
	{
		[awardNotificationNode renderNode];
	}

	@synchronized (self)
	{
		if ([now timeIntervalSinceDate:currentMusicDate] < kMusicNotDuration)
		{
			[musicNotificationNode renderNode];
		}
	}

#ifdef TARGET_OS_IPHONE
	[pauseNode renderNode];
#ifdef IPAD
	[cameraNode renderNode];
#endif
	[accelerateNode renderNode];

	if (STEERING_BUTTONS)
	{
		[steerLeftNode renderNode];
		[steerRightNode renderNode];
	}
	else if (STEERING_ACCELEROMETER)
	{
	}
	else if (STEERING_TOUCHPAD)
	{
		[touchCenter renderNode];
		[touchLeft renderNode];
		[touchRight renderNode];
		[touchStretchLeft renderNode];
		[touchStretchRight renderNode];
	}
	if (powerup && !game.accelWeapon)
	{
		BatchingTextureNode *node = [weaponTextureNodes objectAtIndex:powerup - 1];

		vector2f size = [node size];
		vector3f pos = [node position];


		[node setSize:vector2f(controlButtonSize/ 2, controlButtonSize/ 2)];
		[node setPosition:[shootNode position] + vector3f(controlButtonSize/ 4, controlButtonSize/ 4, 0)];
		[node renderNode];
		[node setSize:size];
		[node setPosition:pos];

		[shootNode renderNode];
	}
#endif
}

- (void)renderDimming
{
	[[scene colorOnlyShader] bind];


	float timeSinceChange = min([game flightTime], [game remainingFlightTime]);
	myBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	globalMaterial.color = vector4f(0.0f, 0.0f, 0.0f, 1.0f - min(timeSinceChange, 1.0f));

	DrawCenteredScreenQuad(w, h);
	/*PSEUDO_DRAW_CALL*/
}

- (void)renderMinimapTexture
{
	assert(currentShader);

	glBindTexture(GL_TEXTURE_2D, minimapTexname);
	currentTexture = nil;

	[minimapVBO bind];


	glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, (const GLushort *) 0);

	globalInfo.drawCalls++;
	/*DRAW_CALL*/
}

- (void)renderMinimapPoints
{
	int insect = w - ((int) (w / 40.0)) * 8;
	myClientStateVTN(kNeedEnabled, kNeedDisabled, kNeedDisabled);

	vector2f _point;
	vector2f _newpoint;


	[pointShader bind];
	globalMaterial.color = vector4f(0.8f, 0.8f, 0.8f, 1.0f);

	matrix44f_c orthographicMatrix;
	matrix_orthographic_RH(orthographicMatrix, 0.0f, (float) w, 0.0f, (float) h, -1.0f, 1.0f, cml::z_clip_neg_one);

	[currentShader prepareWithModelViewMatrix:cml::identity_transform<4, 4>() andProjectionMatrix:orthographicMatrix];



	glUniform1f(pointSizePos, w / 140.0f);



	GLshort positions[12 * 2];
	glVertexAttribPointer(VERTEX_ARRAY, 2, GL_SHORT, GL_FALSE, 0, positions);

	int i = 0;
	for (Enemyship *enemy in game.enemies)
	{
		if (![enemy enabled])
			continue;

		_point = vector2f([game.currentTrack positionAtIndex:[enemy nearestTrackpoint]][0], [game.currentTrack positionAtIndex:[enemy nearestTrackpoint]][2]);
		_newpoint = ((_point - theirCenter) / radiusFactor + ourCenter);

		positions[i * 2] = insect + _newpoint[0];
		positions[i * 2 + 1] = BOTTOMOFFSET + (ourCenter[0] * 2) - _newpoint[1];
		i++;
	}
	glDrawArrays(GL_POINTS, 0, i);
	globalInfo.drawCalls++;
	/*DRAW_CALL*/




	glUniform1f(pointSizePos, w / 80.0f);

	[currentShader setColor:vector4f(1.0f, 1.0f, 1.0f, 1.0f)];



	_point = vector2f([game.currentTrack positionAtIndex:ship.currpoint][0], [game.currentTrack positionAtIndex:ship.currpoint][2]);
	_newpoint = ((_point - theirCenter) / radiusFactor + ourCenter);
	positions[0] = insect + _newpoint[0];
	positions[1] = BOTTOMOFFSET + (ourCenter[0] * 2) - _newpoint[1];

	if (game.gameMode == kGameModeMultiplayer)
	{
		_point = vector2f([game.currentTrack positionAtIndex:[game ship2].currpoint][0], [game.currentTrack positionAtIndex:[game ship2].currpoint][2]);
		_newpoint = ((_point - theirCenter) / radiusFactor + ourCenter);

		positions[2] = insect + _newpoint[0];
		positions[3] = BOTTOMOFFSET + (ourCenter[0] * 2) - _newpoint[1];
		glDrawArrays(GL_POINTS, 0, 2);
	}
	else
		glDrawArrays(GL_POINTS, 0, 1);

	globalInfo.drawCalls++;
	/*DRAW_CALL*/

	glUniform1f(pointSizePos, w / 100.0f);
	[currentShader setColor:vector4f(0.0f, 0.0f, 0.0f, 1.0f)];


	_point = vector2f([game.currentTrack positionAtIndex:ship.currpoint][0], [game.currentTrack positionAtIndex:ship.currpoint][2]);
	_newpoint = ((_point - theirCenter) / radiusFactor + ourCenter);
	positions[0] = insect + _newpoint[0];
	positions[1] = BOTTOMOFFSET + (ourCenter[0] * 2) - _newpoint[1];
	glDrawArrays(GL_POINTS, 0, 1);

	globalInfo.drawCalls++;
	/*DRAW_CALL*/

	if (game.gameMode == kGameModeMultiplayer)
	{
		[currentShader setColor:vector4f(0.8f, 0.2f, 0.2f, 1.0f)];

		_point = vector2f([game.currentTrack positionAtIndex:[game ship2].currpoint][0], [game.currentTrack positionAtIndex:[game ship2].currpoint][2]);
		_newpoint = ((_point - theirCenter) / radiusFactor + ourCenter);
		positions[0] = insect + _newpoint[0];
		positions[1] = BOTTOMOFFSET + (ourCenter[0] * 2) - _newpoint[1];
		glDrawArrays(GL_POINTS, 0, 1);

		globalInfo.drawCalls++;
		/*DRAW_CALL*/
	}
}

- (void)queueString:(const char *)string atX:(uint16_t)pos_x atY:(uint16_t)pos_y withColor:(vector4f)color withOutlineColor:(vector4f)ocolor isLabel:(BOOL)label
{
	vec3 c = {{color[0], color[1], color[2]}};
	vec3 oc = {{ocolor[0], ocolor[1], ocolor[2]}};
	texture_font_t *font = label ? plainFont : technoFont;

	if (label)
	{
		vec2 pen = {{pos_x + 1, pos_y + 1}};
		add_text(vbuffer, font, string, pen, oc, oc);
	}

	vec2 pen = {{pos_x, pos_y}};
	font->outline_type = 0;
	font->outline_thickness = 0;
	add_text(vbuffer, font, string, pen, c, c);


	if (!label)
	{
		font->outline_type = 1;
		font->outline_thickness = 0.3;
		add_text(vbuffer, font, string, pen, oc, oc);
	}
}

- (void)queueString:(const char *)string atX:(uint16_t)pos_x atY:(uint16_t)pos_y withColor:(vector4f)color isLabel:(BOOL)label
{
	[self queueString:string atX:pos_x atY:pos_y withColor:color withOutlineColor:vector4f(0.0, 0.0, 0.0, 1.0) isLabel:label];
}

- (void)queueString:(const char *)string atX:(uint16_t)pos_x atY:(uint16_t)pos_y isLabel:(BOOL)label
{
	[self queueString:string atX:pos_x atY:pos_y withColor:vector4f(0.7, 0.7, 0.7, 1.0) withOutlineColor:vector4f(0.0, 0.0, 0.0, 1.0) isLabel:label];
}

- (float)stringWidth:(const char *)string isLabel:(BOOL)label
{
	float x = 0;
	texture_glyph_t *glyph;

	for (size_t j = 0; j < strlen(string); ++j)
	{
		glyph = texture_font_get_glyph(label ? plainFont : technoFont, string[j]);
		if (!glyph)
		{
			NSLog(@"Warning: stringDimension got empty glyph");
			continue;
		}
		int kx = (j == 0) ? 0 : texture_glyph_get_kerning(glyph, string[j - 1]);
		x += kx;
		x += glyph->advance_x;
	}

//    NSLog(@"string dimension %f %f %s", x, (float) glyph->height, string);
	return x;
}

- (void)queueStrings
{
	uint8_t leftinsect = fontsize / 4;
	uint8_t bottominsect = leftinsect + BOTTOMOFFSET;
	uint16_t topinsect = h - (fontsize + 5);
	vector4f color;

	char str[] = "RANK.. 12 OF 12";
	float rdim = [self stringWidth:str isLabel:FALSE];
	char str2[] = "12 OF 12";
	float rdim2 = [self stringWidth:str2 isLabel:FALSE];

	if (game.gameMode != kGameModeTimeAttack && runde >= 1)
	{
		[self queueString:"LAPS" atX:leftinsect atY:topinsect isLabel:FALSE];
		for (int i = 1; i <= game.roundsNum; i++)
		{
			if (runde < i)
				snprintf(buf, kBufferSize, "%i.", i);
			else if (runde == i)
				snprintf(buf, kBufferSize, "%i. %.1f", i, [game simTime] - [[timeArray objectAtIndex:i - 1] doubleValue]);
			else
				snprintf(buf, kBufferSize, "%i. %.1f", i, [[timeArray objectAtIndex:i] doubleValue] - [[timeArray objectAtIndex:i - 1] doubleValue]);

			[self queueString:buf atX:leftinsect atY:topinsect - (fontsize * i) isLabel:FALSE];
		}

		[self queueString:"RANK." atX:w - rdim - leftinsect atY:topinsect - fontsize isLabel:FALSE];
		snprintf(buf, kBufferSize, "%i OF %i", [ship placing], game.aliveShipCount);
		color = vector4f(0.1 + ([ship placing] / game.aliveShipCount) * 0.6, 0.8, 0.1 + ([ship placing] / game.aliveShipCount) * 0.6, 1.0);
		[self queueString:buf atX:w - rdim2 - leftinsect atY:topinsect - fontsize withColor:color isLabel:FALSE];
	}
	else if (runde > 0)
	{
		[self queueString:"LAPS" atX:leftinsect atY:topinsect isLabel:FALSE];

		snprintf(buf, kBufferSize, "%s", [fastestLap cStringUsingEncoding:NSASCIIStringEncoding]);
		[self queueString:buf atX:leftinsect atY:topinsect - fontsize isLabel:FALSE];

		snprintf(buf, kBufferSize, "CURR. %.1f", [self timeInCurrentRound]);
		[self queueString:buf atX:leftinsect atY:topinsect - (fontsize * 2) isLabel:FALSE];
	}

	if ([now timeIntervalSinceDate:currentAwardDate] < kAwardNotDuration)
	{
		NSArray *awardWords = [currentAward componentsSeparatedByString:@" "];
		int awardY = [awardNotificationNode position][1];

		[self queueString:"AWARD" atX:widthAward / 2.8 atY:awardY + heightAwardHalf + fontsize * 1.5 isLabel:FALSE];

		[self queueString:[[awardWords objectAtIndex:0] cStringUsingEncoding:NSASCIIStringEncoding]
		              atX:widthAward / 2.8
		              atY:awardY + heightAwardHalf - fontsize
			      isLabel:FALSE];
		[self queueString:[[awardWords objectAtIndex:1] cStringUsingEncoding:NSASCIIStringEncoding]
		              atX:widthAward / 2.8
		              atY:awardY + heightAwardHalf - fontsize * 2
			      isLabel:FALSE];
	}

	@synchronized (self)
	{
		if ([now timeIntervalSinceDate:currentMusicDate] < kMusicNotDuration)
		{
			NSArray *awardWords = [currentMusic componentsSeparatedByString:@" - "];
			int musicY = [musicNotificationNode position][1];
			[self queueString:"MUSIC" atX:(w - widthAward) + widthAward / 2.8 atY:musicY + heightAwardHalf + fontsize * 1.5 isLabel:FALSE];


			[self queueString:[[awardWords objectAtIndex:0] cStringUsingEncoding:NSASCIIStringEncoding]
			              atX:(w - widthAward) + widthAward / 2.8
			              atY:musicY + heightAwardHalf - fontsize * 0.5
				      isLabel:TRUE];
			[self queueString:[[awardWords objectAtIndex:1] cStringUsingEncoding:NSASCIIStringEncoding]
			              atX:(w - widthAward) + widthAward / 2.8
			              atY:musicY + heightAwardHalf - fontsize * 1.5
				      isLabel:TRUE];
		}
	}

	if (runde > 0)
	{
		float speedInfo = [ship speed].length();
		[self queueString:"PACE." atX:w - rdim - leftinsect atY:topinsect isLabel:FALSE];

		snprintf(buf, kBufferSize, "%.0f", speedInfo * 160);
		color = vector4f(0.7 - (speedInfo * 160) / 800, 0.7 - (speedInfo * 160) / 800, 0.80, 1.0);
		[self queueString:buf atX:w - rdim2 - leftinsect atY:topinsect withColor:color isLabel:FALSE];

		if (game.gameMode != kGameModeTimeAttack && game.gameMode != kGameModeMultiplayer)
		{
			int core = [ship core];
			[self queueString:"CORE." atX:w - rdim - leftinsect atY:topinsect - fontsize * 2 isLabel:FALSE];

			if (![ship coreModeActive])
			{
				if ([ship core] > 100)
					color = vector4f(0.8,
							((globalInfo.frame / 10) % 2 != 0) ? 1 : 0,
							((globalInfo.frame / 10) % 2 != 0) ? 1 : 0, 1.0);
				else
					color = vector4f(0.8, (100 - core) / 125.0, (100 - core) / 125.0, 1.0);

				snprintf(buf, kBufferSize, "%i", core);
			}
			else
			{
				color = vector4f(0.99, 0.3, 0.3, 1.0);

				snprintf(buf, kBufferSize, "ACTIVE");
			}


			[self queueString:buf atX:w - rdim2 - leftinsect atY:topinsect - fontsize * 2 withColor:color isLabel:FALSE];
		}
	}

	if (globalSettings.slowMotion && (([ship slowmoFinish] - game.simTime) > 0))
	{
		snprintf(buf, kBufferSize, "SLOWTIME. %.1f", [ship slowmoFinish] - game.simTime);

		float dim = [self stringWidth:buf isLabel:FALSE];;
		[self queueString:buf atX:w / 2.0f - dim / 2.0f atY:h / 3.0f isLabel:FALSE];
	}

	if ([ship coreModeActive])
	{
		snprintf(buf, kBufferSize, "CORETIME. %.1f", [ship coreModeFinish] - game.simTime);

		float dim = [self stringWidth:buf isLabel:FALSE];;
		[self queueString:buf atX:w / 2.0f - dim / 2.0f atY:h / 3.3f isLabel:FALSE];
	}

	if ([weaponMessages count])
	{
		int offset = 70;
		for (NSDictionary *msg in weaponMessages)
		{
			snprintf(buf, kBufferSize, "%s", [[msg objectForKey:@"msg"] cStringUsingEncoding:NSASCIIStringEncoding]);

			[self queueString:buf atX:leftinsect atY:bottominsect + offset withColor:vector4f(0.7, 0.7, 0.7, 1.0) withOutlineColor:vector4f(0.0, 0.0, 0.0, 1.0) isLabel:TRUE];
#ifdef IPHONE
            offset += 20;            
#else
			offset += 40;
#endif
		}
	}

	uint8_t powerup = [[ship powerup] activePowerupOrLoadedPowerup];
	if (powerup)
	{
#ifdef IPHONE
        snprintf(buf, kBufferSize, "%s", [[[[ship powerup] name] uppercaseString] cStringUsingEncoding:NSASCIIStringEncoding]);
#else
		snprintf(buf, kBufferSize, "%s %s", [[[[ship powerup] name] uppercaseString] cStringUsingEncoding:NSASCIIStringEncoding], ([[ship powerup] activePowerup] ? "FIRED" : "AVAILABLE"));
#endif
		if (powerup != kSpeedup && [[ship powerup] nitroLoaded])
			[self queueString:buf atX:leftinsect + 70 + 64 atY:bottominsect isLabel:FALSE];
		else
			[self queueString:buf atX:leftinsect + 70 atY:bottominsect isLabel:FALSE];
	}

	if (globalSettings.displayFPS)
	{
		snprintf(buf, kBufferSize, "FPS %u", globalInfo.fps);

		[self queueString:buf atX:w / 2 - (fontsize * 2) atY:topinsect isLabel:FALSE];
	}

	if ([now timeIntervalSinceDate:currentMessageDate] < ((runde < 1) ? 5.0 : 1.5))
	{
		if (!currentMessageUrgent || (globalInfo.frame / 4) % 6 != 0)
		{
			float dim = [self stringWidth:[currentMessage cStringUsingEncoding:NSASCIIStringEncoding] isLabel:FALSE];

			if (currentMessageUrgent)
				color = vector4f(0.99, 0.6, 0.6, 1.0);
			else
				color = vector4f(0.7, 0.7, 0.7, 1.0);

			[self queueString:[currentMessage cStringUsingEncoding:NSASCIIStringEncoding]
			              atX:w / 2.0f - dim / 2.0f
			              atY:h / 2.0f - fontsize / 2.0f
				    withColor:color
					  isLabel:FALSE];
		}
	}

	if (enemyNamePref < 2)
	{
		CGRect frame = [currentRenderPass frame];
		for (SceneNode <Ship> *enemy in game.ships)
		{
			if (enemy == ship || ![enemy enabled])
				continue;

			if (![enemy isKindOfClass:[Playership class]] && (enemyNamePref == 1))
				continue;

			if (length([enemy position] - [ship position]) < 40)
			{
				vector3f p = cml::project_point([currentCamera viewMatrix], [currentCamera projectionMatrix], [currentRenderPass viewportMatrix], [enemy position]);


				if (p[0] > frame.origin.x &&
						p[1] > frame.origin.y &&
						p[0] < frame.origin.x + frame.size.width &&
						p[1] < frame.origin.y + frame.size.height &&
						p[2] < 1.0 && p[2] > 0.0)
				{
					p[0] -= frame.origin.x;
					p[1] -= frame.origin.y;

					const char *enemyName = [[enemy name] cStringUsingEncoding:NSASCIIStringEncoding];
					float dim = [self stringWidth:enemyName isLabel:TRUE];

					if ([enemy isKindOfClass:[Playership class]])
						color = vector4f(0.3, 0.4, 0.9, 1.0);
					else
						color = vector4f(0.9, 0.4, 0.3, 1.0);

					[self queueString:enemyName
					              atX:p[0] - dim / 2.0
					              atY:p[1] + frame.size.height / 50.0
						    withColor:color
					 withOutlineColor:vector4f(0.9, 0.9, 0.9, 1.0)
							  isLabel:TRUE];
				}
			}
		}
	}
}

- (void)preloadTex
{
	[[scene textureOnlyShader] bind];

	glBindTexture(GL_TEXTURE_2D, imageAtlas->id);
	currentTexture = nil;

	DrawQuadWithCoordinates(0, 0,
			0 + 32, 0,
			0 + 32, 32,
			0, 32);

	NSArray *tex = [Texture allTextures];
	int x = 1;
	int y = 0;
	for (Texture *t in tex)
	{
		[t bind];

		DrawQuadWithCoordinates(x * 32, y * 32,
				x * 32 + 32, y * 32,
				x * 32 + 32, y * 32 + 32,
				x * 32, y * 32 + 32);

		x++;

		if (x * 32 + 32 > w)
		{
			x = 0;
			y++;
		}
	}

	/*PSEUDO_DRAW_CALL*/
}

- (void)purgeWeaponMessages
{
	if (globalInfo.frame % 60 == 0)
	{
		NSMutableArray *tmp = [NSMutableArray array];
		for (NSDictionary *msg in weaponMessages)
		{
			if ([now timeIntervalSinceDate:[msg objectForKey:@"time"]] > 2)
				[tmp addObject:msg];
		}
		[weaponMessages removeObjectsInArray:tmp];
	}
}

- (void)renderCountdown
{
	if ((runde == 0) || ((runde == 1) && ([self timeInCurrentRound] < 1.0f)))
	{
		float countdownTime = [game simTime] - startTime;
		if ((int) countdownTime <= 3)
			[self renderCountdown:countdownTime atDistance:(-70.0f - (countdownTime - floor(countdownTime)) * 350.0f)];
	}
}

- (void)renderNode
{
	if (![scene bounds].width || ![scene bounds].height || (currentRenderPass.settings != kMainRenderPass) || done)
		return;

	[now release];
	now = [[NSDate date] retain];
	w = [currentRenderPass frame].size.width;
	h = [currentRenderPass frame].size.height;


	vertex_buffer_clear(imageBuffer);
	vertex_buffer_clear(vbuffer);


	[self purgeWeaponMessages];



	[self renderCountdown];

	myEnableBlendParticleCullDepthtestDepthwrite(YES, NO, YES, NO, YES);



	if ((runde < 1) && (game.flightMode < kFlightGame))
		[self renderDimming];


	if (globalInfo.frame == 0)
		[self preloadTex];

	[self queueStrings];
	[self queueBitmapOverlays];


	{ // render queued overlays & minimap texture
		globalMaterial.color = vector4f(1.0f, 1.0f, 1.0f, 1.0f);
		myBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		matrix44f_c orthographicMatrix;
		matrix_orthographic_RH(orthographicMatrix, 0.0f, (float) w, 0.0f, (float) h, -1.0f, 1.0f, cml::z_clip_neg_one);


		if (runde >= 1)
		{
			[[scene textureOnlyShader] bind];

			[currentShader prepareWithModelViewMatrix:cml::identity_transform<4, 4>() andProjectionMatrix:orthographicMatrix];
			myClientStateVTN(kNeedEnabled, kNeedEnabled, kNeedDisabled);
			glBindTexture(GL_TEXTURE_2D, imageAtlas->id);       // render overlay bitmaps
			currentTexture = nil;
			vertex_buffer_render(imageBuffer, GL_TRIANGLES, "gg");
			/*PREUSO_DRAW_CALL*/

			if ((runde >= 1) && (game.gameMode != kGameModeTimeAttack) && !(game.gameMode == kGameModeMultiplayer && [ship playerNumber] == 1))
				[self renderMinimapTexture];                        // render minimap texture
		}


		[colorAttributeTextureShader bind];

		[currentShader prepareWithModelViewMatrix:cml::identity_transform<4, 4>() andProjectionMatrix:orthographicMatrix];
		myClientStateVTN(kNeedEnabled, kNeedEnabled, kNeedEnabled);
		glBindTexture(GL_TEXTURE_2D, manager->atlas->id);   // render overlay strings
		currentTexture = nil;
		vertex_buffer_render(vbuffer, GL_TRIANGLES, "ggg");
		/*PREUSO_DRAW_CALL*/
	}

	myEnableBlendParticleCullDepthtestDepthwrite(YES, YES, YES, NO, YES);
	if ((runde >= 1) && (game.gameMode != kGameModeTimeAttack) && !(game.gameMode == kGameModeMultiplayer && [ship playerNumber] == 1))
		[self renderMinimapPoints];
}

- (float)timeInCurrentRound
{
	return [game simTime] - [[timeArray lastObject] doubleValue];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
//	NSLog(@"runde changed from %i to %i (max %i)", runde, [ship round], game.roundsNum);
//    #warning revert

	runde = [ship round];
	if (runde == 0)
	{
		startTime = game.simTime;
		return;
	}

	[timeArray addObject:$numd([game simTime])];
	int len = [timeArray count];
	float time = len > 1 ? [[timeArray objectAtIndex:len - 1] doubleValue] - [[timeArray objectAtIndex:len - 2] doubleValue] : 0.0;


	if (game.gameMode == kGameModeTimeAttack)
	{
		// NSLog(@"timeattack");

		if (len > 1)
		{
			// NSLog(@"full lap");

			if (time < [[NSUserDefaults standardUserDefaults] doubleForKey:$stringf(@"FastestTimeAttackTrack%iTime", game.highscoreTrackNum)])
			{
				// NSLog(@"fastest lap");

				[fastestLap release];
				fastestLap = [$stringf(@"Best. %.1f", time) retain];
				[[NSUserDefaults standardUserDefaults] setDouble:time forKey:$stringf(@"FastestTimeAttackTrack%iTime", game.highscoreTrackNum)];
				$setdefault([game.ship ghostData], $stringf(@"FastestTimeAttackTrack%iData", game.highscoreTrackNum));
				$setdefaulti(game.shipNum, $stringf(@"FastestTimeAttackTrack%iShip", game.highscoreTrackNum));
#ifdef __APPLE__
				dispatch_async(dispatch_get_global_queue(0, 0), ^
				{
					$defaultsync;
				});
#endif
				SceneNode *ghostShipGroupNode = [game ghostShipGroupNode];
				Ghostship *ghost = [[ghostShipGroupNode children] lastObject];

				//  NSLog(@"ghost data %@", [[game.ship ghostData] description]);

				if (!ghost ||
						[ghost shipNum] != game.shipNum)
				{

					Ghostship *g = [[Ghostship alloc] initWithOctreeNamed:[[game shipNames] objectAtIndex:game.shipNum]];
					[g setData:[NSData dataWithData:[game.ship ghostData]]];
					[g setShipNum:game.shipNum];
					[[ghostShipGroupNode children] removeAllObjects];
					[[ghostShipGroupNode children] addObject:g];
					[g release];

					// NSLog(@"adding new ghost ship %@", [g description]);

				}
				else
				{
					[ghost setData:[[[game.ship ghostData] copy] autorelease]];

					//    NSLog(@"setting data of existing ship");
				}
			}
			// else
			//	NSLog(@"NOT fastest lap");
		}
		[game.ship resetGhostData];
	}


	if (((game.gameMode == kGameModeCareer) || (game.gameMode == kGameModeCustomGame)) &&
			runde > 1)
	{
		if ([ship alwaysLeading])
			[self addAward:kAwardLeadRound];

		if ([ship noWallhit])
			[self addAward:kAwardCleanRound];

		[ship resetLapObjectives];
	}

	if (runde > game.roundsNum)
	{
//        NSLog(@"finished last roudn!");
//        #warning revert

		[game advanceFlightMode];
		[ship stopSound];

		[ship setCoreModeActive:FALSE];

		endSieg = [ship placing];
		endTime = [game simTime];

		switch (endSieg)
		{
			case 1:
		        Play_Sound(sounds.first);
		        break;
			case 2:
		        Play_Sound(sounds.second);
		        break;
			case 3:
		        Play_Sound(sounds.third);
		        break;
			default:
		        Play_Sound(sounds.bad_result);
		        break;
		}

#ifdef TARGET_OS_MAC
        float animduration = 6.0f;
        float finishdelay = 2.0f;
#else
		float animduration = 4.0f;
		float finishdelay = 4.0f;
#endif


		[game addAnimationWithDuration:animduration
		                     animation:^(double delay)
		                     {
			                     [ship.attachedCamera setPosition:vector3f(sinf(delay * M_PI) * (delay + 1), 1, cosf(delay * M_PI) * (delay + 1))];
			                     [ship.attachedCamera setRotation:vector3f(0, delay * 180, 0)];
		                     }
				            completion:^
				            {}];

		if (game.flightMode == kFlightEpilogue)
		{
			done = TRUE;

			[game performBlockAfterDelay:finishdelay block:^
			{
#ifdef TARGET_OS_MAC
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[GameSheetController sharedController] viewScoreAction:self];
                });
#elif defined(__COCOTRON__) || defined (GNUSTEP)
                [[RenderViewController sharedController] quitAndLoadNib:nil];
#elif defined(TARGET_OS_IPHONE)
				NSDictionary *result = [CoreBreach fetchResult1];
				NSDictionary *settings = [CoreBreach fetchSettings];
				NSDictionary *obj = [NSDictionary dictionaryWithObjectsAndKeys:settings, @"settings", result, @"result", nil]; // result 2 can be nil shouldnt matter
//                NSLog(@"sending game finished notificatioN");
//                #warning revert

				[[NSNotificationCenter defaultCenter] postNotificationName:@"gameFinished" object:obj];
				[result release];
				[settings release];
#endif
			}];
			//	[game performBlockAfterDelay:6.0 block:^{ if (scene && [scene renderpasses] && [[scene renderpasses] count])            [[[[scene renderpasses] objectAtIndex:1] objects] addObject:[[[QCNode alloc] initWithCompositionNamed:@"CL"] autorelease]]; }];
		}
		else
		{
			assert(0);
		}
	}
	else if (runde > 1)
		Play_Sound(sounds.checkpoint);

	if ((runde > 1) && (game.gameMode != kGameModeMultiplayer))
	{
		//   NSLog(@"going to highscore");
		Highscores *hs = [[Highscores alloc] init];

		[hs storeHighscore:time forMode:game.gameMode forNickname:$default(kNicknameKey) onTrack:game.highscoreTrackNum withShip:game.shipNum];

		[hs sendHighscore:time forMode:game.gameMode forNickname:$default(kNicknameKey) onTrack:game.highscoreTrackNum withShip:game.shipNum withData:[NSData data]];

		[hs release];
	}
}

- (void)addMusic:(NSString *)music
{
	@synchronized (self)
	{
		[currentMusic release];
		currentMusic = [music copy];

		[currentMusicDate release];
		currentMusicDate = [now copy];
	}
}

- (void)addAward:(awardEnum)award
{
	NSString *message;
	if (award == kAwardCorebreach)
	{
		message = @"CORE BREACH";
		corebreaches++;
	}
	else if (award == kAwardCleanRound)
	{
		message = @"CLEAN ROUND";
		cleanrounds++;
	}
	else if (award == kAwardLeadRound)
	{
		message = @"LEAD ROUND";
		leadrounds++;
	}
	else if (award == kAwardObtainHit)
	{
		message = @"OBTAIN HIT";
	}
	else
	{
		fatal("AddAward unknown");
	}


	if ([now timeIntervalSinceDate:currentAwardDate] > kAwardNotDuration)
	{
		[currentAward release];
		currentAward = [message copy];

		[currentAwardDate release];
		currentAwardDate = [now copy];
	}
	else
	{
		if (!kAwardObtainHit)
		{
			[game performBlockAfterDelay:(kAwardNotDuration - [now timeIntervalSinceDate:currentAwardDate])
			                       block:^
			                       {
				                       [currentAward release];
				                       currentAward = [message copy];

				                       [currentAwardDate release];
				                       currentAwardDate = [[NSDate date] copy];
			                       }];
		}
	}
}

- (void)addWeaponMessage:(NSString *)message
{
	NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:message, @"msg", now, @"time", nil];
	[weaponMessages addObject:dict];
	[dict release];
}

- (void)addMessage:(NSString *)message urgent:(BOOL)urgent
{
	//  NSLog(@"add message %@", message);

	[currentMessage release];
	currentMessage = [[[message stringByReplacingOccurrencesOfString:@"ä" withString:@"ae"] uppercaseString] copy];

	[currentMessageDate release];
	currentMessageDate = [now copy];

	currentMessageUrgent = urgent;
}

- (void)removeAllMessages
{
	[currentMessage release];
	currentMessage = @"BiteMyShinyMetal@$$";

	[currentMessageDate release];
	currentMessageDate = [[NSDate distantPast] retain];
}

- (GLuint)makeMinimap:(int)size
{
#ifdef TARGET_OS_IPHONE
	int realsize = size;
#ifdef IPHONE
    size = 128;
#elif defined(IPAD)
	size = 256;
#else
#error shit
#endif
#endif

	GLuint texName;

#ifndef GNUSTEP
	//CGRect rect = {{0, 0}, {size.width, size.height}};
	void *data = calloc(size * 4, size);

	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
#ifdef TARGET_OS_IPHONE
	CGContextRef bitmapContext = CGBitmapContextCreate(data, size, size, 8, size * 4, space, kCGImageAlphaPremultipliedLast);
#else
    	CGContextRef bitmapContext = CGBitmapContextCreate(data, size, size, 8, size * 4, space, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little );
#endif
	CGColorSpaceRelease(space);

	CGContextTranslateCTM(bitmapContext, 0, size);
	CGContextScaleCTM(bitmapContext, 1.0, -1.0);


	theirCenter = vector2f([game.currentTrack center][0], [game.currentTrack center][2]);
	ourCenter = vector2f(size / 2, size / 2);
	radiusFactor = [game.currentTrack radius] / (sqrtf((size - (size / 30.0)) * (size - (size / 30.0))) / 2);



	CGContextSetRGBStrokeColor(bitmapContext, 0.0, 0.0, 0.0, 1.0);
	CGContextSetLineWidth(bitmapContext, size / 25.0);
	CGContextSetLineJoin(bitmapContext, kCGLineJoinRound);
	for (int i = 0; i < [game.currentTrack trackPoints] / 19; i++)
	{
		vector2f _point = vector2f([game.currentTrack positionAtIndex:i * 20][0], [game.currentTrack positionAtIndex:i * 20][2]);

		vector2f _newpoint = ((_point - theirCenter) / radiusFactor + ourCenter);

		if (i == 0)
			CGContextMoveToPoint(bitmapContext, _newpoint[0], size - _newpoint[1]);
		else
			CGContextAddLineToPoint(bitmapContext, _newpoint[0], size - _newpoint[1]);
	}
	CGContextStrokePath(bitmapContext);



	CGContextSetRGBStrokeColor(bitmapContext, 0.5, 0.5, 0.5, 1.0);
	CGContextSetLineWidth(bitmapContext, size / 30.0);
	CGContextSetLineJoin(bitmapContext, kCGLineJoinRound);
	for (int i = 0; i < [game.currentTrack trackPoints] / 19; i++)
	{
		vector2f _point = vector2f([game.currentTrack positionAtIndex:i * 20][0], [game.currentTrack positionAtIndex:i * 20][2]);

		vector2f _newpoint = ((_point - theirCenter) / radiusFactor + ourCenter);

		if (i == 0)
			CGContextMoveToPoint(bitmapContext, _newpoint[0], size - _newpoint[1]);
		else
			CGContextAddLineToPoint(bitmapContext, _newpoint[0], size - _newpoint[1]);
	}
	CGContextStrokePath(bitmapContext);


	CGContextSetRGBStrokeColor(bitmapContext, 0.0, 1.0, 0.0, 1.0);
	CGContextSetLineJoin(bitmapContext, kCGLineJoinMiter);
	vector2f _point = vector2f([game.currentTrack positionAtIndex:0][0], [game.currentTrack positionAtIndex:0][2]);
	vector2f _newpoint = ((_point - theirCenter) / radiusFactor + ourCenter);
	CGContextMoveToPoint(bitmapContext, _newpoint[0], size - _newpoint[1]);
	vector2f _point2 = vector2f([game.currentTrack positionAtIndex:[game.currentTrack trackPoints] / 100][0], [game.currentTrack positionAtIndex:[game.currentTrack trackPoints] / 100][2]);
	vector2f _newpoint2 = ((_point2 - theirCenter) / radiusFactor + ourCenter);
	CGContextAddLineToPoint(bitmapContext, _newpoint2[0], size - _newpoint2[1]);
	CGContextStrokePath(bitmapContext);


#ifdef TARGET_OS_IPHONE
	theirCenter = vector2f([game.currentTrack center][0], [game.currentTrack center][2]);
	ourCenter = vector2f(realsize / 2, realsize / 2);
	radiusFactor = [game.currentTrack radius] / (sqrtf((realsize - (realsize / 30.0)) * (realsize - (realsize / 30.0))) / 2);
#endif

	CGContextRelease(bitmapContext);
#else
    
    NSImage *theImage = [[NSImage alloc] initWithSize:NSMakeSize(size, size)];
    
    [theImage lockFocus];
    
    //    NSAffineTransform *t = [NSAffineTransform transform];
    //           [t scaleXBy:1.0 yBy:-1.0];
    //           [t translateXBy:0.0 yBy:-size];
    //           [t concat];
    
    
    theirCenter = vector2f([game.currentTrack center][0], [game.currentTrack center][2]);
	ourCenter = vector2f(size / 2, size / 2);
	radiusFactor = [game.currentTrack radius] / (sqrtf((size  - (size / 30.0)) *  (size  - (size / 30.0))) / 2);
    
    
    {
        [[NSColor blackColor] setStroke];
        NSBezierPath* aPath = [NSBezierPath bezierPath];
        [aPath setLineJoinStyle:NSRoundLineJoinStyle];
        [aPath setLineWidth:size / 25.0f];
        for (int i = 0; i < [game.currentTrack trackPoints] / 19; i++)
        {
            vector2f _point = vector2f([game.currentTrack positionAtIndex:i*20][0], [game.currentTrack positionAtIndex:i*20][2]);
            
            vector2f _newpoint = ((_point - theirCenter) / radiusFactor + ourCenter);
            
            if (i == 0)
                [aPath moveToPoint:NSMakePoint(_newpoint[0], /*size -*/ _newpoint[1])];
            else
                [aPath lineToPoint:NSMakePoint(_newpoint[0], /*size -*/ _newpoint[1])];
        }
        [aPath stroke];
    }
    {
        [[NSColor grayColor] setStroke];
        NSBezierPath* aPath = [NSBezierPath bezierPath];
        [aPath setLineJoinStyle:NSRoundLineJoinStyle];
        [aPath setLineWidth:size / 30.0f];
        for (int i = 0; i < [game.currentTrack trackPoints] / 19; i++)
        {
            vector2f _point = vector2f([game.currentTrack positionAtIndex:i*20][0], [game.currentTrack positionAtIndex:i*20][2]);
            
            vector2f _newpoint = ((_point - theirCenter) / radiusFactor + ourCenter);
            
            if (i == 0)
                [aPath moveToPoint:NSMakePoint(_newpoint[0], /*size -*/ _newpoint[1])];
            else
                [aPath lineToPoint:NSMakePoint(_newpoint[0], /*size -*/ _newpoint[1])];
        }
        [aPath stroke];
    }
    
    {
        [[NSColor greenColor] setStroke];
        NSBezierPath* aPath = [NSBezierPath bezierPath];
        [aPath setLineJoinStyle:NSMiterLineJoinStyle];
        [aPath setLineWidth:size / 30.0f];
        
        vector2f _point = vector2f([game.currentTrack positionAtIndex:0][0], [game.currentTrack positionAtIndex:0][2]);
        vector2f _newpoint = ((_point - theirCenter) / radiusFactor + ourCenter);
        [aPath moveToPoint:NSMakePoint(_newpoint[0], /*size -*/ _newpoint[1])];
        vector2f _point2 = vector2f([game.currentTrack positionAtIndex:[game.currentTrack trackPoints] / 100][0], [game.currentTrack positionAtIndex:[game.currentTrack trackPoints] / 100][2]);
        vector2f _newpoint2 = ((_point2 - theirCenter) / radiusFactor + ourCenter);
        [aPath lineToPoint:NSMakePoint(_newpoint2[0], /*size -*/ _newpoint2[1])];
        
        [aPath stroke];
    }
    
    
    NSBitmapImageRep *bitmap = [NSBitmapImageRep alloc];
    NSImageRep *rep = [theImage bestRepresentationForDevice: nil];
    
    [rep drawInRect:NSMakeRect(0, 0, size, size)];
    
    [bitmap initWithFocusedViewRect:NSMakeRect(0.0, 0.0, size, size)];
    
    
    [theImage unlockFocus];
    
    void *data = [bitmap bitmapData];
#endif



	glGenTextures(1, &texName);
	glBindTexture(GL_TEXTURE_2D, texName);
	currentTexture = nil;



	//	NSLog(@"HUD creating texture %i", size);
#ifndef GL_ES_VERSION_2_0
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, size, size, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, data);
#else

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, size, size, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
#endif


#ifndef GNUSTEP
	free(data);
#endif

	return texName;
}
@end

// ------------------------------------------------------- typedef & struct ---
typedef struct
{
	float x, y, z;
	float u, v;
	vec3 color;
} vertex_t;

// --------------------------------------------------------------- add_text ---
void add_text(vertex_buffer_t *buffer, texture_font_t *font,
		const char *text, vec2 pen, vec3 fg_color_1, vec3 fg_color_2)
{
	size_t i;
	for (i = 0; i < strlen(text); ++i)
	{
		texture_glyph_t *glyph = texture_font_get_glyph(font, text[i]);

		if (!glyph)
		{
			printf("Warning: add_text got empty glyph\n");
			continue;
		}

		float kerning = 0;
		if (i > 0)
		{
			kerning = texture_glyph_get_kerning(glyph, text[i - 1]);
		}
		pen.x += kerning;

		/* Actual glyph */
		float x0 = (pen.x + glyph->offset_x);
		float y0 = (int) (pen.y + glyph->offset_y);
		float x1 = (x0 + glyph->width);
		float y1 = (int) (y0 - glyph->height);
		float s0 = glyph->s0;
		float t0 = glyph->t0;
		float s1 = glyph->s1;
		float t1 = glyph->t1;
		GLuint index = buffer->vertices->size;
		GLushort indices[] = {index, index + 1, index + 2,
				index, index + 2, index + 3};
		vertex_t vertices[] = {
				{(int) x0, y0, 0, s0, t0, fg_color_1},
				{(int) x0, y1, 0, s0, t1, fg_color_2},
				{(int) x1, y1, 0, s1, t1, fg_color_2},
				{(int) x1, y0, 0, s1, t0, fg_color_1}};
		vertex_buffer_push_back_indices(buffer, indices, 6);
		vertex_buffer_push_back_vertices(buffer, vertices, 4);
		pen.x += glyph->advance_x;
	}
}
