//
//  Game.m
//  Core3D
//
//  Created by CoreCode on 19.11.07.
//  Copyright 2007 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//
/* 
 TODO:
 
 v1.2:
    "steering improvements"
 
    iOS:
        assert in HUD triggered / no finish?
        wrong accelerometer direction sometimes?      
 
    bugs:
        win32: video prefs lower line wrong
        webm videos have spanish subtitles on english systems
        wave can catch when falling
        the stutter problem
        rescue rotation z problem
        unpretty things after finish
        enemies touching walls (track 3)

    enhancements:
        linux: sdl doesn't give us all resolutions
        add aspect ratio in SDL resolution popup
        intelligent helper, that shows keys or camera change
        movie longer especially spanish subtitles
        show attacks and damage in minimap
        force feedback
        missile wall collision explosion
        hud speedometer
        "killcam"

    rare bugs:
        crash HID : #0  0x00000001007e867d in IOHIDQueueClass::queueEventSourceCallback () (damaged queue pointer)
        coremode active after finish
        superbug when changing lane in spiral
 */


#import "Game.h"


#ifndef TARGET_OS_IPHONE
#import "Editor.h"
#else
int steeringMode;
#endif
#import "Highscores.h"


const NSString *global_bundleVersion = @"1.1.5";
const NSString *global_bundleIdentifier = @"org.corecode.corebreachmac";

//#define BUILD_PVS 1

#ifdef DEBUG
BOOL renderCollision;
#endif

Sounds sounds;
Game *game = nil;
//NSMutableDictionary     *wrongShips;

@implementation Game

@synthesize lodMode, bonusboxen, enemiesNum, trackNum, meshTrackNum, difficulty, shipNum, ship2Num, currentTrack, currentTrackBorder, ship, ship2, hud, hud2, aliveShipCount, ghostShipGroupNode, shipNames, gameMode, enemies, roundsNum, flightMode, shieldSphere, damageSphere, ships, bombUpgraded, minesUpgraded, waveUpgraded, speedupUpgraded, damageUpgraded, postProcessingLevel, highscoreTrackNum, trackName, multiCore, trackProperties, phongShader, damageSphereNode, shieldSphereNode, particleNode, animatedTextureShader, mineNode, spriteNode, mineMesh, bombMesh, dynamicNode, accelerometerSensitivity, accelWeapon, steeringMode;

+ (void)initialize
{
#ifdef TARGET_OS_IPHONE
	[CoreBreach initialize];
#endif
}

- (id)init
{
	if ((self = [super init]))
	{
		NSAutoreleasePool *pool;
		pool = [[NSAutoreleasePool alloc] init];

//        wrongShips = [[NSMutableDictionary alloc] init];
#ifndef TARGET_OS_IPHONE
       if ($defaulti(kPlayer1InputDeviceIndexKey) || $defaulti(kPlayer2InputDeviceIndexKey))
            [[HIDSupport sharedInstance] startHID];
#else
		steeringMode = $defaulti(kIOSControlMethod);
		accelWeapon = $defaulti(kIOSFireAccel);
#endif

		if (game != nil)
			fatal("Error: cannot initialize the game twice");

		gameMode = (gameModeEnum) $defaulti(kGameModeKey);
		game = self;
		lodMode = $defaulti(kModelQualityKey);
		postProcessingLevel = $defaulti(kPostProcessingKey);
		multiCore = $defaulti(kMultiplayerEnableCorebreachesKey);
		accelerometerSensitivity = $defaultf(kIOSAccelSensitivity);

		if (gameMode == kGameModeCareer)
		{
#ifndef TARGET_OS_IPHONE
			trackNum = CareerPopupToReal($defaulti(kTrackNumKey));
#else
			trackNum = $defaulti(kTrackNumKey);
#endif
			enemiesNum = 8;
			if (trackNum + 1 == 6)
				enemiesNum = 12;
			if (trackNum + 1 == 12)
				enemiesNum = 1;
			shipNum = $defaulti(kShipNumKey);
			difficulty = $defaulti(kDifficultyKey);

			bombUpgraded = $defaulti(kBombUpgraded);
			speedupUpgraded = $defaulti(kSpeedupUpgraded);
			minesUpgraded = $defaulti(kMinesUpgraded);
			waveUpgraded = $defaulti(kWaveUpgraded);
			damageUpgraded = $defaulti(kDamageUpgraded);
		}
		else if (gameMode == kGameModeCustomGame)
		{
			enemiesNum = $defaulti(kCustomraceEnemiesNumKey) + 1;
			trackNum = $defaulti(kCustomraceTrackNumKey);
			shipNum = $defaulti(kCustomraceShipNumKey);
			difficulty = $defaulti(kCustomraceDifficultyKey);
			roundsNum = $defaulti(kCustomraceRoundsNumKey) + 1;
		}
		else if (gameMode == kGameModeTimeAttack)
		{
			enemiesNum = 0;
			trackNum = $defaulti(kTimeattackTrackNumKey);
			shipNum = $defaulti(kTimeattackShipNumKey);
			roundsNum = 250;
		}
		else if (gameMode == kGameModeMultiplayer)
		{
			enemiesNum = $defaulti(kMultiplayerEnemiesNumKey) + 1;
			trackNum = $defaulti(kMultiplayerTrackNumKey);
			shipNum = $defaulti(kMultiplayerShipNumKey);
			ship2Num = $defaulti(kMultiplayerShip2NumKey);
			difficulty = $defaulti(kMultiplayerDifficultyKey);
			roundsNum = $defaulti(kMultiplayerRoundsNumKey) + 1;

//			if (globalSettings.shadowMode > kShipOnly)
//				globalSettings.shadowMode = kShipOnly;
		}

#ifdef TIMEDEMO
        gameMode = kGameModeCustomGame;
        enemiesNum = 8;
        roundsNum = 2;
        trackNum = 5;
#endif
//#warning PVS
//        trackNum = 4;




		highscoreTrackNum = trackNum;
		meshTrackNum = trackNum;
		if (trackNum >= kNumTracks)
			meshTrackNum -= kNumTracks;
		assert(shipNum < kNumShips);

		if (gameMode == kGameModeCareer)
			roundsNum = [[kTrackRounds objectAtIndex:meshTrackNum] intValue];


		if (trackNum >= kNumTracks * 2)
		{

			NSArray *tracks = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:APPLICATION_SUPPORT_DIR error:NULL];
			tracks = [tracks filteredArrayUsingPredicate:$predf(@"self ENDSWITH[cd] '.cbtrack'")];

			trackName = [[tracks objectAtIndex:trackNum - kNumTracks * 2 - 1] stringByDeletingPathExtension];

			meshTrackNum = 222;
			trackNum = 222;
			highscoreTrackNum = [trackName hash];
		}

		if (!trackName)
			globalInfo.pvsCells = [[$array(@"100", @"450", @"425", @"760", @"625", @"676") objectAtIndex:meshTrackNum] intValue];

		RenderPass *multiPass = nil;
		CGRect fr = CGRectMake(0, IS_MULTI ? ([scene bounds].height / 2.0) : 0, [scene bounds].width, IS_MULTI ? ([scene bounds].height / 2.0) : [scene bounds].height);
		RenderPass *mainPass = [[RenderPass alloc] initWithFrame:fr andAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable | (IS_MULTI ? kCALayerMinYMargin : 0)];
		currentRenderPass = mainPass;
		mainPass.settings = kMainRenderPass;



		Light *light = [[Light alloc] init];
		[light setPosition:vector3f(0, 2000, 0)];
		[light setLightDiffuseColor:vector4f(0.9f, 0.9f, 0.9f, 1.0f)];
		[light setLightAmbientColor:vector4f(0.2f, 0.2f, 0.2f, 1.0f)];
		[[mainPass lights] addObject:light];
		assert([[mainPass lights] indexOfObject:light] == 0);



		RenderTarget *mrt = [[RenderTarget alloc] initWithWidthMultiplier:1.0 andHeightMultiplier:1.0];
		[mainPass setRenderTarget:mrt];
		[mrt release];

		if (IS_MULTI)
		{
#ifndef DEMO
			CGRect fr_m = CGRectMake(0, 0, [scene bounds].width, [scene bounds].height / 2.0);
			multiPass = [[RenderPass alloc] initWithFrame:fr_m andAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable | kCALayerMaxYMargin];
			multiPass.settings = kMainRenderPass;

			RenderTarget *ort = [[RenderTarget alloc] initWithWidthMultiplier:1.0 andHeightMultiplier:1.0];
			[multiPass setRenderTarget:ort];
			[[multiPass lights] addObject:light];
			[ort release];
#endif
		}



		SceneNode *sceneNode = [[SceneNode alloc] init];
		OutlineShader *ols = [[OutlineShader alloc] init];


		// lightnums 1player: 0mainlight 1weaponlight 2exhaustlight
		// lightnums 2player: 0mainlight 1exhaustlight 2multiexhaustlight

		GameShader *sceneObjectsLitShader = [[GameShader alloc] initWithLighting:NO enableSpecular:YES enableShadows:NO lightNum1:0 lightNum2:0 isAdditive:NO];
		GameShader *sceneObjectsUnlitShader;

		if ($defaulti(kLightQualityKey))
		{
			sceneObjectsUnlitShader = [[GameShader alloc] initWithLighting:YES enableSpecular:YES enableShadows:NO lightNum1:0 lightNum2:1 isAdditive:NO];


			phongShader = [[ShaderNode alloc] initWithShader:[scene phongTextureShader]];
		}
		else
		{
			sceneObjectsUnlitShader = [sceneObjectsLitShader retain];
			phongShader = [[ShaderNode alloc] initWithShader:[scene textureOnlyShader]];
		}

		GameShader *sceneObjectsLitWithShadowsShader = [[GameShader alloc] initWithLighting:$defaulti(kLightQualityKey) enableSpecular:YES enableShadows:YES lightNum1:1 lightNum2:2 isAdditive:YES];
		GameShader *trackShader = [[GameShader alloc] initWithLighting:$defaulti(kLightQualityKey) enableSpecular:NO enableShadows:YES lightNum1:1 lightNum2:2 isAdditive:YES];
		ShaderNode *textureShader = [[ShaderNode alloc] initWithShader:[scene textureOnlyShader]];
		animatedTextureShader = [[AnimatedTextureShader alloc] init];

		Skybox *skybox = [[Skybox alloc] initWithSurroundTextureNamed:$stringf(@"skybox_north_east_south_west_%i", (trackName ? 1 : meshTrackNum + 1)) andUpTextureNamed:$stringf(@"skybox_up_%i", (trackName ? 1 : meshTrackNum + 1)) andDownTextureNamed:$stringf(@"skybox_down_%i", (trackName ? 1 : meshTrackNum + 1))];



		if (trackName)
		{
			trackProperties = [[[NSString stringWithContentsOfURL:[NSURL fileURLWithPath:[[APPLICATION_SUPPORT_DIR stringByAppendingPathComponent:[trackName stringByAppendingString:@".cbtrack"]] stringByAppendingPathComponent:@"track.xml"]] encoding:NSUTF8StringEncoding error:NULL] propertyList] retain];
			realTrack = [[Mesh alloc] initWithOctree:[NSURL fileURLWithPath:[[APPLICATION_SUPPORT_DIR stringByAppendingPathComponent:[trackName stringByAppendingString:@".cbtrack"]] stringByAppendingPathComponent:@"track.octree"]] andName:trackName];
		}
		else
		{
			NSString *trackPropertiesString = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:$stringf(@"track%i", meshTrackNum + 1) withExtension:@"xml"] encoding:NSUTF8StringEncoding error:NULL];

			//            NSLog([Highscores sha1:trackPropertiesString]);

			NSArray *sha = kTrackSHA1;
			if (![[sha objectAtIndex:meshTrackNum] isEqualToString:[Highscores sha1:trackPropertiesString]])
				fatal("Error: md5 sum mismatch on track property xml %s", [[Highscores sha1:trackPropertiesString] UTF8String]);

			trackProperties = [[trackPropertiesString propertyList] retain];

			realTrack = [[Mesh alloc] initWithOctreeNamed:$stringf(@"track%i", (trackNum == 6) ? 7 : meshTrackNum + 1) andTexureQuality:$numi(0)];
		}

		int anisExponent = $defaulti(kFilterQualityKey);
		float anis = (anisExponent == 0) ? 0 : pow_f(2, anisExponent);


		[[realTrack texture] setAnisotropy:anis];


		[realTrack setShininess:5];
		[realTrack setDoubleSided:YES];

		currentTrack = [[Racetrack alloc] initWithTracknumber:trackNum + 1 andMeshtracknumber:meshTrackNum + 1];

		if (trackName)
			currentTrackBorder = [[CollideableMeshBullet alloc] initWithOctree:[NSURL fileURLWithPath:[[APPLICATION_SUPPORT_DIR stringByAppendingPathComponent:[trackName stringByAppendingString:@".cbtrack"]] stringByAppendingPathComponent:@"trackborder_collision.octree"]] andName:[trackName stringByAppendingString:@"border_collision"]];
		else
			currentTrackBorder = [[CollideableMeshBullet alloc] initWithOctreeNamed:$stringf(@"track%iborder_collision", meshTrackNum + 1)];

		NSMutableArray *sceneObjectsLit = [[NSMutableArray alloc] init];
		NSMutableArray *sceneObjectsLitWithShadows = [[NSMutableArray alloc] init];
		NSMutableArray *sceneObjectsUnlit = [[NSMutableArray alloc] init];

		if (trackName) // add scene objects to scene object shaders
		{
			BOOL done = FALSE;
			int i = 0;
			do
			{
				NSString *p = [[APPLICATION_SUPPORT_DIR stringByAppendingPathComponent:trackName] stringByAppendingPathComponent:$stringf(@"%i.octree", i)];

				if ([[NSFileManager defaultManager] fileExistsAtPath:p])
				{
					NSURL *mu = [NSURL fileURLWithPath:p];
					Mesh *m = [[Mesh alloc] initWithOctree:mu andName:$stringf(@"%i", i)];
					[sceneObjectsLit addObject:m];
					[m release];
				}
				else
					done = TRUE;
			} while (!done);
		}
		else
		{
			int loadTrack = meshTrackNum;
			if (trackNum == 6)
				loadTrack = 6;

			for (NSString *name in [kTrackObjectsNamesLit objectAtIndex:loadTrack])
			{
				Mesh *m = [[Mesh alloc] initWithOctreeNamed:name];
				[sceneObjectsLit addObject:m];
				[m release];
			}

			for (NSString *name in [kTrackObjectsNamesLitWithShadow objectAtIndex:loadTrack])
			{
				Mesh *m = [[Mesh alloc] initWithOctreeNamed:name];
				[sceneObjectsLitWithShadows addObject:m];
				[m release];
			}

			for (NSString *name in [kTrackObjectsNamesUnlit objectAtIndex:loadTrack])
			{
				Mesh *m = [[Mesh alloc] initWithOctreeNamed:name];
				[sceneObjectsUnlit addObject:m];
				[m release];
			}
		}


		// create attachment point batch nodes and single meshes for reuse;
		damageSphereNode = [[SceneNode alloc] init];
		shieldSphereNode = [[SceneNode alloc] init];
		mineNode = [[SceneNode alloc] init];
		particleNode = [[SceneNode alloc] init];
		spriteNode = [[SceneNode alloc] init];
		dynamicNode = [[DynamicNode alloc] initWithTextureNamed:kEffectShadowTexture];
		shieldSphere = [[Mesh alloc] initWithOctreeNamed:@"item_sphere_shield"];
		damageSphere = [[Mesh alloc] initWithOctreeNamed:@"item_sphere_damage"];
		[shieldSphere setHasTransparency:YES];
		[damageSphere setHasTransparency:YES];

		mineMesh = [[Mesh alloc] initWithOctreeNamed:@"item_mine"];
		bombMesh = [[Mesh alloc] initWithOctreeNamed:@"item_bomb"];

		[[textureShader children] addObject:spriteNode];
		[[textureShader children] addObject:damageSphereNode];
		[[textureShader children] addObject:shieldSphereNode];
		[[textureShader children] addObject:dynamicNode];
		[[animatedTextureShader children] addObject:mineNode];


		[currentTrack setCollisionShapeTriangleMesh:NO];
		[currentTrackBorder setCollisionShapeTriangleMesh:NO];

		{  // init playership(s)
			shipNames = [kShipOctreeNames copy];
			ship = [[Playership alloc] initWithOctreeNamed:[shipNames objectAtIndex:shipNum] andTexureQuality:$numi(0)];

			[ship setShipNum:shipNum];
			[ship setPlayerNumber:0];
			[ship setCollisionShapeFittingSphere];

			//       [ship setEnemyIndex:0];
			//        [ship setName:@"bla"];
			//        [ship setRound:1];
			//        [ship setNearestTrackpoint:1];
			//        [ship setEnemyIndex:1];
			//        [ship setShipNum:1];
			//        [ship setCollisionShapeSphere:vector3f(0.6, 0.4, 1.3)];

			[ship setPosition:[currentTrack positionAtIndex:0]];
			[ship setRotationFromLookAt:[currentTrack positionAtIndex:1]];
			ship->rp = mainPass;
#ifndef DISABLE_SOUND
#ifndef TIMEDEMO
			if ((globalSettings.soundVolume * $defaultf(kSoundShipVolumeKey) > 0.01) &&
					(!IS_MULTI || !$defaulti(kDisablemultiturbinesKey)) &&
					(!$defaulti(@"timedemo")))
			{
				[ship attachSoundNamed:$stringf(@"turbine%i", shipNum + 1)];
				[ship setPitch:0.5];
				[ship setVolume:$defaultf(kSoundShipVolumeKey)];
				[ship setLooping:YES];
			}
#endif
#endif
			//	[ship setCollisionShapeTriangleMesh:NO];
			//	[ship setCollisionShapeConvexHull:YES];
			//	[ship setCollisionShapeBox:vector3f(2.0f, 2.0f, 2.0f)];

			if (IS_MULTI)
			{
				ship2 = [[Playership alloc] initWithOctreeNamed:[shipNames objectAtIndex:ship2Num]];
				[ship2 setShipNum:ship2Num];
				[ship2 setPlayerNumber:1];
				vector3f cur = [currentTrack positionAtIndex:0];
				[ship2 setPosition:cur];
				[ship2 setRotationFromLookAt:[currentTrack positionAtIndex:1]];
				vector3f next = [currentTrack positionAtIndex:1];
				vector3f up = vector3f(0, 1, 0);
				vector3f perp = cross(up, next - cur).normalize();
				vector3f side = cur + perp * 5;
				[ship2 setPosition:side];
				[ship2 setCollisionShapeFittingSphere];
				ship2->rp = multiPass;

#ifndef DISABLE_SOUND
#ifndef TIMEDEMO
				if ((globalSettings.soundVolume * $defaultf(kSoundShipVolumeKey) > 0.01) &&
						(!IS_MULTI || !$defaulti(kDisablemultiturbinesKey)))
				{
					[ship2 attachSoundNamed:$stringf(@"turbine%i", ship2Num + 1)];
					[ship2 setPitch:0.5];
					[ship2 setVolume:$defaultf(kSoundShipVolumeKey)];
					[ship2 setLooping:YES];
				}
#endif
#endif
			}
		} // END init playership(s)


		{ // init sounds
			BOOL female = $defaulti(kFemaleSoundsetKey);
			if (!trackName)
				sounds.newTrackVoice = LoadSound($stringf(@"track%i", meshTrackNum + 1));
			sounds.incoming = LoadSound(@"incoming");


			sounds.checkpoint = LoadSound($stringf(@"speech_checkpoint_%@male", female ? @"fe" : @""));
			sounds.elimination1 = LoadSound($stringf(@"speech_elimination1_%@male", female ? @"fe" : @""));
			sounds.elimination2 = LoadSound($stringf(@"speech_elimination2_%@male", female ? @"fe" : @""));
			sounds.coremode = LoadSound($stringf(@"speech_coremode_%@male", female ? @"fe" : @""));
			sounds.newship = LoadSound($stringf(@"speech_newship_%@male", female ? @"fe" : @""));

			sounds.go = LoadSound($stringf(@"speech_countdown-go_%@male", female ? @"fe" : @""));
			sounds.one = LoadSound($stringf(@"speech_countdown-one_%@male", female ? @"fe" : @""));
			sounds.two = LoadSound($stringf(@"speech_countdown-two_%@male", female ? @"fe" : @""));
			sounds.three = LoadSound($stringf(@"speech_countdown-three_%@male", female ? @"fe" : @""));


			sounds.first = LoadSound($stringf(@"speech_place-first_%@male", female ? @"fe" : @""));
			sounds.second = LoadSound($stringf(@"speech_place-second_%@male", female ? @"fe" : @""));
			sounds.third = LoadSound($stringf(@"speech_place-third_%@male", female ? @"fe" : @""));
			sounds.bad_result = LoadSound($stringf(@"speech_place-bad-result_%@male", female ? @"fe" : @""));
		} // END init sounds

		if (gameMode == kGameModeTimeAttack) // init ghost
		{
			// NSLog(@"gamemode timeattack");
			ghostShipGroupNode = [[SceneNode alloc] init];
			enemies = [[NSArray alloc] initWithObjects:ghostShipGroupNode, nil];
			[ghostShipGroupNode release];

			if ([[NSUserDefaults standardUserDefaults] doubleForKey:$stringf(@"FastestTimeAttackTrack%iTime", highscoreTrackNum)] < 999)
			{
				NSString *k1 = $stringf(@"FastestTimeAttackTrack%iShip", highscoreTrackNum);
				int ghostShipNum = $defaulti(k1);
				Ghostship *g = [[Ghostship alloc] initWithOctreeNamed:[shipNames objectAtIndex:ghostShipNum]];

				NSString *k2 = $stringf(@"FastestTimeAttackTrack%iData", highscoreTrackNum);
				[g setData:$default(k2)];
				[g setShipNum:ghostShipNum];
				[g setHasTransparency:YES];
				[g setSrcBlend:GL_CONSTANT_ALPHA];
				[g setDstBlend:GL_ONE_MINUS_CONSTANT_ALPHA];
				[[ghostShipGroupNode children] addObject:g];
				[g release];
				//NSLog(@"new ghostship with data %@", [$default(k2) description]);
			}
			// else
			//NSLog(@"no fastest lap? %i %f %f", highscoreTrackNum, (float)[[NSUserDefaults standardUserDefaults] doubleForKey:$stringf(@"FastestTimeAttackTrack%iTime", highscoreTrackNum)], [[NSUserDefaults standardUserDefaults] floatForKey:$stringf(@"FastestTimeAttackTrack%iTime", highscoreTrackNum)]);

		}
		else // init enemies
		{
			NSMutableArray *tmpEnemies = [[NSMutableArray alloc] init];
			NSMutableArray *tmpNames;
			NSArray *allEnemies;

			if ((trackNum + 1 == 12) && (gameMode == kGameModeCareer))
			{
				Enemyship *endgegner = [[Enemyship alloc] initWithOctreeNamed:[shipNames objectAtIndex:6]];

				tmpNames = [NSMutableArray arrayWithObject:@"Reeper"];
				allEnemies = [[NSArray alloc] initWithObjects:endgegner, nil];
			}
			else
			{
				Enemyship *e1 = [[Enemyship alloc] initWithOctreeNamed:[shipNames objectAtIndex:0]];
				Enemyship *e2 = [[Enemyship alloc] initWithOctreeNamed:[shipNames objectAtIndex:1]];
				Enemyship *e3 = [[Enemyship alloc] initWithOctreeNamed:[shipNames objectAtIndex:2]];
				Enemyship *e4 = [[Enemyship alloc] initWithOctreeNamed:[shipNames objectAtIndex:3]];
				Enemyship *e5 = [[Enemyship alloc] initWithOctreeNamed:[shipNames objectAtIndex:4]];
				Enemyship *e6 = [[Enemyship alloc] initWithOctreeNamed:[shipNames objectAtIndex:5]];

				Enemyship *e7 = [e1 copy];
				Enemyship *e8 = [e2 copy];
				Enemyship *e9 = [e3 copy];
				Enemyship *e10 = [e4 copy];
				Enemyship *e11 = [e5 copy];
				Enemyship *e12 = [e6 copy];

				tmpNames = [NSMutableArray arrayWithArray:kEnemyNames];
				allEnemies = [[NSArray alloc] initWithObjects:e1, e2, e3, e4, e5, e6, e7, e8, e9, e10, e11, e12, nil];
			}

			int i = 0;
			for (Enemyship *enemy in allEnemies)
			{
				if (i < enemiesNum)
				{
					int nameIndex = cml::random_integer(0, [tmpNames count] - 1);
					[enemy setName:[tmpNames objectAtIndex:nameIndex]];
					[tmpNames removeObjectAtIndex:nameIndex];

					// only increase halfway with track length
					int bla = (enemiesNum < 8) ? (7 - i) : i;
					[enemy setNearestTrackpoint:((bla) * (20 + [currentTrack trackPoints] / 115) + ([currentTrack trackPoints] - 180)) % [currentTrack trackPoints]];
					if ([enemy nearestTrackpoint] < [currentTrack trackPoints] / 2)
						[enemy setRound:1];
					else
						[enemy setRound:0];



					[enemy setEnemyIndex:i];
					[enemy setShipNum:i % 6];

#ifndef DISABLE_SOUND
					if (!IS_MULTI && globalSettings.soundVolume * $defaultf(kSoundEnemyShipsVolumeKey) > 0.01)
					{
						if ((trackNum + 1 == 12) && (gameMode == kGameModeCareer))
							[enemy attachSoundNamed:@"turbine7-mono"];
						else
							[enemy attachSoundNamed:$stringf(@"turbine%i-mono", i % 6 + 1)];
						[enemy setPitch:0.5];
						[enemy setVolume:$defaultf(kSoundEnemyShipsVolumeKey)];
						[enemy setLooping:YES];
						[enemy setProperty:AL_ROLLOFF_FACTOR toValue:1.0];
					}
#endif

					i++;
					[tmpEnemies addObject:enemy];
				}
				[enemy release];
			}
//            NSMutableArray *tmpEnemies = [[NSMutableArray alloc] init];
//            for (int i = 0; i < 99; i++)
//            {
//                Enemyship *enemy = [[Enemyship alloc] initWithOctreeNamed:[shipNames objectAtIndex:i % 6]];
//
//                [enemy setEnemyIndex:i];
//
//                [enemy setNearestTrackpoint:i * 10];
//                [enemy setCollisionShapeSphere:vector3f(0.4, 0.4, 1.3)];
//                [enemy setRound:0];
//                [enemy setShipNum:i%6];
//                [tmpEnemies addObject:enemy];
//                [enemy release];
//            }

			enemies = [[NSArray alloc] initWithArray:tmpEnemies];
			[tmpEnemies addObject:ship];
			if (IS_MULTI)
				[tmpEnemies addObject:ship2];
			ships = [[NSArray alloc] initWithArray:tmpEnemies];

			[tmpEnemies release];
			[allEnemies release];
		}

		SceneNode *bonusboxNode = [[SceneNode alloc] init];
		SceneNode *speedboxNode = [[SceneNode alloc] init];

		if (gameMode != kGameModeTimeAttack) // init bonusboxen
		{
			NSMutableArray *bbx = [NSMutableArray array];

			Mesh *bb = [[Mesh alloc] initWithOctreeNamed:@"item_bonusbox"];
			Mesh *sb = [[Mesh alloc] initWithOctreeNamed:@"item_speedbox"];

			[bb setHasTransparency:TRUE];
			[sb setHasTransparency:TRUE];

			[bb setContributionCullingDistance:BOX_CONTRIBUTION_CULLING_DISTANCE];
			[sb setContributionCullingDistance:BOX_CONTRIBUTION_CULLING_DISTANCE];

			//#ifndef WIN32
			int bonusNum = [[trackProperties objectForKey:@"bonusboxen"] intValue];
			int speedNum = [[trackProperties objectForKey:@"speedboxen"] intValue];

//#ifdef TARGET_OS_IPHONE
//            bonusNum = speedNum = 0;
//#endif
			for (int i = 0; i < bonusNum + speedNum; i++)
			{
				BOOL isBonus = (i < bonusNum);
				BonusBox *bonusBoxSuperNode = [[BonusBox alloc] init];

				[bonusBoxSuperNode setIsSpeedbox:!isBonus];
				float size = (iOS) ? 1.75 : 1.5;
				[bonusBoxSuperNode setCollisionShapeSphere:vector3f(size, size, size)];

				int _index = cml::random_integer(60, [currentTrack trackPoints] - 20);
//                int _index = cml::random_integer([currentTrack trackPoints] - 70, [currentTrack trackPoints] - 5);


				vector3f pos;
				if ((trackNum + 1 == 12) && (gameMode == kGameModeCareer) && isBonus && (cml::random_integer(0, 4) == 0))
					pos = [currentTrack positionAtIndex:_index forEnemy:0];
				else
					pos = [currentTrack positionAtIndex:_index];

				if (!isBonus)
				{
					//NSLog(@"placing speedbox %i %i", [[kTrackBonusboxes objectAtIndex:meshTrackNum] intValue],  [[kTrackSpeedboxes objectAtIndex:meshTrackNum] intValue]);

					vector3f up = vector3f(0, 1, 0);
					vector3f next = [currentTrack positionAtIndex:_index + 1];

					vector3f perp = cross(up, next - pos).normalize();
					int rand = cml::random_integer(-6, 6);
					rand += (rand > 0) ? 6 : -6;
					vector3f side = pos + perp * rand;
					pos = side;
				}

				vector3f intersectionPoint = [currentTrack intersectWithLineStart:(pos + vector3f(0.0f, 100.0f, 0.0f)) end:(pos + vector3f(0.0f, -100.0f, 0.0f))];
				if ((intersectionPoint[0] != FLT_MAX) || (intersectionPoint[1] != FLT_MAX) || (intersectionPoint[2] != FLT_MAX))
					[bonusBoxSuperNode setPosition:vector3f(pos[0], intersectionPoint[1] + Y_OFFSET + Y_EXTRABB_OFFSET, pos[2])];
				else
				{
					NSLog(@"Warning: couldn't properly place bonusbox");
					[bonusBoxSuperNode setPosition:pos];
				}

				[bonusBoxSuperNode setRotation:vector3f(0, cml::random_real(0.0, 360.0), 0)];
				[bonusBoxSuperNode attachSoundNamed:isBonus ? @"collision_bonus" : @"collision_speed"];

				[bbx addObject:bonusBoxSuperNode];

				[[bonusBoxSuperNode children] addObject:isBonus ? bb : sb];

				[bonusBoxSuperNode setShadowOrientation:[currentTrack positionAtIndex:_index + 1] - pos];

				[[(isBonus ? bonusboxNode : speedboxNode) children] addObject:bonusBoxSuperNode];

				[bonusBoxSuperNode release];
			}
//#endif
			[bb release];
			[sb release];
			bonusboxen = [[NSArray alloc] initWithArray:bbx];
		}


		if (!trackName) // add TV and cambot for real tracks
		{
			if (globalInfo.gpuSuckynessClass <= 1)
			{
				heliMesh = [[Mesh alloc] initWithOctreeNamed:@"item_cambot"];
				[heliMesh setEnabled:NO];

				heliData1 = [[NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:$stringf(@"track%i", meshTrackNum + 1) withExtension:@"ghost1"]] retain];
				heli1 = [[SceneNode alloc] init];
				[[heli1 children] addObject:heliMesh];

				[heliMesh release];
			}
			if (globalInfo.gpuSuckynessClass == 0)
			{
				heliData2 = [[NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:$stringf(@"track%i", meshTrackNum + 1) withExtension:@"ghost2"]] retain];
				heli2 = [[SceneNode alloc] init];
				[[heli2 children] addObject:heliMesh];

				heliData3 = [[NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:$stringf(@"track%i", meshTrackNum + 1) withExtension:@"ghost3"]] retain];
				heli3 = [[SceneNode alloc] init];
				[[heli3 children] addObject:heliMesh];
			}
#ifndef NODATA
			PlasmaShader *ps = [[PlasmaShader alloc] init];
			Mesh *tv = [[Mesh alloc] initWithOctreeNamed:$stringf(@"track%i_TV", (trackNum == 6) ? 7 : meshTrackNum + 1)];
			[[ps children] addObject:tv];

			[[sceneNode children] addObject:ps];
			[tv release];
			[ps release];
#endif
		}

#ifndef NODATA
		{  // customize tracks
			if (trackNum + 1 == 1)
			{
				//  [heli1 setPosition:vector3f(1191.328 * 0.2, -22.286 * 0.2, 1165.992 * 0.2)];



				Mesh *roehre = [[Mesh alloc] initWithOctreeNamed:@"track1_Roehre_Hive"];
				Mesh *k1 = [[Mesh alloc] initWithOctreeNamed:@"track1_K1"];
				Mesh *k2 = [[Mesh alloc] initWithOctreeNamed:@"track1_K2"];
				Mesh *k3 = [[Mesh alloc] initWithOctreeNamed:@"track1_K3"];
				Mesh *k4 = [[Mesh alloc] initWithOctreeNamed:@"track1_K4"];
				Mesh *p1 = [[Mesh alloc] initWithOctreeNamed:@"track1_P1"];
				Mesh *p2 = [[Mesh alloc] initWithOctreeNamed:@"track1_P2"];


				[roehre setPosition:vector3f(1203.963 * 0.2, -37.646 * 0.2, 1161.679 * 0.2)];
				[k1 setPosition:vector3f(1838.47 * 0.2, 1641.481 * 0.2, -4685.546 * 0.2)];
				[k2 setPosition:vector3f(1838.47 * 0.2, 1682.624 * 0.2, -4685.546 * 0.2)];
				[k3 setPosition:vector3f(-1967.063 * 0.2, 1103.164 * 0.2, -4781.646 * 0.2)];
				[k4 setPosition:vector3f(-1967.063 * 0.2, 1138.094 * 0.2, -4781.646 * 0.2)];
				[p1 setPosition:vector3f(1837.917 * 0.2, 673.636 * 0.2, -4693.824 * 0.2)];
				[p2 setPosition:vector3f(-1968.554 * 0.2, 305.5 * 0.2, -4790.32 * 0.2)];

				[sceneObjectsLit addObject:roehre];
				[sceneObjectsLit addObject:k1];
				[sceneObjectsLit addObject:k2];
				[sceneObjectsLit addObject:k3];
				[sceneObjectsLit addObject:k4];
				[sceneObjectsLit addObject:p1];
				[sceneObjectsLit addObject:p2];


				[roehre release];
				[k1 release];
				[k2 release];
				[k3 release];
				[k4 release];
				[p1 release];
				[p2 release];


				[self addAnimationWithDuration:999.0
				                     animation:^(double delay)
				                     {
					                     [roehre setRotation:vector3f(delay * 10.0f, 0.0f, 0.0f)];

					                     [k1 setRotation:vector3f(0, delay * 40, 0)];
					                     [k2 setRotation:vector3f(0, delay * -50, 0)];
					                     [k3 setRotation:vector3f(0, delay * 60, 0)];
					                     [k4 setRotation:vector3f(0, delay * -70, 0)];


					                     [p1 setPosition:vector3f(1837.917 * 0.2, 673.636 * 0.2 + sinf(delay * M_PI / 1.2) * 140, -4693.824 * 0.2)];
					                     [p2 setPosition:vector3f(-1968.554 * 0.2, 305.5 * 0.2 + sinf(delay * M_PI / 1.2) * 140, -4790.32 * 0.2)];
				                     }
						            completion:^
						            {}];
			}
			else if (meshTrackNum + 1 == 2)
			{

				Mesh *roehre = [[Mesh alloc] initWithOctreeNamed:@"track2_Roehre_Hive"];
				[sceneObjectsLit addObject:roehre];
				[roehre setPosition:vector3f(2358.588 * 0.2, 412.516 * 0.2, 1781.433 * 0.2)];
				[roehre release];



				Mesh *turbine1 = [[Mesh alloc] initWithOctreeNamed:@"track2_Turbine_1"];
				Mesh *turbine2 = [[Mesh alloc] initWithOctreeNamed:@"track2_Turbine_2"];


				[turbine1 setPosition:vector3f(-312.22 * 0.2, 548.726 * 0.2, 1121.505 * 0.2)];
				[turbine2 setPosition:vector3f(1187.024 * 0.2, 548.296 * 0.2, 1077.722 * 0.2)];

				[turbine1 setRotation:vector3f(0, 5.659, 0)];
				[turbine2 setRotation:vector3f(0, -3.154, 0)];

				[sceneObjectsLit addObject:turbine1];
				[sceneObjectsLit addObject:turbine2];

				[turbine1 release];
				[turbine2 release];


				Mesh *pumpe1 = [[Mesh alloc] initWithOctreeNamed:@"track2_Pumpe1"];
				Mesh *pumpe2 = [[Mesh alloc] initWithOctreeNamed:@"track2_Pumpe2"];


				[pumpe1 setPosition:vector3f(-2809.649 * 0.2, 819.693 * 0.2, 3186.937 * 0.2)];
				[pumpe2 setPosition:vector3f(-2821.019 * 0.2, 1340.048 * 0.2, 3190.606 * 0.2)];



				[sceneObjectsLit addObject:pumpe1];
				[sceneObjectsLit addObject:pumpe2];

				[pumpe1 release];
				[pumpe2 release];


				Mesh *s1 = [[Mesh alloc] initWithOctreeNamed:@"track2_S1"];
				Mesh *s2 = [[Mesh alloc] initWithOctreeNamed:@"track2_S2"];
				Mesh *s3 = [[Mesh alloc] initWithOctreeNamed:@"track2_S3"];


				[s1 setPosition:vector3f(7541.875 * 0.2, 647.848 * 0.2, 4008.792 * 0.2)];
				[s2 setPosition:vector3f(5290.426 * 0.2, 467.603 * 0.2, 947.515 * 0.2)];
				[s3 setPosition:vector3f(6488.585 * 0.2, 569.937 * 0.2, 1276.109 * 0.2)];



				[sceneObjectsLit addObject:s1];
				[sceneObjectsLit addObject:s2];
				[sceneObjectsLit addObject:s3];

				[s1 release];
				[s2 release];
				[s3 release];


				[game addAnimationWithDuration:999.0
				                     animation:^(double delay)
				                     {
					                     [roehre setRotation:vector3f(delay * 10, 0, 0)];

					                     [turbine1 setRotation:vector3f(0, 5.659, delay * 500)];
					                     [turbine2 setRotation:vector3f(0, -3.154, delay * 500)];

					                     [pumpe1 setPosition:vector3f(-2809.649 * 0.2, 819.693 * 0.2 + sinf(delay * M_PI / 1.2) * 180, 3186.937 * 0.2)];
					                     [pumpe2 setPosition:vector3f(-2821.019 * 0.2, 1340.048 * 0.2 + sinf(delay * M_PI / 0.3) * 50, 3190.606 * 0.2)];


					                     [s1 setRotation:vector3f(0, delay * 100.0, 0)];
					                     [s2 setRotation:vector3f(0, delay * 100.0, 0)];
					                     [s3 setRotation:vector3f(0, delay * 100.0, 0)];
				                     }
						            completion:^
						            {}];
			}
			else if (meshTrackNum + 1 == 3)
			{
				Mesh *turbine = [[Mesh alloc] initWithOctreeNamed:@"track3_Turbine"];
				SceneNode *turbine1 = [[SceneNode alloc] init];
				SceneNode *turbine2 = [[SceneNode alloc] init];

				[[turbine1 children] addObject:turbine];
				[[turbine2 children] addObject:turbine];

				[turbine1 setPosition:vector3f(188.1174, 104.9746, 929.4564)];
				[turbine2 setPosition:vector3f(3.709, 104.9746, 790.1208)];

				[turbine1 setRotation:vector3f(0, -45.036, 0)];
				[turbine2 setRotation:vector3f(0, -26.695, 0)];



				[sceneObjectsLit addObject:turbine1];
				[sceneObjectsLit addObject:turbine2];

				[turbine release];
				[turbine1 release];
				[turbine2 release];

				Mesh *bohrer = [[Mesh alloc] initWithOctreeNamed:@"track3_Bohrer"];
				SceneNode *bohrer1 = [[SceneNode alloc] init];
				SceneNode *bohrer2 = [[SceneNode alloc] init];

				[[bohrer1 children] addObject:bohrer];
				[[bohrer2 children] addObject:bohrer];

				[bohrer1 setPosition:vector3f(1542.762, 30.7746, 1087.623)]; // y 270,7746
				[bohrer2 setPosition:vector3f(-3084.0582, -8.3178, 778.5454)];

				[bohrer1 setRotation:vector3f(0, 125.374, 0)];
				[bohrer2 setRotation:vector3f(0, 17.505, 0)];


				[sceneObjectsLit addObject:bohrer1];
				[sceneObjectsLit addObject:bohrer2];

				[bohrer release];
				[bohrer1 release];
				[bohrer2 release];

				Mesh *ships1 = [[Mesh alloc] initWithOctreeNamed:@"track3_Ships1"];
				Mesh *ships2 = [[Mesh alloc] initWithOctreeNamed:@"track3_Ships2"];
				Mesh *ships3 = [[Mesh alloc] initWithOctreeNamed:@"track3_Ships3"];

				[sceneObjectsLit addObject:ships1];
				[sceneObjectsLit addObject:ships2];
				[sceneObjectsLit addObject:ships3];

				[ships1 release];
				[ships2 release];
				[ships3 release];

				[game addAnimationWithDuration:999.0
				                     animation:^(double delay)
				                     {
					                     [bohrer1 setRotation:vector3f(((sinf(delay * M_PI) + 1) / 2.0) * -65.0, 125.374, 0)];
					                     [bohrer2 setRotation:vector3f(((sinf(delay * M_PI) + 1) / 2.0) * -65.0 + 33.0, 17.505, 0)];

					                     [turbine1 setRotation:vector3f(0, -45.036, delay * 500)];
					                     [turbine2 setRotation:vector3f(0, -26.695, delay * 500)];

					                     [ships1 setRotation:vector3f(0, [ships1 rotation][1] + (sinf(delay) + 2.0 * cosf(delay / 3) + 4.0) / 30.0, 0)];
					                     [ships2 setRotation:vector3f(0, delay * 10, 0)];
					                     [ships3 setRotation:vector3f(0, delay * 15, 0)];
				                     }
						            completion:^
						            {}];
			}
			else if (meshTrackNum + 1 == 4)
			{
				Mesh *roehre = [[Mesh alloc] initWithOctreeNamed:@"track4_Roehre_Hive"];
				[sceneObjectsLit addObject:roehre];
				[roehre setPosition:vector3f(1483.976 * 0.2, 59.046 * 0.2, 1785.17 * 0.2)];
				[roehre release];

				Mesh *turbine = [[Mesh alloc] initWithOctreeNamed:@"track4_Turbine"];

				[turbine setPosition:vector3f(3684.082 * 0.2, 1017.48 * 0.2, 6271.525 * 0.2)];

				[sceneObjectsLit addObject:turbine];

				[turbine release];


				Mesh *windrad = [[Mesh alloc] initWithOctreeNamed:@"track4_Windrad"];

				SceneNode *w1 = [[SceneNode alloc] init];
				SceneNode *w2 = [[SceneNode alloc] init];
				SceneNode *w3 = [[SceneNode alloc] init];
				SceneNode *w4 = [[SceneNode alloc] init];



				[[w1 children] addObject:windrad];
				[[w2 children] addObject:windrad];
				[[w3 children] addObject:windrad];
				[[w4 children] addObject:windrad];

				[w1 setPosition:vector3f(-9515.754 * 0.2, 2766.86 * 0.2, 11436.423 * 0.2)];
				[w2 setPosition:vector3f(-6156.764 * 0.2, 2907.522 * 0.2, 11915.721 * 0.2)];
				[w3 setPosition:vector3f(-3438.63 * 0.2, 2658.074 * 0.2, 12772.621 * 0.2)];
				[w4 setPosition:vector3f(-10334.063 * 0.2, 3712.442 * 0.2, 13779.737 * 0.2)];



				[sceneObjectsLit addObject:w1];
				[sceneObjectsLit addObject:w2];
				[sceneObjectsLit addObject:w3];
				[sceneObjectsLit addObject:w4];

				[w1 release];
				[w2 release];
				[w3 release];
				[w4 release];

				[windrad release];

				[game addAnimationWithDuration:999.0
				                     animation:^(double delay)
				                     {
					                     [roehre setRotation:vector3f(delay * 10, 0, 0)];

					                     [turbine setRotation:vector3f(0, delay * 100, 0)];

					                     [w1 setRotation:vector3f(0, -54.709, delay * 410)];
					                     [w2 setRotation:vector3f(0, 0, delay * 420)];
					                     [w3 setRotation:vector3f(0, 0, delay * 430)];
					                     [w4 setRotation:vector3f(0, -25.014, delay * 440)];
				                     }
						            completion:^
						            {}];
			}
			else if (meshTrackNum + 1 == 5)
			{
				Mesh *hammer = [[Mesh alloc] initWithOctreeNamed:@"track5_Schwunghammer"];
				SceneNode *hammer1 = [[SceneNode alloc] init];
				SceneNode *hammer2 = [[SceneNode alloc] init];

				[[hammer1 children] addObject:hammer];
				[[hammer2 children] addObject:hammer];

				[hammer1 setPosition:vector3f(-1867.2072, 509.274, -56.4872)];
				[hammer2 setPosition:vector3f(-1229.733, 357.5108, -1389.2234)];

				[hammer1 setRotation:vector3f(0, 122.08, 0)];
				[hammer2 setRotation:vector3f(0, 131.105, 0)];


				[sceneObjectsLit addObject:hammer1];
				[sceneObjectsLit addObject:hammer2];

				[hammer release];
				[hammer1 release];
				[hammer2 release];


				Mesh *roehrehoehle = [[Mesh alloc] initWithOctreeNamed:@"track5_Roehre_in_Hoehle"];

				[sceneObjectsLit addObject:roehrehoehle];

				[roehrehoehle setPosition:vector3f(-537.109 * 0.2, 188.957 * 0.2, -6837.175 * 0.2)];

				[roehrehoehle release];

				Mesh *roehreziel = [[Mesh alloc] initWithOctreeNamed:@"track5_Roehre_vorm_Ziel"];

				[sceneObjectsLit addObject:roehreziel];

				[roehreziel setPosition:vector3f(3801.796 * 0.2, 66.715 * 0.2, 1938.791 * 0.2)];

				[roehreziel release];

				Mesh *roehrestart = [[Mesh alloc] initWithOctreeNamed:@"track5_Roehre_nach_dem_Start"];

				[sceneObjectsLit addObject:roehrestart];

				[roehrestart setPosition:vector3f(2224.3374, 111.751, 933.1578)];

				[roehrestart release];


				Mesh *roehre = [[Mesh alloc] initWithOctreeNamed:@"track5_Roehre_HIVE"];

				[sceneObjectsLit addObject:roehre];

				[roehre setPosition:vector3f(1131.715, 11.7052, 381.4328)];

				[roehre release];


				[game addAnimationWithDuration:999.0
				                     animation:^(double delay)
				                     {
					                     [roehre setRotation:vector3f(delay * 10, 0, 0)];

					                     [hammer1 setRotation:vector3f(0, 122.08, sinf(delay * M_PI / 4.0) * 80)];
					                     [hammer2 setRotation:vector3f(0, 131.105, sinf((delay + 1) * M_PI / 4.0) * 20 + 20)];


					                     [roehreziel setRotation:vector3f(delay * 9, 0, 0)];
					                     [roehrestart setRotation:vector3f(0, delay * 11, 0)];
					                     [roehrehoehle setRotation:vector3f(0, -delay * 22, 0)];
				                     }
						            completion:^
						            {}];
			}
			else if (meshTrackNum + 1 == 6)
			{

				Mesh *roehre = [[Mesh alloc] initWithOctreeNamed:@"track6_Roehre_Hive"];

				[sceneObjectsLit addObject:roehre];

				[roehre setPosition:vector3f(1789.087 * 0.2, 59.864 * 0.2, 1513.006 * 0.2)];

				[roehre release];


				Mesh *dreh = [[Mesh alloc] initWithOctreeNamed:@"track6_Drehflaechen"];

				[sceneObjectsLit addObject:dreh];

				[dreh setPosition:vector3f(-15910.911 * 0.2, 4965.587 * 0.2, -1901.415 * 0.2)];

				[dreh release];


				Mesh *kugel1 = [[Mesh alloc] initWithOctreeNamed:@"track6_Kugel_1"];
				Mesh *kugel2 = [[Mesh alloc] initWithOctreeNamed:@"track6_Kugel_2"];
				Mesh *kugel3 = [[Mesh alloc] initWithOctreeNamed:@"track6_Kugel_3"];

				[sceneObjectsLit addObject:kugel1];
				[sceneObjectsLit addObject:kugel2];
				[sceneObjectsLit addObject:kugel3];

				[kugel1 setPosition:vector3f(-4714.353 * 0.2, 1466.985 * 0.2, 1039.535 * 0.2)];
				[kugel2 setPosition:vector3f(-4714.353 * 0.2, 1466.985 * 0.2, 1039.535 * 0.2)];
				[kugel3 setPosition:vector3f(-4714.353 * 0.2, 1466.985 * 0.2, 1039.535 * 0.2)];

				[kugel1 release];
				[kugel2 release];
				[kugel3 release];


				[game addAnimationWithDuration:999.0
				                     animation:^(double delay)
				                     {
					                     [roehre setRotation:vector3f(delay * 20, 0, 0)];
					                     [dreh setRotation:vector3f(0, delay * 10, 0)];
					                     [kugel1 setRotation:vector3f(delay * 30, 0, 0)];
					                     [kugel2 setRotation:vector3f(0, 0, delay * 25)];
					                     [kugel3 setRotation:vector3f(0, delay * 20, 0)];
				                     }
						            completion:^
						            {}];
			}
			if (trackNum + 1 == 7)
			{
				//   [heli1 setPosition:vector3f(1191.328 * 0.2, -22.286 * 0.2, 1165.992 * 0.2)];


#ifdef __APPLE__
				Mesh *felsen = [sceneObjectsUnlit objectAtIndex:[sceneObjectsUnlit indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop)
				{return ([[(SceneNode *) obj name] isEqualToString:$stringf(@"track%i_Felsen", trackNum + 1)]);}]];
				[felsen setSpecularColor:vector4f(0.2, 0.2, 0.2, 1.0)];
#endif



				Mesh *roehre = [[Mesh alloc] initWithOctreeNamed:@"track7_Roehre_Hive"];

				[sceneObjectsLit addObject:roehre];

				[roehre setPosition:vector3f(1191.328 * 0.2, -22.286 * 0.2, 1165.992 * 0.2)];

				[game addAnimationWithDuration:999.0
				                     animation:^(double delay)
				                     {[roehre setRotation:vector3f(delay * 10, 0, 0)];}
						            completion:^
						            {}];
				[roehre release];
			}
		} // END customize tracks
#endif




		// attach camera to ship
		[[mainPass camera] setFov:kGameFov];
		[[mainPass camera] setRelativeModeTargetFactor:vector3f(1.0, 1.0, $defaultf(kTiltCameraKey))];
		//		[[mainPass camera] setRelativeModeTarget:ship];

		[scene setMainRenderPass:mainPass];
		[ship setAttachedCamera:[mainPass camera]];
		hud = [[HUD alloc] initWithPlayership:ship];
		[ship setOurHUD:hud];



		if (IS_MULTI)
		{
			[[multiPass camera] setFov:kGameFov];
			[[multiPass camera] setRelativeModeTargetFactor:vector3f(1.0, 1.0, $defaultf(kTiltCameraKey))];
			[[multiPass camera] setRelativeModeTarget:ship2];
			[ship2 setAttachedCamera:[multiPass camera]];
			[ship2 adjustCamera:NO];
			hud2 = [[HUD alloc] initWithPlayership:ship2];
			[ship2 setOurHUD:hud2];
		}


		// add objects to scenegraph
		[[sceneObjectsLitWithShadowsShader children] addObjectsFromArray:sceneObjectsLitWithShadows];
		[[sceneObjectsLitShader children] addObjectsFromArray:sceneObjectsLit];
		[[sceneObjectsUnlitShader children] addObjectsFromArray:sceneObjectsUnlit];
		[[trackShader children] addObject:realTrack];



		[[ols children] addObjectsFromArray:$array(trackShader, phongShader, sceneObjectsLitShader, sceneObjectsUnlitShader, sceneObjectsLitWithShadowsShader)];

		if (!IS_TIMEDEMO)
			[[phongShader children] addObject:ship];

		if (IS_MULTI)
			[[phongShader children] addObject:ship2];



		[[phongShader children] addObjectsFromArray:enemies];



		[[phongShader children] addObject:bonusboxNode];
		[[phongShader children] addObject:speedboxNode];



		if (heli1) [[phongShader children] addObject:heli1];
		if (heli2) [[phongShader children] addObject:heli2];
		if (heli3) [[phongShader children] addObject:heli3];
		[heli1 release];
		[heli2 release];
		[heli3 release];


		[[textureShader children] addObject:skybox];

		// here
		[[sceneNode children] addObject:ols];

		[[sceneNode children] addObject:animatedTextureShader];
		[[sceneNode children] addObject:textureShader];


		for (SceneNode <Ship> *s in ships)
			[[sceneNode children] addObject:[s powerup]];

		[[sceneNode children] addObject:particleNode];

		[[particleNode children] addObject:[ship fire1]];
		[[particleNode children] addObject:[ship fire2]];

		if ($defaulti(kParticleQualityKey) == 0 && gameMode != kGameModeTimeAttack)
		{
			for (Enemyship *e in enemies)
			{
				[[particleNode children] addObject:[e fire1]];
				[[particleNode children] addObject:[e fire2]];
			}
		}



		if (IS_MULTI)
		{
			[[particleNode children] addObject:[ship2 fire1]];
			[[particleNode children] addObject:[ship2 fire2]];
		}



		pp = [[PostprocessingShader alloc] init];
		[pp setUpdatesChildren:YES];
		[[pp children] addObjectsFromArray:[sceneNode children]];
		[ship set_ourPP:pp];

		[[mainPass objects] addObject:pp];
		[[mainPass objects] addObject:hud];
		if ([ship spark])
			[[mainPass objects] addObject:[ship spark]];



		[[scene objects] addObject:pp];
		[[scene objects] addObject:hud];

		if (IS_MULTI)
		{
			pp2 = [[PostprocessingShader alloc] init];
			[[pp2 children] addObjectsFromArray:[sceneNode children]];


			[[multiPass objects] addObject:pp2];
			[[multiPass objects] addObject:hud2];
			if ([ship2 spark])
				[[multiPass objects] addObject:[ship2 spark]];

			[[scene objects] addObject:pp2];
			[[scene objects] addObject:hud2];

			[ship2 set_ourPP:pp2];
		}


		if (globalSettings.shadowMode) // add shadow
		{
			int shadowmapsize = 0;
			if (globalSettings.shadowSize == 0)
				shadowmapsize = 128;
			else if (globalSettings.shadowSize == 1)
				shadowmapsize = 256;
			else if (globalSettings.shadowSize == 2)
				shadowmapsize = 512;

			RenderPass *sp = [RenderPass shadowRenderPassWithSize:shadowmapsize light:light casters:[NSArray arrayWithObject:ship] andMainCamera:[mainPass camera]];

			if (shipNum == kNumShips - 1)
				[(FocusingCamera *) [sp camera] setFovFactor:2.5f];

			[[trackShader shadowRenderpasses] addObject:sp];
			[[sceneObjectsLitWithShadowsShader shadowRenderpasses] addObject:sp];

			[[scene renderpasses] addObject:sp];

			if (IS_MULTI)
			{
				RenderPass *_sp = [RenderPass shadowRenderPassWithSize:shadowmapsize light:light casters:[NSArray arrayWithObject:ship2] andMainCamera:[multiPass camera]];

				if (ship2Num == kNumShips - 1)
					[(FocusingCamera *) [_sp camera] setFovFactor:2.5f];

				[[trackShader shadowRenderpasses] addObject:_sp];
				[[sceneObjectsLitWithShadowsShader shadowRenderpasses] addObject:_sp];

				[[scene renderpasses] addObject:_sp];
			}

//			if (globalSettings.shadowMode > kShipOnly)
//			{
//				if (globalSettings.shadowSize == 0)
//					shadowmapsize = 1024;
//				else if (globalSettings.shadowSize == 1)
//					shadowmapsize = 2048;
//				else if (globalSettings.shadowSize == 2)
//					shadowmapsize = 4096;
//
//				RenderPass *_sp = [RenderPass shadowRenderPassWithSize:shadowmapsize light:light casters:enemies andMainCamera:[mainPass camera]];
//
//				[[trackShader shadowRenderpasses] addObject:_sp];
//                [[sceneObjectsLitWithShadowsShader shadowRenderpasses] addObject:_sp];
//
//				[[scene renderpasses] addObject:sp];
//			}
		}

//        [[realTrack texture] permanentlyBind];
//        for (Mesh *n in [[sceneObjectsLit arrayByAddingObjectsFromArray:sceneObjectsLitWithShadows] arrayByAddingObjectsFromArray:sceneObjectsUnlit])
//            [[n texture] permanentlyBind];




		[[scene renderpasses] addObject:mainPass];

		{ // add exhaust lights
			Light *exhaustLight = [[Light alloc] init];
			[exhaustLight setPosition:vector3f(0.0f, 0.0f, 1.5f)];
			[exhaustLight setRelativeModeTarget:ship];
			[exhaustLight setLinearAttenuation:1.50f];
			[exhaustLight setLightAmbientColor:vector4f(0.50f, 0.50f, 0.50f, 1.0f)];
			[exhaustLight setLightDiffuseColor:vector4f(0.99f, 0.7f, 0.7f, 1.0f)];
			[[mainPass lights] addObject:exhaustLight];
			[ship setExhaustLight:exhaustLight];
			[exhaustLight release];
			if (!IS_MULTI)
			assert([[mainPass lights] indexOfObject:exhaustLight] == 2);


			if (IS_MULTI)
			{
				[[scene renderpasses] addObject:multiPass];

				Light *exhaustLight2 = [[Light alloc] init];
				[exhaustLight2 setLightDiffuseColor:vector4f(0.50f, 0.50f, 0.50f, 1.0f)];
				[exhaustLight2 setLightAmbientColor:vector4f(0.99f, 0.7f, 0.7f, 1.0f)];
				[exhaustLight2 setPosition:vector3f(0.0f, 0.0f, 1.5f)];
				[exhaustLight2 setLinearAttenuation:1.50f];
				[exhaustLight2 setRelativeModeTarget:ship2];
				[ship2 setExhaustLight:exhaustLight2];
				[[mainPass lights] addObject:exhaustLight2];
				[[multiPass lights] addObject:exhaustLight];
				[[multiPass lights] addObject:exhaustLight2];
				assert([[mainPass lights] indexOfObject:exhaustLight] == 1);
				assert([[mainPass lights] indexOfObject:exhaustLight2] == 2);
				assert([[multiPass lights] indexOfObject:exhaustLight] == 1);
				assert([[multiPass lights] indexOfObject:exhaustLight2] == 2);
				[exhaustLight2 release];
			}
		} // END add exhaust lights


#ifdef BUILD_PVS
		NSMutableArray *pvsobjects = [NSMutableArray arrayWithArray:sceneObjectsUnlit];
		[pvsobjects addObjectsFromArray:sceneObjectsLit];
		[pvsobjects addObjectsFromArray:sceneObjectsLitWithShadows];
		[pvsobjects addObject:realTrack];
		[pvsobjects addObject:tv];
		PVSNode *pvs = [[PVSNode alloc] initWithObjectArray:pvsobjects];
		[[scene objects] addObject:pvs];
		[[mainPass objects] addObject:pvs];
#endif

		[[scene objects] addObject:currentTrackBorder];


		[particleNode release];
		[spriteNode release];
		[damageSphereNode release];
		[shieldSphereNode release];
		[mineNode release];
		[bonusboxNode release];
		[speedboxNode release];
		[animatedTextureShader release];
		[textureShader release];
		[sceneNode release];
		[multiPass release];
		[mainPass release];
		[ols release];
		[phongShader release];
		[sceneObjectsLitShader release];
		[sceneObjectsUnlitShader release];
		[sceneObjectsLitWithShadowsShader release];
		[realTrack release];
		[trackShader release];
		[skybox release];
		[light release];
		[pp release];
		[pp2 release];
		[sceneObjectsLit release];
		[sceneObjectsLitWithShadows release];
		[sceneObjectsUnlit release];


#ifdef TARGET_OS_MAC
		[(NSNotificationCenter *)[NSNotificationCenter defaultCenter]
                                              addObserver:self
												 selector:@selector(willResign:)
													 name:NSApplicationWillResignActiveNotification
												   object:NSApp];

		[(NSNotificationCenter *)[NSNotificationCenter defaultCenter]
                                              addObserver:self
												 selector:@selector(willBecome:)
													 name:NSApplicationWillBecomeActiveNotification
												   object:NSApp];
#elif defined(TARGET_OS_IPHONE)
		[[NSNotificationCenter defaultCenter] addObserver:self
		                                         selector:@selector(handleBackground:)
				                                     name:UIApplicationDidEnterBackgroundNotification
					                               object:nil];
#endif
#ifndef TARGET_OS_MAC
		pauseTexture = [Texture newTextureNamed:(gameMode == kGameModeTimeAttack) ? kOverlayOptionsmenuTimeattackTexture : kOverlayOptionsmenuTexture];
		[pauseTexture load];
#endif

		if (IS_MULTI)
			flightMode = kFlightShowShip; // so it will be incremented to countdown

		[self update];



		if (!(trackName ||
				gameMode != kGameModeCareer ||
				(trackNum != 0 && trackNum != 2 && trackNum != 11) ||
				$defaulti($stringf(kStoryISeenKey, trackNum))))
		{
			BOOL spanish = FALSE;
			NSArray *languages = $default(@"AppleLanguages");
			if ([languages indexOfObject:@"es"] != NSNotFound &&
					((([languages indexOfObject:@"es"] < [languages indexOfObject:@"en"]) && ([languages indexOfObject:@"en"] != NSNotFound)) || ([languages indexOfObject:@"en"] == NSNotFound)))
				spanish = TRUE;

			if ([[(NSLocale *) [NSLocale currentLocale] objectForKey:NSLocaleLanguageCode] isEqualToString:@"es"])
				spanish = TRUE;

			storyTex = [Texture newTextureNamed:$stringf(@"story_%i%@", trackNum + 1, spanish ? @"_es" : @"")];

			[storyTex load];
		}

		//   [[[[RenderViewController sharedController] window] contentView] addSubview:button];
		[pool drain];
	}


	return self;
}

- (float)flightTime
{
	return simTime - flightStartTime;
}

- (float)remainingFlightTime
{
	if (flightMode == kFlightShowMap)
		return 10 - [self flightTime];
	else if (flightMode == kFlightShowShip)
		return 7 - [self flightTime];
	else if (flightMode == kFlightShowCountdown)
		return 5 - [self flightTime];
	else
		return 0;
}

- (void)setupFlightMode
{
	if (flightMode == kFlightShowMap)
	{
		[[ship attachedCamera] setAxisConfiguration:kXYZRotation];

		[[ship attachedCamera] setFov:55];


		Play_Sound(sounds.newTrackVoice);

		if (!trackName)
		{
			__block Game *blockSelf = self;

			if (!$defaulti($stringf(kTrackISeenKey, (long)trackNum)))
			{
				[self performBlockAfterDelay:1.0 block:^
				{
					if ([blockSelf flightMode] == kFlightShowMap)
						[hud addMessage:[kTrackNames objectAtIndex:meshTrackNum] urgent:NO];
				}];
			}
			else
			{
				[self performBlockAfterDelay:1.0 block:^
				{
					if ([blockSelf flightMode] == kFlightShowMap)
						[hud addMessage:$stringf(@"%@ - %@", NSLocalizedString(@"New track", nil), [kTrackNames objectAtIndex:meshTrackNum]) urgent:NO];
				}];
			}

			$setdefaulti(YES, $stringf(kTrackISeenKey, (long)trackNum));
			$defaultsync;
		}
	}
	if (flightMode == kFlightShowShip)
	{
		[[ship attachedCamera] setAxisConfiguration:kYXZRotation];
		[[ship attachedCamera] setFov:45];
		[hud addMessage:$stringf(@"%@ - %@", NSLocalizedString(@"New ship", nil), [kShipNames objectAtIndex:shipNum]) urgent:NO];
		Play_Sound(sounds.newship);
	}
	if (flightMode == kFlightShowCountdown)
	{
		[heliMesh setEnabled:YES];

		[[ship attachedCamera] setAxisConfiguration:kYXZRotation];
		[[ship attachedCamera] setFov:45];
		[hud addMessage:NSLocalizedString(@"Prepare for race", nil) urgent:NO];
#ifndef DISABLE_SOUND
		if ((globalSettings.soundVolume * $defaultf(kSoundShipVolumeKey) > 0.01) &&
				(!IS_MULTI || !$defaulti(kDisablemultiturbinesKey)))
			[ship playSound];

		if ((globalSettings.soundVolume * $defaultf(kSoundShipVolumeKey) > 0.01) &&
				(IS_MULTI && !$defaulti(kDisablemultiturbinesKey)))
			[ship2 playSound];


		if (!IS_MULTI && (globalSettings.soundVolume * $defaultf(kSoundEnemyShipsVolumeKey) > 0.01))
			for (Enemyship *e in enemies)
				[e playSound];
#endif
	}
	if (flightMode == kFlightGame)
	{
		[storyTex release];
		storyTex = nil;
		[[ship attachedCamera] setAxisConfiguration:kYXZRotation];
#ifdef TIMEDEMO
        [[ship attachedCamera] setRelativeModeTarget:[enemies objectAtIndex:3]];
#else
		if ($defaulti(@"timedemo"))
			[[ship attachedCamera] setRelativeModeTarget:[enemies objectAtIndex:(enemiesNum / 2)]];
		else
			[[ship attachedCamera] setRelativeModeTarget:ship];
#endif

		[[ship attachedCamera] setFov:kGameFov];
		[ship adjustCamera:NO];

		[ship setRound:0];

//#ifndef TEST
//        [self performBlockAfterDelay:cml::random_real(5, 20) block:^{
//            dispatch_async(dispatch_get_main_queue(), ^{
//
//                [[RenderViewController sharedController] release];
//                [NSBundle loadNibNamed:@"Launcher" owner:NSApp]; });}];
//#endif


		[self performBlockAfterDelay:0.0 block:^
		{Play_Sound(sounds.three);}];
		[self performBlockAfterDelay:1.0 block:^
		{Play_Sound(sounds.two);}];
		[self performBlockAfterDelay:2.0 block:^
		{Play_Sound(sounds.one);}];
		[self performBlockAfterDelay:3.0 block:^
		{Play_Sound(sounds.go);}];
		[self performBlockAfterDelay:6.0 block:^
		{
			UnloadSound(sounds.one);
			UnloadSound(sounds.two);
			UnloadSound(sounds.three);
			UnloadSound(sounds.go);
			UnloadSound(sounds.newship);
		}];


		if ($defaulti(kMusicEnabledKey) && !IS_TIMEDEMO)
		{
			__block HUD *blockHUD = hud;
			musicManager = [[MusicManager alloc] initWithSongs:$default(kMusicNamesKey) andSongChangeBlock:^(NSString *param)
			{[blockHUD addMusic:param];}];
		}
	}
}

- (void)advanceFlightMode
{
	//   NSLog(@"flightmode %i", (int)flightMode);

	static BOOL firstmultifinish = FALSE;

	[hud removeAllMessages];

	if (flightMode == kFlightShowMap)
		UnloadSound(sounds.newTrackVoice);

#ifdef TIMEDEMO
	flightMode = (flightModeEnum)(flightMode + 1);
    if (flightMode == kFlightShowStory)
        flightMode = (flightModeEnum)(flightMode + 1);
    if (flightMode == kFlightShowMap)
        flightMode = (flightModeEnum)(flightMode + 1);
    if (flightMode == kFlightShowShip)
        flightMode = (flightModeEnum)(flightMode + 1);

#else
	flightMode = (flightModeEnum) (flightMode + 1);

	if (flightMode == kFlightShowStory)
	{
		if (trackName ||
				gameMode != kGameModeCareer ||
				(trackNum != 0 && trackNum != 2 && trackNum != 11) ||
				$defaulti($stringf(kStoryISeenKey, trackNum)))
			flightMode = (flightModeEnum) (flightMode + 1);
		else
		{
			$setdefaulti(YES, $stringf(kStoryISeenKey, trackNum));
			$defaultsync;
		}
	}
	if (flightMode == kFlightShowMap)
	{
		if ($defaulti(kDontPresentTrackKey))
			flightMode = (flightModeEnum) (flightMode + 1);
	}
	if (flightMode == kFlightShowShip)
	{
		if ($defaulti($stringf(kShipISeenKey, (long)shipNum)))
			flightMode = (flightModeEnum) (flightMode + 1);
		else
		{
			$setdefaulti(YES, $stringf(kShipISeenKey, (long)shipNum));
			$defaultsync;
		}
	}
#endif

	if (IS_MULTI && (flightMode == kFlightEpilogue) && !firstmultifinish)
	{
		firstmultifinish = TRUE;
		flightMode = kFlightGame;
	}
	else
	{
		flightStartTime = simTime;
		[self setupFlightMode];
	}
//    NSLog(@"increased flightmode to %i", (int)flightMode);
}

- (void)update
{
	[super update];

	for (SceneNode *m in [mineNode children])
		[m setRotation:[m rotation] + vector3f(0.0f, 1.0f, 0.0f)];


	for (Mesh *m in bonusboxen)
		[m setRotation:[m rotation] + vector3f(0.0f, globalInfo.frameDiff * 360.0f / 4.0f, 0.0f)];


	char disabled = 0;
	for (Mesh *e in ships)
		if (![e enabled])
			disabled++;

	aliveShipCount = ([ships count] - disabled);



	//	NSLog(@"update %i %f fm %i", globalInfo.frame, simTime, flightMode);

	if (globalInfo.frame == 0) // whole world visible in frame 0 so it is warmed up ;)
	{
		Camera *cam = [ship attachedCamera];
		if (meshTrackNum == 0)
			[cam setPosition:vector3f(0.0f, 1000.0f, 0.0f)];
		else if (meshTrackNum == 1)
			[cam setPosition:vector3f(0.0f, 4000.0f, 0.0f)];
		else if (meshTrackNum == 2)
			[cam setPosition:vector3f(0.0f, 6000.0f, 0.0f)];
		else if (meshTrackNum == 3)
			[cam setPosition:vector3f(0.0f, 5000.0f, 0.0f)];
		else if (meshTrackNum == 4)
			[cam setPosition:vector3f(0.0f, 6000.0f, 0.0f)];
		else if (meshTrackNum == 5)
			[cam setPosition:vector3f(0.0f, 5000.0f, 0.0f)];

		// TODO

		[cam setRotation:vector3f(-90.0f, 0.0f, 0.0f)];
	}
	else if (globalInfo.frame == 1)
	{
		[self advanceFlightMode];
	}
	else if (flightMode == kFlightShowMap)
	{
		Camera *cam = [ship attachedCamera];

		if (meshTrackNum + 1 == 1)
		{
			[cam setPosition:vector3f(sinf([self flightTime] / 1.75) * 575, 250.0, cosf([self flightTime] / 1.75) * 575)];
			[cam setRotationFromLookAt:vector3f(0.0, 0.0, 0.0)];
			[cam setPosition:[cam position] + vector3f(0.0, 10.0, 0.0)];
			[cam setRotation:[cam rotation] + vector3f(5.0, 0.0, 0)];
		}
		else if (meshTrackNum + 1 == 2)
		{
			[cam setPosition:vector3f(sinf([self flightTime] / 1.75) * 1975, 500, cosf([self flightTime] / 1.75) * 1975)];
			[cam setRotationFromLookAt:vector3f(0.0, 0.0, 0.0)];
			[cam setPosition:[cam position] + vector3f(-400.0, 500.0, 700.0)];
			[cam setRotation:[cam rotation] + vector3f(-10.0, 0.0, 0)];
		}
		else if (meshTrackNum + 1 == 3)
		{
			[cam setPosition:vector3f(sinf([self flightTime] / 1.75) * 1575, 500, cosf([self flightTime] / 1.75) * 1575)];
			[cam setRotationFromLookAt:vector3f(0.0, 0.0, 0.0)];
			[cam setPosition:[cam position] + vector3f(0.0, 10.0, 1000.0)];
			[cam setRotation:[cam rotation] + vector3f(10.0, 0.0, 0)];
		}
		else if (meshTrackNum + 1 == 4)
		{
			float m = [self flightTime] + 8.5;

			[cam setPosition:vector3f(sinf(m / 1.75) * 2675, 500, cosf(m / 1.75) * 2675)];
			[cam setRotationFromLookAt:vector3f(0.0, 0.0, 0.0)];
			[cam setPosition:[cam position] + vector3f(3 * 7.0, 10.0, 3 * -25.0)];
			[cam setRotation:[cam rotation] + vector3f(10.0, 0.0, 0)];
		}
		else if (meshTrackNum + 1 == 5)
		{
			[cam setPosition:vector3f(sinf([self flightTime] / 1.75) * 1975, 500, cosf([self flightTime] / 1.75) * 1775)];
			[cam setRotationFromLookAt:vector3f(0.0, 0.0, 0.0)];
			[cam setPosition:[cam position] + vector3f(0.0, 400.0, 200.0)];
			[cam setRotation:[cam rotation] + vector3f(0.0, 0.0, 0)];
		}
		else if (meshTrackNum + 1 == 6)
		{
			[cam setPosition:vector3f(sinf([self flightTime] / 1.75) * 1575, 500, cosf([self flightTime] / 1.75) * 1575)];
			[cam setRotationFromLookAt:vector3f(0.0, 0.0, 0.0)];
			[cam setPosition:[cam position] + vector3f(0.0, 10.0, 0.0)];
			[cam setRotation:[cam rotation] + vector3f(10.0, 0.0, 0)];
		}
		else // custom
		{
			[cam setPosition:vector3f(sinf([self flightTime] / 1.75) * 575, 250.0, cosf([self flightTime] / 1.75) * 575)];
			[cam setRotationFromLookAt:vector3f(0.0, 0.0, 0.0)];
			[cam setPosition:[cam position] + vector3f(0.0, 100.0, 0.0)];
			[cam setRotation:[cam rotation] + vector3f(5.0, 0.0, 0)];
		}

		if ([self remainingFlightTime] < 0.0)
			[self advanceFlightMode];
	}
	else if (flightMode == kFlightShowShip)
	{
		Camera *cam = [ship attachedCamera];
		[cam setPosition:[ship position] + vector3f(sinf([self flightTime]) * 2.5, 0.0, cosf([self flightTime]) * 1.75)];
		[cam setRotationFromLookAt:[ship position]];

		if ([self remainingFlightTime] < 0.0)
			[self advanceFlightMode];
	}
	else if (flightMode == kFlightShowCountdown)
	{
		Camera *cam = [ship attachedCamera];
		vector3f forward = [ship getLookAt];
		vector3f up = vector3f(0.0, 1.0, 0.0);
		vector3f right = cross(forward, up).normalize();

		[cam setPosition:[ship position] + (right * max((1 - cml::sqr(([self flightTime] - 2) / 2)) * 5, 0.0f) + forward * max((155 - [self flightTime] * 40), -5.0f) + up * 0)];
		[cam setRotationFromLookAt:[ship position]];
		[cam setPosition:[cam position] + vector3f(0, max(10 - [self flightTime] * 2, 0.0f), 0)];

		if ([self remainingFlightTime] < 0.0)
			[self advanceFlightMode];
	}
	else if (flightMode == kFlightGame)
	{
		if (heli1 && heliData1)
		{
			float t = [self flightTime];

			int f = floorf(t * 30.0);


			if (heliData1 &&
					f > 0 &&
					(f * 3 * 2 + 9) * 4 + 3 < (int) [heliData1 length])
			{
				float *d = (float *) [heliData1 bytes];

				vector3fe pos1 (&d[f * 3 * 2]);
				vector3fe rot1 (&d[f * 3 * 2 + 3]);
				vector3fe pos2 (&d[f * 3 * 2 + 6]);
				vector3fe rot2 (&d[f * 3 * 2 + 9]);

				[heli1 setPosition:lerp(pos1, pos2, (t * 30.0) - f)];
				[heli1 setRotation:lerp(rot1, rot2, (t * 30.0) - f)];
			}

			if (heliData2 &&
					f > 0 &&
					(f * 3 * 2 + 9) * 4 + 3 < (int) [heliData2 length])
			{
				float *d = (float *) [heliData2 bytes];

				vector3fe pos1 (&d[f * 3 * 2]);
				vector3fe rot1 (&d[f * 3 * 2 + 3]);
				vector3fe pos2 (&d[f * 3 * 2 + 6]);
				vector3fe rot2 (&d[f * 3 * 2 + 9]);

				[heli2 setPosition:lerp(pos1, pos2, (t * 30.0) - f)];
				[heli2 setRotation:lerp(rot1, rot2, (t * 30.0) - f)];
			}

			if (heliData3 &&
					f > 0 &&
					(f * 3 * 2 + 9) * 4 + 3 < (int) [heliData3 length])
			{
				float *d = (float *) [heliData3 bytes];

				vector3fe pos1 (&d[f * 3 * 2]);
				vector3fe rot1 (&d[f * 3 * 2 + 3]);
				vector3fe pos2 (&d[f * 3 * 2 + 6]);
				vector3fe rot2 (&d[f * 3 * 2 + 9]);

				[heli3 setPosition:lerp(pos1, pos2, (t * 30.0) - f)];
				[heli3 setRotation:lerp(rot1, rot2, (t * 30.0) - f)];
			}
		}
	}

#ifndef TARGET_OS_IPHONE
    if ((flightMode < kFlightGame)
        && [[HIDSupport sharedInstance] started])
    {
        static int prevPressed = -1;

        BOOL nowPressed = FALSE;

        if ([[HIDSupport sharedInstance] valueOfItem:kLookBackKey] > 0.9 ||
            [[HIDSupport sharedInstance] valueOfItem:kFireWeaponKey] > 0.9 ||
            [[HIDSupport sharedInstance] valueOfItem:kChangeCameraKey] > 0.9)
        {
            nowPressed = TRUE;
        }

        if ((prevPressed == 0) && (nowPressed == TRUE))
        {
            [self advanceFlightMode];
        }

        prevPressed = nowPressed;
    }
#endif
}

#define RECT_CONTAINS_POINT(center, widthHalf, heightHalf, point) (abs(vector2f(point - center)[0]) < widthHalf && abs(vector2f(point - center)[1]) < heightHalf)

- (void)_mouseDown:(CGPoint)grabOrigin
{
#ifdef TARGET_OS_MAC
    [self performBlockAfterDelay:0.0 block:^{
#endif
	if (flightMode < kFlightGame)
		[self advanceFlightMode];
#ifdef TARGET_OS_MAC
        }];
#endif


#ifdef TARGET_OS_IPHONE
	if (!paused)
	{
		vector2f point = vector2f(grabOrigin.x, grabOrigin.y);
		vector2f center = vector2f([scene bounds].width / 2.0f + pauseOffset + topButtonSizeHalf, topButtonSizeHalf);

		if (RECT_CONTAINS_POINT(center, topButtonSizeHalf, topButtonSizeHalf, point))
		{
			[self startPause];
		}
	}
	{
		vector2f point = vector2f(grabOrigin.x, grabOrigin.y);
		vector2f center = vector2f([scene bounds].width / 2.0f + cameraOffset + topButtonSizeHalf, topButtonSizeHalf);

		if (RECT_CONTAINS_POINT(center, topButtonSizeHalf, topButtonSizeHalf, point))
		{
			[ship handleCamera];
		}
	}
#endif

#if defined(SDL) || defined(TARGET_OS_IPHONE)
	if (paused)
	{
		//  NSLog(@"mouse %f %f", grabOrigin.x, grabOrigin.y);

		$defaultsync;

		vector2f point = vector2f(grabOrigin.x, grabOrigin.y);

		vector2f center = vector2f([scene bounds].width / 2.0f, [scene bounds].height / 2.0f);
		vector2f returncenter = center + vector2f(0.0f, 24.0f);
		vector2f quitcenter = center + vector2f(0.0f, 24.0f + 66.0f);
		vector2f resumecenter = center + vector2f(0.0f, 24.0f - 66.0f);
		vector2f scorecenter = center + vector2f(0.0f, 24.0f - 66.0f - 66.0f);

		if (RECT_CONTAINS_POINT(returncenter, 150, 25, point))
		{
#ifdef TARGET_OS_IPHONE
			[[NSNotificationCenter defaultCenter] postNotificationName:@"gameFinished" object:nil];
#else
            [[RenderViewController sharedController] quitAndLoadNib:@"Launcher"];
            [[GameSheetController sharedController] autorelease];
#endif
		}
		else if (RECT_CONTAINS_POINT(quitcenter, 150, 25, point))
		{
			[scene release];
			fatal("CoreBreach proper termination\n");
		}
		else if (RECT_CONTAINS_POINT(resumecenter, 150, 25, point))
		{
			[self stopPause];
		}
		else if (RECT_CONTAINS_POINT(scorecenter, 150, 25, point))
		{
			if (gameMode == kGameModeTimeAttack && [hud.timeArray count] >= 2)
			{
#ifdef TARGET_OS_IPHONE
				NSDictionary *result = [CoreBreach fetchResult1];
				NSDictionary *settings = [CoreBreach fetchSettings];
				NSDictionary *object = [NSDictionary dictionaryWithObjectsAndKeys:settings, @"settings", result, @"result", nil]; // result 2 can be nil shouldnt matter
				[[NSNotificationCenter defaultCenter] postNotificationName:@"gameFinished" object:object];
				[result release];
				[settings release];
#else                
                [[RenderViewController sharedController] quitAndLoadNib:nil];
#endif
			}
		}
	}
#endif
}

#ifndef TARGET_OS_IPHONE
- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint grabOrigin = [theEvent locationInWindow];
    [self _mouseDown:grabOrigin];
}

- (void)keyDown:(NSEvent *)theEvent
{
    if (flightMode < kFlightGame)
    {
        [self mouseDown:nil];
        return;
    }
	unichar c = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];

#ifndef RELEASEBUILD
	if ((([theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask) && (c == 'e'))
	{
		[Editor loadEditor:self];
	}
#endif
#ifdef DEBUG
    if (c == 'c')
	{
        renderCollision = !renderCollision;
        [realTrack setEnabled:!renderCollision];
	}
#endif

//	else if (c == 'c')
//	{
//		static int i = 0;
//		static Camera *savedCamera;
//
//		if (i ==0)
//			savedCamera = [[[scene mainRenderPass] camera] retain];
//#warning shit
//
//		[[scene mainRenderPass] setCamera:[[[scene renderpasses] objectAtIndex:i++] camera]];
//	}
#ifdef SDL
    if (c == SDLK_ESCAPE)
	{
		if (paused)
            [self stopPause];
        else
            [self startPause];
	}
    else if (c == SDLK_UP)
    {
        int limit = (gameMode == kGameModeTimeAttack && [hud.timeArray count] >= 2) ? -1 : 0;
        if (paused && pauseButtonSelection > limit)
            pauseButtonSelection --;
    }
    else if (c == SDLK_DOWN)
    {
        if (paused && pauseButtonSelection < 2)
            pauseButtonSelection ++;
    }
    else if (c == SDLK_RETURN || c == SDLK_KP_ENTER)
    {
        if (paused && pauseButtonSelection == -1)
        {
            [[RenderViewController sharedController] quitAndLoadNib:nil];
        }
        else if (paused && pauseButtonSelection == 0)
            [self stopPause];
        else if (paused && pauseButtonSelection == 1)
        {
            [[RenderViewController sharedController] quitAndLoadNib:@"Launcher"];
            [[GameSheetController sharedController] autorelease];
        }
        else if (paused && pauseButtonSelection == 2)
        {
            [scene release];
            fatal("CoreBreach proper termination\n");
        }
    }
#else
	if (c == 27)
	{
		[[GameSheetController sharedController] presentPauseSheet];
		[self startPause];
	}
#endif
    if (!paused)
	{
		[ship keyDown:theEvent];
		[ship2 keyDown:theEvent];
	}
}

- (void)keyUp:(NSEvent *)theEvent
{
	[ship keyUp:theEvent];
	[ship2 keyUp:theEvent];
}
#else
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	for (UITouch *t in touches)
	{
		CGPoint p = [t locationInView:[t view]];

		[self _mouseDown:p];
	}
}
#endif

- (void)startPause
{
	self->paused = YES;
	[self pauseSoundAndMusic];
#ifdef SDL
    SDL_ShowCursor(SDL_ENABLE);
#endif
}

- (void)pauseSoundAndMusic
{
	[ship pauseSound];

	[musicManager pauseMusic];
}

- (void)stopPause
{
	self->paused = NO;
	[ship playSound];

	[musicManager unpauseMusic];
#ifdef SDL
    SDL_ShowCursor(SDL_DISABLE);
#endif
}

+ (void)renderSplash
{
	Texture *splashTex = [Texture newTextureNamed:kOverlayLoadingTexture];
	[splashTex load];
	[splashTex bind];
	[[scene textureOnlyShader] bind];

	myEnableBlendParticleCullDepthtestDepthwrite(NO, NO, YES, YES, YES);

	CGRect fr = CGRectMake(0, 0, [scene bounds].width, [scene bounds].height);
	RenderPass *mainPass = [[RenderPass alloc] initWithFrame:fr andAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
	currentRenderPass = mainPass;

	globalMaterial.color = vector4f(1.0f, 1.0f, 1.0f, 1.0f);

	DrawCenteredScreenQuad(256, 256);


	//NSLog(@"drawing splash %@ %@", splashTex, [scene textureOnlyShader]);

	[splashTex release];
	[mainPass release];
	/*PSEUDO_DRAW_CALL*/

	currentRenderPass = nil;
}

- (void)render
{
	if (flightMode == kFlightShowStory)
	{
		[storyTex bind];
		[[scene textureOnlyShader] bind];
		globalMaterial.color = vector4f(1.0f, 1.0f, 1.0f, 1.0f);

		myEnableBlendParticleCullDepthtestDepthwrite(NO, NO, YES, YES, YES);

		DrawARFullScreenQuad([storyTex width], [storyTex height]);

		/*PSEUDO_DRAW_CALL*/
	}

#ifdef DEBUG
	if (renderCollision)
	{
		[[scene phongOnlyShader] bind];
		[currentTrack render];
		[currentTrackBorder render];
	}
#endif

#ifndef TARGET_OS_MAC
	if (paused)
	{
		CGRect saved;
		if (gameMode == kGameModeMultiplayer)
		{
			myViewport((GLint) 0, (GLint) 0, (GLsizei) [scene bounds].width, (GLsizei) [scene bounds].height);
			saved = currentRenderPass.frame;
			currentRenderPass.frame = CGRectMake(0, 0, (GLsizei) [scene bounds].width, (GLsizei) [scene bounds].height);
		}

		myEnableBlendParticleCullDepthtestDepthwrite(YES, NO, YES, NO, YES);
		myBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		[pauseTexture bind];
		[[scene textureOnlyShader] bind];

		globalMaterial.color = vector4f(1.0f, 1.0f, 1.0f, 1.0f);

		DrawCenteredScreenQuad(384, 384);

#ifdef SDL
        [[scene colorOnlyShader] bind];

        vector2f center = vector2f([scene bounds].width / 2.0f, [scene bounds].height / 2.0f);

        vector2f returncenter = center + vector2f(0.0f, 24.0f);
        vector2f quitcenter = center + vector2f(0.0f, 24.0f + 66.0f);
        vector2f resumecenter = center + vector2f(0.0f, 24.0f - 66.0f);
        vector2f scorecenter = center + vector2f(0.0f, 24.0f - 66.0f - 66.0f);

        vector2f currentcenter;
        if (pauseButtonSelection == -1)
            currentcenter = scorecenter;
        else if (pauseButtonSelection == 0)
            currentcenter = resumecenter;
        else if (pauseButtonSelection == 1)
            currentcenter = returncenter;
        else if (pauseButtonSelection == 2)
            currentcenter = quitcenter;



        globalMaterial.color = vector4f(0.7f, 0.2f, 0.1f, 0.5f);

        DrawQuadWithCoordinates(currentcenter[0] - 148, [scene bounds].height - currentcenter[1] - 22,
                                currentcenter[0] + 148, [scene bounds].height - currentcenter[1] - 22,
                                currentcenter[0] + 148, [scene bounds].height - currentcenter[1] + 23,
                                currentcenter[0] - 148, [scene bounds].height - currentcenter[1] + 23);

        if (gameMode == kGameModeTimeAttack && [hud.timeArray count] < 2)
        {
            globalMaterial.color = vector4f(0.2f, 0.2f, 0.2f, 0.5f);

            DrawQuadWithCoordinates(scorecenter[0] - 148, [scene bounds].height - scorecenter[1] - 22,
                                    scorecenter[0] + 148, [scene bounds].height - scorecenter[1] - 22,
                                    scorecenter[0] + 148, [scene bounds].height - scorecenter[1] + 23,
                                    scorecenter[0] - 148, [scene bounds].height - scorecenter[1] + 23);
        }
        /*PSEUDO_DRAW_CALL*/
#endif


		if (gameMode == kGameModeMultiplayer)
		{
			currentRenderPass.frame = saved;
		}
	}
#endif
}



#ifdef TARGET_OS_IPHONE
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
#define kFilteringFactor            0.1
	static int i = 0;
	static float history[3][6] = {{0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}, {0, 0, 0, 0, 0, 0}};

	//Use a basic low-pass filter to only keep the gravity in the accelerometer values
	accelerometerGravity[0] = acceleration.x * kFilteringFactor + accelerometerGravity[0] * (1.0 - kFilteringFactor);
	accelerometerGravity[1] = acceleration.y * kFilteringFactor + accelerometerGravity[1] * (1.0 - kFilteringFactor);
	accelerometerGravity[2] = acceleration.z * kFilteringFactor + accelerometerGravity[2] * (1.0 - kFilteringFactor);


	history[0][i % 6] = accelerometerGravity[0];
	history[1][i % 6] = accelerometerGravity[1];
	history[2][i % 6] = accelerometerGravity[2];

	i++;

	accelerometerChanges[0] = history[0][(i - 1) % 6] - history[0][i % 6];
	accelerometerChanges[1] = history[1][(i - 1) % 6] - history[1][i % 6];
	accelerometerChanges[2] = history[2][(i - 1) % 6] - history[2][i % 6];

	//NSLog(@"gravity: %f %f %f    %f %f %f", accelerometerGravity[0], accelerometerGravity[1], accelerometerGravity[2], accelerometerChanges[0], accelerometerChanges[1], accelerometerChanges[2]);
	//cout << accelerometerChanges[2] << endl;

	//	z > -0.1 => brake
	// y 0.5 > links, y -0.5 > rechts
}
#endif

- (void)dealloc
{
	//NSLog(@"game dealloc");
//    extern     NSMutableDictionary     *wrongShips;

//    for (int i = 0; i < 99; i++)
//    {
//        if ((![wrongShips objectForKey:$stringf(@"%i", i+100)])
//            &&
//            (![wrongShips objectForKey:$stringf(@"%i", i+200)]))
//              NSLog(@"Ship fine: %i", i);
//    }


	//NSLog([wrongShips description]);

	game = nil;
	[trackProperties release];

#ifndef TARGET_OS_IPHONE
    if ($defaulti(kPlayer1InputDeviceIndexKey) || $defaulti(kPlayer2InputDeviceIndexKey))
        [[HIDSupport sharedInstance] stopHID];
#endif
#ifndef TARGET_OS_MAC
	[pauseTexture release];
#endif

	[musicManager release];

	[bombMesh release];
	[mineMesh release];
	[shieldSphere release];
	[dynamicNode release];
	[damageSphere release];
	[hud release];
	[hud2 release];
	[ship release];
	[ship2 release];

	[currentTrack release];
	[currentTrackBorder release];

	[shipNames release];
	[bonusboxen release];
	[enemies release];
	[ships release];

	[heliData1 release];
	[heliData2 release];
	[heliData3 release];

#ifdef TARGET_OS_MAC
	[(NSNotificationCenter *)[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSApplicationWillResignActiveNotification
												  object:NSApp];

	[(NSNotificationCenter *)[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSApplicationWillBecomeActiveNotification
												  object:NSApp];
#elif defined(TARGET_OS_IPHONE)
	[[NSNotificationCenter defaultCenter] removeObserver:self
	                                                name:UIApplicationDidEnterBackgroundNotification
		                                          object:nil];
#endif

	[super dealloc];
}

- (void)handleBackground:(NSNotification *)noti
{
	[self startPause];
}

- (void)willResign:(NSNotification *)noti
{
#if defined(TARGET_OS_MAC) && defined(RELEASEBUILD)
	if (![[RenderViewController sharedController] isInFullScreenMode])
		[[GameSheetController sharedController] presentPauseSheet];
	[self startPause];
#endif
}

- (void)willBecome:(NSNotification *)noti
{
#if defined(TARGET_OS_MAC) && defined(RELEASEBUILD)
	if ([[RenderViewController sharedController] isInFullScreenMode])
		[[GameSheetController sharedController] presentPauseSheet];
#endif
}

//- (void)render
//{
//    [currentTrack render];
//}

@end
