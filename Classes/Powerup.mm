//
//  Powerup.m
//  Core3D
//
//  Created by CoreCode on 04.06.08.
//  Copyright 2008 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "Game.h"


#define SMOKEDURATION 0.9
#define SMOKESTARTDELAY 0.06
#define SMOKEMAXDENSITY 0.50
#define SMOKESIZE 0.8

short qdEnabled = 0;
BOOL qdPicked = 0;
float qdTrackpoint;

@implementation Powerup

@synthesize speedUp, velocity, weaponLight, activePowerup, nitroLoaded;


+ (weaponTypeEnum)generateTypeForShip:(SceneNode <Ship> *)ship
{
	int subtract = 0;
	if (qdPicked)
		subtract += 1;
	if ([ship isKindOfClass:[Enemyship class]])
		subtract += 1;

	weaponTypeEnum result = (weaponTypeEnum) cml::random_integer(kFirstWeaponIndex, kLastWeaponIndex - subtract);

	if ((qdPicked) && (result == kWave))
		result = (weaponTypeEnum) (result + 1);
	if ((result == kPlasma) && ([ship isKindOfClass:[Enemyship class]]))
		result = (weaponTypeEnum) (result + 1);

	if ((game.gameMode == kGameModeMultiplayer) && (result == kPlasma) && ([ship isKindOfClass:[Playership class]]) && !(game.multiCore))
		result = kRockets;

	if (result == kWave)
		qdPicked = TRUE;

	if (([ship isKindOfClass:[Playership class]]) && ([(Playership *) ship coreModeActive]))
	{
		if (result == kMines)
			result = kMissile;
		if (result == kBomb)
			result = kRockets;
	}

	return result;
}

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithOwner:(SceneNode <Ship> *)owner
{
	if ((self = [super init]))
	{
		additionalBlendTextureShader = [Shader newShaderNamed:@"texture" withDefines:@"#define ADDITIONALBLEND 1\n" withTexcoordsBound:YES andNormalsBound:NO];

		masterShip = owner;

		if ([owner isKindOfClass:[Playership class]] && !IS_MULTI)
		{
			weaponLight = [[Light alloc] init];
			[weaponLight setPosition:vector3f(0, 0, 0)];
			[weaponLight setLinearAttenuation:1000.0f];
			[weaponLight setLightDiffuseColor:vector4f(0.99f, 0.5f, 0.5f, 1.0f)];
			[weaponLight setRelativeModeTarget:self];
			[[currentRenderPass lights] addObject:weaponLight];
			assert([[currentRenderPass lights] indexOfObject:weaponLight] == 1);
		}

		trackSpeedModifier = [[game.trackProperties objectForKey:@"speedfactor"] floatValue];

		{ // sounds
			rocketSoundNode = [[SceneNode alloc] init];
			[rocketSoundNode attachSoundNamed:@"weapon_photoncannon"];
			[rocketSoundNode setVolume:2.0];
			mineSoundNode = [[SceneNode alloc] init];
			[mineSoundNode attachSoundNamed:@"weapon_eject"];
			[mineSoundNode setVolume:2.0];
			missileSoundNode = [[SceneNode alloc] init];
			[missileSoundNode attachSoundNamed:@"weapon_missiles"];
			[missileSoundNode setVolume:2.0];
			bombSoundNode = [[SceneNode alloc] init];
			[bombSoundNode attachSoundNamed:@"weapon_thunder"];
			[bombSoundNode setVolume:2.0];
			waveSoundNode = [[SceneNode alloc] init];
			[waveSoundNode attachSoundNamed:@"weapon_quake"];
			[waveSoundNode setVolume:2.0];
			plasmaSoundNode = [[SceneNode alloc] init];
			[plasmaSoundNode attachSoundNamed:@"weapon_plasma"];
			[plasmaSoundNode setVolume:2.0];
			speedSoundNode = [[SceneNode alloc] init];
			[speedSoundNode attachSoundNamed:@"weapon_speed"];
			[speedSoundNode setVolume:2.0];
		}

		{ // zeus plasma cannon
			int particlecount;
			if ($defaulti(kParticleQualityKey) == 0)
				particlecount = 4096;
			else if ($defaulti(kParticleQualityKey) == 1)
				particlecount = 2048;
			else
				particlecount = 1024;

			plasmaBolt = [[SphereParticlesystem alloc] initWithParticleCount:particlecount andTextureNamed:kSpriteParticleTexture];
			[plasmaBolt setSize:2.8];
			[plasmaBolt setEnabled:FALSE];
			[[game.particleNode children] addObject:plasmaBolt];
		}

		{ // missile
			missileSmokeEnabled = NO;
			missileSmoke = [[NSMutableArray alloc] init];
			smokeNodes = [[NSMutableSet alloc] init];
			for (int i = 0; i < 20; i++)
			{
				SpriteNode *sn = [[SpriteNode alloc] initWithTextureNamed:kSpriteSmokeTexture]; // TODO
				[smokeNodes addObject:sn];
				[sn release];
			}

			missile = [[CollideableMeshBullet alloc] initWithOctreeNamed:@"item_missile"];
			[missile setEnabled:FALSE];
			[missile setCollisionShapeFittingSphere];
			[[game.phongShader children] addObject:missile];

			missileSprite = [[SpriteNode alloc] initWithTextureNamed:kSpriteMissileTexture];
			[missileSprite setEnabled:FALSE];

			[[game.spriteNode children] addObject:missileSprite];
		}

		{ // rocket
			rocketSprite1 = [[SpriteNode alloc] initWithTextureNamed:kSpriteRocketTexture]; // TODO
			rocketSprite2 = [[SpriteNode alloc] initWithTextureNamed:kSpriteRocketTexture];
			rocketSprite3 = [[SpriteNode alloc] initWithTextureNamed:kSpriteRocketTexture];

			[rocketSprite1 setSize:2.0];
			[rocketSprite2 setSize:2.0];
			[rocketSprite3 setSize:2.0];

			[rocketSprite1 setEnabled:FALSE];
			[rocketSprite2 setEnabled:FALSE];
			[rocketSprite3 setEnabled:FALSE];

			[[game.spriteNode children] addObject:rocketSprite1];
			[[game.spriteNode children] addObject:rocketSprite2];
			[[game.spriteNode children] addObject:rocketSprite3];
		}

		{ // wave
			if (game.trackName)
				wave = [[Mesh alloc] initWithOctree:[NSURL fileURLWithPath:[[APPLICATION_SUPPORT_DIR stringByAppendingPathComponent:[game.trackName stringByAppendingString:@".cbtrack"]] stringByAppendingPathComponent:@"trackbase_collision.octree"]] andName:[game.trackName stringByAppendingString:@"base_collision"]];
			else
				wave = [[Mesh alloc] initWithOctreeNamed:$stringf(@"track%iqd", game.meshTrackNum + 1)]; // TODO
			[wave setEnabled:FALSE];
			//        [wave setPosition:vector3f(0, -1.0, 0)];
			[wave setDoubleSided:YES];

			waveshader = [Shader newShaderNamed:@"texture_wave" withTexcoordsBound:YES andNormalsBound:NO];
			[waveshader bind];

			qdposPos = glGetUniformLocation(waveshader.shaderName, "qdPosition");


			wavetex = [Texture newTextureNamed:kEffectWaveTexture];
			[wavetex load];
		}

		{  // bomb
			bomb = [[SceneNode alloc] init];
			[[bomb children] addObject:game.bombMesh];
			[[[game animatedTextureShader] children] addObject:bomb];
			[bomb setEnabled:FALSE];
			[bomb release];


			bombSphere = [[SceneNode alloc] init];

			[[bombSphere children] addObject:[game damageSphere]];
			[[[game damageSphereNode] children] addObject:bombSphere];
			[bombSphere release];

			[bombSphere setScale:0.0];
			[bombSphere setEnabled:NO];
		}
	}

	return self;
}

- (NSString *)name
{
	return [kWeaponNames objectAtIndex:[self activePowerupOrLoadedPowerup]];
}

- (void)hitEnemy:(SceneNode <Ship> *)e withWeapon:(weaponTypeEnum)w
{
	[masterShip hasHit:(w == kPlasma) ? YES : NO];

	switch (w)
	{
		case kBomb:
	        [e hit:kMediumHit];
	        [game.hud addWeaponMessage:$stringf(@"%@'s bomb blew %@ away!", [masterShip name], [e name])];
	        break;
		case kWave:
	        [e hit:kMediumHit];
	        [game.hud addWeaponMessage:$stringf(@"%@'s wave unerringly hit %@!", [masterShip name], [e name])];
	        break;
		case kRockets:
	        [e hit:kBigHit];
	        [game.hud addWeaponMessage:$stringf(@"%@'s rocket whent right into %@!", [masterShip name], [e name])];
	        break;
		case kMissile:
	        [e hit:kBigHit];
	        [game.hud addWeaponMessage:$stringf(@"%@'s missle could not be dodged by %@!", [masterShip name], [e name])];
	        break;
		case kPlasma:
	        [e hit:kDeadlyHit];
	        [game.hud addWeaponMessage:$stringf(@"%@ annihilated %@ with the ZPC!", [masterShip name], [e name])];
	        break;
		case kMines:
		case kSpeedup:
		case kNoWeaponLoaded:
	        break;
	}
}

- (BOOL)loaded
{
	return nitroLoaded || loadedWeapon;
}

- (BOOL)canPickupWeapon
{
	return (loadedWeapon == kNoWeaponLoaded);
}

- (BOOL)canPickupNitro
{
	return !nitroLoaded;
}

- (BOOL)canDeploy
{
	return !activePowerup;
}

- (weaponTypeEnum)activePowerupOrLoadedPowerup
{
	if (activePowerup)
		return activePowerup;
	if (loadedWeapon)
		return loadedWeapon;
	if (nitroLoaded)
		return kSpeedup;

	return kNoWeaponLoaded;
}

- (void)pickup:(BOOL)nitro forShip:(SceneNode <Ship> *)ship
{
	if (nitro)
	assert([self canPickupNitro]);
	else
			assert([self canPickupWeapon]);

	if (nitro)
		nitroLoaded = YES;
	else
		loadedWeapon = [Powerup generateTypeForShip:ship];
}

- (void)deploy:(BOOL)nitro
{
	if (!loadedWeapon && !nitroLoaded)
		return;

	if ((nitro && nitroLoaded) || !loadedWeapon)
	{
		activePowerup = kSpeedup;
		nitroLoaded = FALSE;
	}
	else
	{
		activePowerup = loadedWeapon;
		loadedWeapon = kNoWeaponLoaded;
	}


	[self setPosition:[masterShip position]];
	[self setRotation:[masterShip rotation]];
	rotation[2] = 0;
	[self setVelocity:[masterShip speed]];

//    cout << "deploy weapon" << endl;
//    cout << position << endl;
//    cout << rotation << endl;
//    cout << velocity << endl;

	deployTime = [game simTime];

	if (activePowerup == kMines)
	{
		[mineSoundNode setPosition:position];
		[mineSoundNode updateSound];
		if (game.flightMode != kFlightEpilogue)
			[mineSoundNode playSound];


		BasicBlock b = ^
		{
			CollideableSceneNode *n = [[CollideableSceneNode alloc] init];
			[n setCollisionShapeSphere:vector3f(0.65, 0.65, 0.65)];
			[n setPosition:[masterShip position] - [masterShip getLookAt] * 1.2];
			[[n children] addObject:game.mineMesh];
			[[game.mineNode children] addObject:n];
			[n release];
		};

		[game performBlockAfterDelay:0.1 block:b];
		[game performBlockAfterDelay:0.3 block:b];
		[game performBlockAfterDelay:0.5 block:b];
		[game performBlockAfterDelay:0.7 block:b];
		if (game.minesUpgraded || [masterShip coreModeActive])
			[game performBlockAfterDelay:0.9 block:b];

		[game performBlockAfterDelay:0.7 block:^
		{activePowerup = kNoWeaponLoaded;}];
	}
	else if (activePowerup == kWave)
	{
		[waveSoundNode setPosition:position];
		[waveSoundNode updateSound];
		if (game.flightMode != kFlightEpilogue)
			[waveSoundNode playSound];

		qdTrackpoint = ([masterShip currpoint] + 15) % [game.currentTrack trackPoints];
		qdEnabled = YES;
		[wave setEnabled:YES];



		if (qdTrackpoint > [masterShip currpoint]) // easier with no wrap
		{
			for (SceneNode <Ship> *enemy in game.ships)
			{
				if (![enemy enabled])
					continue;

				if ([enemy currpoint] > [masterShip currpoint] + 2 &&
						[enemy currpoint] < qdTrackpoint)
					[self hitEnemy:enemy withWeapon:kWave];
			}
		}


		[game addAnimationWithDuration:(game.waveUpgraded || [masterShip coreModeActive]) ? 1.5 : 1.0
		                     animation:^(double delay)
		                     {
			                     qdTrackpoint = (qdTrackpoint + ((3.0 * globalInfo.frameDiff * trackSpeedModifier) / 0.01668));

			                     if (qdTrackpoint > [game.currentTrack trackPoints])
				                     qdTrackpoint -= [game.currentTrack trackPoints];

			                     for (SceneNode <Ship> *enemy in game.ships)
			                     {
				                     if (![enemy enabled])
					                     continue;

				                     if (abs([enemy currpoint] - (int) qdTrackpoint) < 5 && ![enemy isHit])
					                     [self hitEnemy:enemy withWeapon:kWave];
			                     }

			                     [waveSoundNode setPosition:[game.currentTrack positionAtIndex:qdTrackpoint]];
			                     [waveSoundNode updateSound];
		                     }
				            completion:^
				            {
					            qdEnabled = NO;
					            [wave setEnabled:NO];
					            activePowerup = kNoWeaponLoaded;
					            qdPicked = NO;
				            }];
	}
	else if (activePowerup == kSpeedup)
	{
		[speedSoundNode setPosition:position];
		[speedSoundNode updateSound];
		if (game.flightMode != kFlightEpilogue)
			[speedSoundNode playSound];

		float duration = (game.speedupUpgraded || [masterShip coreModeActive]) ? 2.6 : 2.0;

		[masterShip._ourPP setRadialblurEnabled:YES];

		[game addAnimationWithDuration:duration
		                     animation:^(double delay)
		                     {
			                     speedUp = sinf(delay * M_PI / duration);
			                     [masterShip._ourPP setRadialBlur:speedUp / 6.0];
			                     [masterShip._ourPP setRadialBright:0.5 + speedUp];
			                     [speedSoundNode setPosition:[masterShip position]];
			                     [speedSoundNode updateSound];
		                     }
				            completion:^
				            {
					            speedUp = 0.0f;
					            activePowerup = kNoWeaponLoaded;
					            [masterShip._ourPP setRadialblurEnabled:NO];
				            }];
	}
	else if (activePowerup == kBomb)
	{
		[bomb setEnabled:TRUE];
		[bomb setPosition:position - [masterShip getLookAt] * 1.5];
		[bombSphere setEnabled:YES];
		[bombSphere setPosition:position];

		float radius = (game.bombUpgraded || [masterShip coreModeActive]) ? 43 : 32;
		[game performBlockAfterDelay:0.66 block:^
		{
			[bombSoundNode setPosition:position];
			[bombSoundNode updateSound];
			if (game.flightMode != kFlightEpilogue)
				[bombSoundNode playSound];
			[bomb setEnabled:FALSE];
			[masterShip._ourPP setThermalEnabled:YES];
			[game addAnimationWithDuration:1.00
			                     animation:^(double delay)
			                     {
				                     [bombSphere setScale:delay * radius * (1.0f / 1.4f)];
				                     [masterShip._ourPP setThermalIntensity:sinf(delay * M_PI)];
				                     for (SceneNode <Ship> *enemy in game.ships)
				                     {
					                     if (![enemy enabled])
						                     continue;

					                     if (![enemy isHit] && length([enemy position] - [bomb position]) < delay * radius)
						                     [self hitEnemy:enemy withWeapon:kBomb];
				                     }
			                     }
					            completion:^
					            {
						            [bombSphere setScale:0.0];
						            [bombSphere setEnabled:NO];
						            activePowerup = kNoWeaponLoaded;
						            [masterShip._ourPP setThermalEnabled:NO];
					            }];
		}];
		//		[game performBlockAfterDelay:1.32 block:^{
		//
		//			BOOL hit = FALSE;
		//			for (Enemyship *enemy in game.enemies)
		//			{
		////				if (abs([enemy nearestTrackpoint] - [ship currpoint]) < 40)
		////				{
		////					hit = TRUE;
		////					[enemy hit:NO];
		////				}
		//
		//			}
		//			if (hit)
		//				Play_Sound(sounds.weapnhit);
		//		}];
	}
	else if ((activePowerup == kPlasma) || (activePowerup == kMissile) || (activePowerup == kRockets))
	{
		[weaponLight setLinearAttenuation:0.5f];


		float s = velocity.length();

		velocity *= (s + 4.0) / s;

		if (activePowerup == kRockets)
		{
			[rocketSoundNode setPosition:position];
			[rocketSoundNode updateSound];
			if (game.flightMode != kFlightEpilogue)
				[rocketSoundNode playSound];

			[rocketSprite1 setRotation:rotation];
			[rocketSprite2 setRotation:rotation];
			[rocketSprite3 setRotation:rotation];

			[rocketSprite1 setPosition:position];
			[rocketSprite2 setPosition:position];
			[rocketSprite3 setPosition:position];

			[rocketSprite1 setVelocity:(velocity * 1.2f)];
			matrix33f_c m;
			cml::identity_transform(m);
			matrix_rotate_about_local_y(m, cml::rad(6.0f));
			[rocketSprite2 setVelocity:transform_vector(m, (velocity * 1.2f))];
			matrix_rotate_about_local_y(m, cml::rad(-12.0f));
			[rocketSprite3 setVelocity:transform_vector(m, (velocity * 1.2f))];

			[rocketSprite1 setEnabled:TRUE];
			[rocketSprite2 setEnabled:TRUE];
			[rocketSprite3 setEnabled:TRUE];
		}
		else if (activePowerup == kPlasma)
		{
			[plasmaSoundNode setPosition:position];
			[plasmaSoundNode updateSound];
			if (game.flightMode != kFlightEpilogue)
				[plasmaSoundNode playSound];

			[plasmaBolt setEnabled:TRUE];
		}
		else if (activePowerup == kMissile)
		{
			[missileSoundNode setPosition:position];
			[missileSoundNode updateSound];
			if (game.flightMode != kFlightEpilogue)
				[missileSoundNode playSound];

			//NSLog(@"deploying missile frame %i", globalInfo.frame);
			missileSmokeEnabled = YES;
			[missile setEnabled:TRUE];
			[missileSprite setEnabled:YES];
			[missile setRotation:rotation];


			[game addTimerWithInterval:0.05 timer:
					                                ^(double d)
					                                {
						                                SpriteNode *sn = [smokeNodes anyObject];
						                                if (!sn) return;
						                                [sn setAdditionalBlendFactor:0.0];
						                                [sn setSize:SMOKESIZE];
						                                [sn setPosition:position];
						                                [sn setRotation:rotation];
						                                [missileSmoke addObject:sn];
						                                [smokeNodes removeObject:sn];
						                                [game addAnimationWithDuration:SMOKEDURATION animation:^(double delay)
						                                {if (delay > SMOKESTARTDELAY) [sn setAdditionalBlendFactor:sinf((delay - SMOKESTARTDELAY) / (SMOKEDURATION- SMOKESTARTDELAY) * M_PI) * SMOKEMAXDENSITY];}
						                                                    completion:^
						                                                    {}];
					                                }
			                completion:^
			                {}
					      endCondition:^BOOL
					      {return ![missile enabled];}];
		}
	}
}

- (void)update // override update instead of update node
{
	if (!activePowerup)
		return;

	if (((activePowerup == kPlasma) && (!explodingShip)) || (activePowerup == kMissile))
	{
		vector3f oldPos = vector3f(position);
//        cout << "missile old pos" << position << endl;

		[self setPosition:position + velocity * (globalInfo.frameDiff / 0.01668)];

		[missile setPosition:position];
		[missileSprite setPosition:position];

//        cout << "missile new pos" << position << endl;
		vector3f tempPos = vector3f(position);
		vector3f intersectionPoint = [game.currentTrack intersectWithLineStart:vector3f(tempPos[0], tempPos[1] + 30, tempPos[2]) end:vector3f(tempPos[0], tempPos[1] - 30, tempPos[2])];
		BOOL intersectsWithBorder = (activePowerup == kPlasma) ? FALSE : [game.currentTrackBorder intersectsWithNode:missile];


		if (!intersectsWithBorder &&
				intersectionPoint[1] != FLT_MAX)
		{
			vector3f newPos = vector3f(tempPos[0], intersectionPoint[1] + Y_OFFSET, tempPos[2]);

			[self setPosition:newPos];
			[plasmaBolt setPosition:position];

			if (activePowerup == kMissile)
			{
				[missile setPosition:position + normalize(velocity)];
				[missile setRotation:[missile rotation] + vector3f(0, 0, 2)];
				[missileSoundNode setPosition:[missile position]];
				[missileSoundNode updateSound];
			}

			for (SceneNode <Ship> *enemy in game.ships)
			{
				if (enemy == masterShip || ![enemy enabled])
					continue;



				if ((vector3f(newPos - [enemy position]).length() < (iOS ? 1.25f : 1.1f)) || ([enemy intersectWithLineStart:oldPos end:newPos][1] != FLT_MAX))
				{
					if (activePowerup == kPlasma)
					{
						[self hitEnemy:enemy withWeapon:kPlasma];

						explodingShip = enemy;
						deployTime = [game simTime];
						[self setPosition:vector3f(0.0, 0.0, 0.0)];
						[self setVelocity:vector3f(0.0, 0.0, 0.0)];
						[self setRelativeModeTarget:enemy];
						if (game.flightMode != kFlightEpilogue)
							Play_Sound(cml::random_integer(0, 1) ? sounds.elimination1 : sounds.elimination2);
					}
					else
					{
						[self hitEnemy:enemy withWeapon:kMissile];
						[missile setEnabled:FALSE];
						[missileSprite setEnabled:FALSE];
						activePowerup = kNoWeaponLoaded;
					}
					break;
				}
			}
		}
		else
		{
			//    cout << "missile done" << endl;

			[weaponLight setLinearAttenuation:1000.0f];
			[game performBlockAfterDelay:SMOKEDURATION block:^
			{
				missileSmokeEnabled = NO;
				[smokeNodes addObjectsFromArray:missileSmoke];
				[missileSmoke removeAllObjects];
			}];
			[missile setEnabled:FALSE];
			[missileSprite setEnabled:FALSE];
			[plasmaBolt setEnabled:FALSE];

			activePowerup = kNoWeaponLoaded;
		}
	}
	else if (activePowerup == kRockets)
	{
		for (SpriteNode *sprite in $array(rocketSprite1, rocketSprite2, rocketSprite3))
		{
			if (![sprite enabled])
				continue;

			vector3f oldPos = vector3f([sprite position]);

			[sprite setPosition:[sprite position] + [sprite velocity] * (globalInfo.frameDiff / 0.01668)];
			[sprite setRotation:[sprite rotation] + vector3f(0, 0, cml::random_real(5.0f, 10.0f))];

			vector3f tempPos = vector3f([sprite position]);
			vector3f intersectionPoint = [game.currentTrack intersectWithLineStart:vector3f(tempPos[0], tempPos[1] + 10, tempPos[2]) end:vector3f(tempPos[0], -10000, tempPos[2])];


			if (intersectionPoint[1] != FLT_MAX)
			{
				vector3f newPos = vector3f(tempPos[0], intersectionPoint[1] + Y_OFFSET, tempPos[2]);

				[sprite setPosition:newPos];

				if (sprite == rocketSprite1)
					[self setPosition:newPos];



				for (SceneNode <Ship> *enemy in game.ships)
				{
					if (enemy == masterShip || ![enemy enabled])
						continue;

					intersectionPoint = [enemy intersectWithLineStart:oldPos end:newPos];

					if (intersectionPoint[1] != FLT_MAX)
					{
						[self hitEnemy:enemy withWeapon:kRockets];
						[sprite setEnabled:FALSE];


						if (![rocketSprite1 enabled] && ![rocketSprite2 enabled] && ![rocketSprite3 enabled])
						{
							activePowerup = kNoWeaponLoaded;
						}

						break;
					}
				}
			}
			else
			{
				[sprite setEnabled:FALSE];

				if (![rocketSprite1 enabled] && ![rocketSprite2 enabled] && ![rocketSprite3 enabled])
				{
					[weaponLight setLinearAttenuation:1000.0f];

					activePowerup = kNoWeaponLoaded;
				}
			}
		}
		[rocketSoundNode setPosition:[rocketSprite2 position]];
		[rocketSoundNode updateSound];
	}
	else if (explodingShip)
	{
		double now = [game simTime];
		double timeDiff = now - deployTime;

		[plasmaBolt setPosition:[explodingShip position]];

		[plasmaBolt setSize:sqrtf(1 - pow_f(timeDiff - 1.0, 2)) * 6];

		if (timeDiff > 1.0)
			[plasmaBolt setIntensity:(1 - sqrtf(1 - pow_f((float) timeDiff - 2.0, 2)))];
		if (timeDiff > 1.5)
			[explodingShip setEnabled:FALSE];
		if (timeDiff > 2.0)
		{
			[plasmaBolt setSize:2.8];
			[plasmaBolt setIntensity:1.0];
			[plasmaBolt setEnabled:FALSE];
			[explodingShip setEnabled:FALSE];
			[[explodingShip fire1] setEnabled:FALSE];
			[[explodingShip fire2] setEnabled:FALSE];
			explodingShip = nil;
			activePowerup = kNoWeaponLoaded;

			[self setRelativeModeTarget:nil];
		}
	}
}

- (void)render
{
	[super render];

	if (![currentRenderPass settings] & kRenderPassSetMaterial)
		return;

	if (missileSmokeEnabled && [missileSmoke count])
	{
		[additionalBlendTextureShader bind];

		for (SpriteNode *sn in [missileSmoke reverseObjectEnumerator])
			[sn render];
	}


	if ([wave enabled])
	{
		[waveshader bind];

		[wavetex bind];

		[waveshader prepare];

		myEnableBlendParticleCullDepthtestDepthwrite(YES, NO, YES, YES, YES);
		myBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		glUniform4fv(qdposPos, 1, vector4f([game.currentTrack positionAtIndex:qdTrackpoint], 1.0).data());

		[wave render];
	}
}

- (void)dealloc
{
	//   NSLog(@"powerup release");
	[additionalBlendTextureShader release];
	[rocketSoundNode release];
	[mineSoundNode release];
	[missileSoundNode release];
	[bombSoundNode release];
	[waveSoundNode release];
	[plasmaSoundNode release];
	[speedSoundNode release];
	[smokeNodes release];
	[wave release];
	[wavetex release];
	[waveshader release];
	[weaponLight release];
	[missileSmoke release];
	[missileSprite release];
	[rocketSprite1 release];
	[rocketSprite2 release];
	[rocketSprite3 release];
	[plasmaBolt release];
	[mine release];
	[missile release];
	[[[game damageSphereNode] children] removeObject:bombSphere];

	[super dealloc];
}
@end