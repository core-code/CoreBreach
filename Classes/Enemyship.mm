//
//  Enemyship.m
//  Core3D
//
//  Created by CoreCode on 08.05.08.
//  Copyright 2008 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "Game.h"

//extern     NSMutableDictionary     *wrongShips;

@implementation Enemyship

//                                //s1 easymiddlehard           s2 easymiddlehard          s3 easymiddlehard          s4 easymiddlehard          s5 easymiddlehard          s6 easymiddlehard
// float trackSpeed[6][4*6] =
///*track1   4laps*/               {{0.91, 0.94, 0.98, 1.02,    0.92, 0.95, 0.99, 1.03,    0.94, 0.97, 1.01, 1.05,    0.95, 0.98, 1.02, 1.06,    0.94, 0.97, 1.01, 1.05,    0.92, 0.96, 1.00, 1.05},
///*track2   2laps*/                {0.91, 0.94, 0.97, 1.00,    0.93, 0.98, 1.02, 1.05,    0.97, 1.03, 1.06, 1.10,    0.99, 1.05, 1.09, 1.13,    1.02, 1.05, 1.10, 1.15,    1.04, 1.07, 1.11, 1.16},
///*track3   3laps*/                {0.90, 0.93, 0.97, 1.01,    0.92, 0.95, 1.00, 1.07,    0.97, 0.99, 1.05, 1.11,    1.02, 1.07, 1.03, 1.18,    1.02, 1.07, 1.12, 1.18,    1.06, 1.10, 1.16, 1.22},
///*track4   2laps*/                {0.85, 0.89, 0.96, 1.01,    0.86, 0.90, 0.97, 1.02,    0.89, 0.93, 1.00, 1.05,    0.91, 0.95, 1.02, 1.07,    0.91, 0.95, 1.02, 1.07,    0.91, 0.95, 1.02, 1.07},
///*track5   2laps*/                {0.89, 0.93, 0.97, 1.00,    0.93, 0.97, 1.01, 1.05,    0.97, 1.02, 1.06, 1.10,    0.99, 1.04, 1.09, 1.13,    0.99, 1.04, 1.09, 1.13,    0.99, 1.04, 1.09, 1.13},
///*track6   2laps*/                {0.84, 0.88, 0.94, 0.98,    0.86, 0.91, 0.96, 1.00,    0.89, 0.95, 1.00, 1.05,    0.94, 1.00, 1.06, 1.12,    0.96, 1.02, 1.10, 1.15,    0.97, 1.04, 1.11, 1.16}};
//
//
//const float reverseFactor[12] = {1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
//                                 0.977, 1.0, 0.995, 1.0, 1.01, 1.0};
//
//const float defaultTrackSpeed[4*6]={0.90,0.93,0.96,1.00,      0.91,0.94,0.97,1.01,       0.92,0.95,0.98,1.02,       0.93,0.96,0.99,1.03,       0.94,0.97,1.01,1.04,       0.95,0.98,1.02,1.05};


@synthesize nearestTrackpoint, round, enemyIndex, shieldVisible, damageVisible, isHit, powerup, attachedCamera, collSoundNode, fire1, fire2;
@dynamic speed, ourHUD, _ourPP, currpoint, coreModeActive;

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithOctree:(NSURL *)file andName:(NSString *)_name
{
	if ((self = [super init]))
	{
		if (game.lodMode != 2) // not low
			realmesh = [[Mesh alloc] initWithOctree:file andName:_name andTexureQuality:$numi(MAX(2, $defaulti(kTextureQualityKey)))];
		//realmesh = [[CollideableMeshBullet alloc] initWithOctree:file andName:_name];


		if (game.lodMode != 0) // not high
		{
			NSURL *newurl = [NSURL fileURLWithPath:[[file path] stringByReplacingOccurrencesOfString:@".octree" withString:@"_lod1.octree"]];

			realmesh_lod = [[Mesh alloc] initWithOctree:newurl andName:_name andTexureQuality:$numi(MAX(2, $defaulti(kTextureQualityKey)))];
		}

		damageSphereNode = [[SceneNode alloc] init];
		[damageSphereNode setRelativeModeTarget:self];
		[[damageSphereNode children] addObject:[game damageSphere]];
		[[[game damageSphereNode] children] addObject:damageSphereNode];
		[damageSphereNode release];
		//      [damageSphereNode setEnabled:FALSE];

		shieldSphereNode = [[SceneNode alloc] init];
		[shieldSphereNode setRelativeModeTarget:self];
		[[shieldSphereNode children] addObject:[game shieldSphere]];
		[[[game shieldSphereNode] children] addObject:shieldSphereNode];
		[shieldSphereNode release];
		//       [shieldSphereNode setEnabled:FALSE];


		powerup = [[Powerup alloc] initWithOwner:self];

		weaponSlowdownFactor = 1.0f;

		hitSoundNode = [[SceneNode alloc] init];
		[hitSoundNode attachSoundNamed:@"hit"];

		dontplaysirene = $defaulti(kDontPlaySireneKey);

		_numPoints = [game.currentTrack enemyPointsForEnemy:enemyIndex];
	}


	return self;
}

- (id)initWithOctreeNamed:(NSString *)_name
{
	NSString *octreeURL = [[NSBundle mainBundle] pathForResource:_name ofType:@"octree"];
	NSString *snzURL = [[NSBundle mainBundle] pathForResource:_name ofType:@"octree.snz"];

	if (!octreeURL && !snzURL)
	{fatal("Error: there is no octree named: %s", [_name UTF8String]);}

	return [self initWithOctree:(octreeURL ? [NSURL fileURLWithPath:octreeURL] : [NSURL fileURLWithPath:snzURL]) andName:_name];
}

- (void)setEnemyIndex:(short)_enemyIndex
{
	enemyIndex = _enemyIndex;

	if ($defaulti(@"timedemo") && (_enemyIndex == (game.enemiesNum / 2)))
		isCameraShip = YES;

	float trackSpeedModifier = [[game.trackProperties objectForKey:@"speedfactor"] floatValue];
#ifdef TARGET_OS_IPHONE
	trackSpeedModifier *= kIphoneTrackSpeedModifier;
#endif

	int playerShipNum = IS_MULTI ? MIN(game.shipNum, game.ship2Num) : game.shipNum;




//    if (game.meshTrackNum < kNumTracks)
//    {
	if (game.gameMode == kGameModeCareer &&
			enemyIndex < 2 &&
			game.meshTrackNum < 5 &&
			playerShipNum <= game.meshTrackNum)
	{
		//  NSLog(@"upping enemy difficulty for index %i from %i to %i", enemyIndex, playerShipNum, game.meshTrackNum+1);

		playerShipNum = game.meshTrackNum + 1;
	}

	playerShipNum = MIN(playerShipNum, 5);

	//float  trackSpeedFactorOld = trackSpeed[game.meshTrackNum][playerShipNum * 4 + game.difficulty] * trackSpeedModifier * reverseFactor[game.trackNum];

	trackSpeedFactor = [[[[game.trackProperties objectForKey:$stringf(@"enemySpeedsShip%i", playerShipNum + 1)] componentsSeparatedByString:@", "] objectAtIndex:game.difficulty] floatValue] * trackSpeedModifier;
	if (game.trackNum >= kNumTracks && !game.trackName)
		trackSpeedFactor *= [[game.trackProperties objectForKey:@"reversefactor"] floatValue];

#ifdef TARGET_OS_IPHONE
	trackSpeedFactor *= kIphoneEnemySpeedModifier;
#endif
//    trackSpeedFactor *= 0.6;
//    #warning revert
	// NSLog(@"old trackSpeed %f %f", trackSpeedFactorOld, trackSpeedFactor);
//    }
//    else
//        trackSpeedFactor = defaultTrackSpeed[playerShipNum * 4 + game.difficulty] * trackSpeedModifier;
}

- (id)copyWithZone:(NSZone *)zone
{
	Enemyship *copy = (Enemyship *) NSCopyObject(self, 0, zone);
	[copy->realmesh retain];
	[copy->realmesh_lod retain];
	[copy->children retain];

//	[copy->relativeModeTarget retain];

	copy->collisionAlgorithms = [[NSMutableDictionary alloc] init];
	copy->currentShape = new btBoxShape(btVector3(1, 1, 1));
	copy->collisionObject = new btCollisionObject();
	copy->powerup = [[Powerup alloc] initWithOwner:copy];


	copy->hitSoundNode = [[SceneNode alloc] init];
	[copy->hitSoundNode attachSoundNamed:@"hit"];


	copy->damageSphereNode = [[SceneNode alloc] init];
	[copy->damageSphereNode setRelativeModeTarget:copy];
	[[copy->damageSphereNode children] addObject:[game damageSphere]];
	[[[game damageSphereNode] children] addObject:copy->damageSphereNode];
	[copy->damageSphereNode release];

	copy->shieldSphereNode = [[SceneNode alloc] init];
	[copy->shieldSphereNode setRelativeModeTarget:copy];
	[[copy->shieldSphereNode children] addObject:[game shieldSphere]];
	[[[game shieldSphereNode] children] addObject:copy->shieldSphereNode];
	[copy->shieldSphereNode release];

	return copy;
}

//- (Mesh *)shadowmesh
//{
//	return (realmesh_lod ? realmesh_lod : realmesh);
//}

- (int)intersectsWithPlayer
{
	int currpointfull = [self currpointfull];

	if (game.gameMode == kGameModeMultiplayer)
	{
		if (abs(currpointfull - [game.ship currpointfull]) > 10 &&
				abs(currpointfull - [game.ship2 currpointfull]) > 10)
			return FALSE;

		if ((length(position - [game.ship position]) > 6) &&
				(length(position - [game.ship2 position]) > 6))
			return false;

		if ((![game.ship2 isRescuing]) && [self intersectsWithNode:game.ship2])
			return 2;
		if ((![game.ship isRescuing]) && [self intersectsWithNode:game.ship])
			return 1;
		return 0;
	}
	else
	{
		if (abs(currpointfull - [game.ship currpointfull]) > 10)
			return FALSE;

		if (length(position - [game.ship position]) > 6)
			return false;

		position[1] = [game.ship position][1];

		return (![game.ship isRescuing]) && [self intersectsWithNode:game.ship];
	}
}

- (void)fireWeapon
{
	if ([powerup canDeploy])
	{
		switch ([powerup activePowerupOrLoadedPowerup]) // there is no powerup active, else we couldn't deploy, so we get the primary loaded powerup
		{
			case kBomb:
			case kMines:
			case kWave:
		        [powerup deploy:NO];
		        break;
			case kRockets:
			case kMissile:
			case kPlasma:
			{
				BOOL didDeploy = FALSE;
				for (SceneNode <Ship> *enemy in game.ships)
				{
					if (enemy == self)
						continue;

					int pointDiff = [enemy currpointfull] - [self currpointfull];
					if (pointDiff < 0 || pointDiff > 300)
						continue;

					vector3f intersectionPoint = [enemy intersectWithLineStart:position end:position + [self speed] * 100];

					if (intersectionPoint[1] != FLT_MAX)
					{
						if ([enemy isKindOfClass:[Playership class]])
						{
							[[enemy ourHUD] addMessage:@"DANGER INCOMING" urgent:YES];
							if (!dontplaysirene && (game.flightMode != kFlightEpilogue))
								Play_Sound(sounds.incoming);
						}

						[powerup deploy:NO];
						didDeploy = TRUE;
						break;
					}
				}
				if (!didDeploy && [powerup nitroLoaded]) // fire nitro while we wait for a target
					[powerup deploy:YES];
				break;
			}
			case kSpeedup: // must be that we only have nitro
		        [powerup deploy:YES];
		        break; // must be that we only have nitro
			case kNoWeaponLoaded:
		        break;
		}
	}
}

- (void)collideWithBonusboxes:(vector3f)oldPosition
{
	if (!round)
		return;

	BOOL canPickupNitro = [powerup canPickupNitro];
	BOOL canPickupWeapon = [powerup canPickupWeapon];

	if (canPickupNitro || canPickupWeapon)
	{
		for (BonusBox *bonusbox in game.bonusboxen)
		{
			if ([bonusbox enabled])
			{
				BOOL speed = [bonusbox isSpeedbox];

				if ((speed && canPickupNitro && (cml::random_integer(0, 2) == 0)) ||
						(!speed && canPickupWeapon))
				{
					if (vector3f([bonusbox position] - position).length() < 1.5f)
					{
						if (game.flightMode != kFlightEpilogue)
							[bonusbox playSound];

						[bonusbox setEnabled:NO];

						[game performBlockAfterDelay:2.0f block:^
						{[bonusbox setEnabled:YES];}];

						[powerup pickup:speed forShip:self];
						break;
					}
				}
			}
		}
	}
}

- (void)collideWithMines:(vector3f)oldPosition
{
	NSMutableArray *tmp = [[NSMutableArray alloc] init];

	for (CollideableSceneNode *mine in [game.mineNode children])
	{
		if ([mine rotation][1] < 10)
			continue;

		vector3f diff = position - oldPosition;
		int times = diff.length() / 3.0f;
		times++;
		vector3f add = diff / times;

		for (int i = 0; i < times; i++)
		{
			oldPosition += add;
			if (vector3f([mine position] - oldPosition).length() < 1.0f)
			{
				[self hit:kLittleHit];
				[game.hud addWeaponMessage:$stringf(@"%@ tripped onto an anonymous mine!", name)];

				[tmp addObject:mine];
				[mine setEnabled:NO];
			}
		}
	}
	[[game.mineNode children] removeObjectsInArray:tmp];
	[tmp release];
}

- (void)updateNode
{
//    if (dead)
//        return;

	//   NSLog(@"update ES frmae %i", globalInfo.frame);

	[shieldSphereNode setEnabled:shieldVisible];
	[damageSphereNode setEnabled:damageVisible];


	vector3f oldPosition = position;
	//NSLog(@"update frame enemyIndex %i %i", globalInfo.frame, enemyIndex);
	if (game.flightMode < kFlightGame)
		return;
	//vector3f pla = [self getLookAt];
	float zrot = 0.0f;
	BOOL didAdvanceRound = FALSE;


	// calculate angle for zrot and speed modifier
	vector3f prevPoint = [game.currentTrack positionAtIndex:nearestTrackpoint forEnemy:enemyIndex];
	vector3f currPoint = [game.currentTrack positionAtIndex:(nearestTrackpoint + 1) forEnemy:enemyIndex];
	vector3f nextPoint = [game.currentTrack positionAtIndex:(nearestTrackpoint + 2) forEnemy:enemyIndex];
	vector3f prevtocurr = currPoint - prevPoint;
	vector3f currtonext = nextPoint - currPoint;

	prevtocurr[1] = 0;
	currtonext[1] = 0;

	float angle = cml::deg(unsigned_angle(prevtocurr, currtonext));

	if (prevtocurr[2] * currtonext[0] - prevtocurr[0] * currtonext[2] < 0)
		angle = -angle;

	angleRingbuffer[globalInfo.frame % 10] = angle;
	angle = (angleRingbuffer[0] + angleRingbuffer[1] + angleRingbuffer[2] + angleRingbuffer[3] + angleRingbuffer[4] + angleRingbuffer[5] + angleRingbuffer[6] + angleRingbuffer[7] + angleRingbuffer[8] + angleRingbuffer[9]) / 10.0f;

	zrot = angle * 10.0f;

	if (angle > 4) angle = 4;
	if (angle < -4) angle = -4;



//	float speedModifier = -log10(fabsf(angle)+0.2f);
//	speedModifier -= ts;
	float cornerSlowdown = (angle * angle) / 40.0f;

	float additionWithoutTrackSpeed;

	if (isCameraShip) // don't want speed changes in timedemo
		additionWithoutTrackSpeed = (1.0f - cornerSlowdown);
	else
		additionWithoutTrackSpeed = (1.0f - cornerSlowdown) * weaponSlowdownFactor * (1.0f + ([powerup speedUp] / 3));

	float addition = additionWithoutTrackSpeed * trackSpeedFactor;

	if (globalInfo.frame % 10 == 0)
		[self setPitch:additionWithoutTrackSpeed];
	[fire1 setSize:additionWithoutTrackSpeed + 0.5f];
	[fire2 setSize:additionWithoutTrackSpeed + 0.5f];

	addition *= globalInfo.frameDiff / (0.01668f / 1.0f);

	nearestTrackpoint += addition;


	if (nearestTrackpoint > _numPoints - 1)
	{
		nearestTrackpoint -= _numPoints;
		round++;
		didAdvanceRound = YES;
	}



	currPoint = [game.currentTrack interpolatedPositionAtIndex:nearestTrackpoint forEnemy:enemyIndex];
	nextPoint = [game.currentTrack interpolatedPositionAtIndex:nearestTrackpoint + 1.0f forEnemy:enemyIndex];

//#ifndef TEST
//    if (globalInfo.frame > 1200)
//    {
//
//        if ((vector3f(position - currPoint).length() > 12) || (nearestTrackpoint > 5000))
//        {
//            NSLog(@" %f (%i, %i %f)",  vector3f(position - currPoint).length(), numPoints, globalInfo.frame, nearestTrackpoint);
//            assert(0);
//        }
//    }
//#endif

	[self setPosition:currPoint];
	[self setRotationFromLookAt:nextPoint];



	if (!didAdvanceRound && (game.flightMode == kFlightGame) && ([game flightTime] > 3 + 3))
	{
		int playerIntersect = [self intersectsWithPlayer];
		if (playerIntersect)
		{
			Playership *e = ((playerIntersect == 1) ? game.ship : game.ship2);

			[e setShieldVisible:[e shieldVisible] + 1];

			[game performBlockAfterDelay:1.0 block:^
			{[e setShieldVisible:[e shieldVisible] - 1];}];

			SceneNode *_collSoundNode = [e collSoundNode];
			if (![_collSoundNode isPlaying])
			{
				[_collSoundNode setPosition:position];
				[_collSoundNode updateSound];
				[_collSoundNode playSound];
			}

			//  NSLog(@"intersect");
			nearestTrackpoint -= addition;
			addition /= 6.0f;

			do
			{
				nearestTrackpoint += addition;

				currPoint = [game.currentTrack interpolatedPositionAtIndex:nearestTrackpoint forEnemy:enemyIndex];


				[self setPosition:currPoint];
			} while (![self intersectsWithPlayer]);

			nearestTrackpoint -= addition;

			currPoint = [game.currentTrack interpolatedPositionAtIndex:nearestTrackpoint forEnemy:enemyIndex];


			[self setPosition:currPoint];

			nextPoint = [game.currentTrack interpolatedPositionAtIndex:nearestTrackpoint + 1.0f forEnemy:enemyIndex];

			[self setRotationFromLookAt:nextPoint];
		}
	}
	vector3f intersectionPoint = [game.currentTrack intersectWithLineStart:(currPoint + vector3f(0.0f, 20.0f, 0.0f)) end:(currPoint + vector3f(0.0f, -20.0f, 0.0f))];
	if ((intersectionPoint[0] != FLT_MAX) || (intersectionPoint[1] != FLT_MAX) || (intersectionPoint[2] != FLT_MAX))
		[self setPosition:vector3f(currPoint[0], intersectionPoint[1] + Y_OFFSET, currPoint[2])];
//    else
//    {
//     [wrongShips setObject:@"WRONG-BASE" forKey:$stringf(@"%i", enemyIndex+100)];
//        dead = YES;
//    }


	rotation[2] = zrot;
	rotation[1] += weaponYRotAddition;

	[self fireWeapon];
	[self collideWithBonusboxes:oldPosition];
	[self collideWithMines:oldPosition];

//	{
//
//		TriangleIntersectionInfo tif = [game.currentTrackBorder intersectWithNode:self];
//
//
//		if (tif.intersects)
//		{
//            [wrongShips setObject:@"WRONG-BORDER" forKey:$stringf(@"%i", enemyIndex+200)];
//            dead = YES;
//
//		}
//	}

//    // adjust shipcolor based on track lighting
//#ifndef WIN32
//    float l = [game.currentTrack lightAtPoint:CGPointMake(position[0], position[2])];
//    if (l > 0.0f)
//    {
//        float intensity = 0.8f + (l * 0.2f);
//        [self setColor:vector4f(1.0f, 1.0f, 1.0f, 1.0f / 0.8f) * intensity];
//    }
//    else
//        [self setColor:vector4f(1.0f, 1.0f, 1.0f, 1.0f)];
//#endif

	if (isCameraShip) // TIMEDEMO
	{
		int c = min((int) ((float) nearestTrackpoint / ((float) _numPoints / (float) globalInfo.pvsCells)), globalInfo.pvsCells - 1);
		currentRenderPass.currentPVSCell = c;

		if (game.trackNum > kNumTracks) // should be >= but track 7 has its own pvs
			currentRenderPass.currentPVSCell = globalInfo.pvsCells - 1 - currentRenderPass.currentPVSCell;
	}

	[super updateNode];
}

- (void)setShipNum:(int)shipNum
{

	if ($defaulti(kParticleQualityKey) == 0)
	{
		fire1 = [[FireParticlesystem alloc] initWithParticleCount:1024 andTextureNamed:kSpriteParticleTexture];
		[fire1 setSize:0.0];
		[fire1 setRelativeModeTarget:self];
		//  [fire1 setEnabled:0];
		fire2 = [[FireParticlesystem alloc] initWithParticleCount:1024 andTextureNamed:kSpriteParticleTexture];
		[fire2 setRelativeModeTarget:self];
		[fire2 setSize:0.0];
		//  [fire2 setEnabled:0];
		[Playership setupFire1:fire1 andFire2:fire2 forShipNum:shipNum];
	}

	int _class = MIN(shipNum / 2, 2);
	collSoundNode = [[SceneNode alloc] init];
	[collSoundNode attachSoundNamed:$stringf(@"collision_enemy%i", _class + 1)];

	if (_class == 0)
	{
		umin = 0.0f;
		umax = 0.5f;
		vmin = 0.5f;
		vmax = 1.0f;
	}
	else if (_class == 1)
	{
		umin = 0.5f;
		umax = 1.0f;
		vmin = 0.5f;
		vmax = 1.0f;
	}
	else if (_class == 2)
	{
		umin = 0.0f;
		umax = 0.5f;
		vmin = 0.0f;
		vmax = 0.5f;
	}

	[self setCollisionShapeSphere:component_mult3([realmesh size], vector3f(1.3f, iOS ? 1.25 : 1.1f, iOS ? 1.25 : 1.1f)) atPosition:[realmesh center]];
}

- (void)hit:(hitEnum)severity
{
	isHit = YES;
	[self setColor:vector4f(1.0f, 0.0f, 0.0f, 1.0f)];
	if (game.flightMode != kFlightEpilogue)
		[hitSoundNode playSound];

	if (severity != kDeadlyHit)
	{
		[self setDamageVisible:[self damageVisible] + 1];

		float duration = (game.damageUpgraded || [game.ship coreModeActive]) ? 1.2f : 0.8f;
		float factor = 0, addition = 0;
		if (severity == kLittleHit)
		{
			factor = 0.3f;
			addition = 0.7f;
		}
		else if (severity == kMediumHit)
		{
			factor = 0.4f;
			addition = 0.6f;
		}
		else if (severity == kBigHit)
		{
			factor = 0.5f;
			addition = 0.5f;
		}

		[game addAnimationWithDuration:duration
		                     animation:^(double delay)
		                     {
			                     weaponSlowdownFactor = cosf(delay * M_PI * 2.0f / duration) * factor + addition;
			                     weaponYRotAddition = 360 - (delay / duration * 360);
			                     [self setColor:vector4f(1.0f, delay / duration, delay / duration, 1.0f)];
		                     }
				            completion:^
				            {
					            isHit = FALSE;
					            [self setDamageVisible:[self damageVisible] - 1];
					            weaponYRotAddition = 0;
				            }];
	}
	else
		[game addAnimationWithDuration:2.0f
		                     animation:^(double delay)
		                     {weaponSlowdownFactor = 1.0f - (delay * delay) / 5.0f;}
				            completion:^
				            {isHit = FALSE;}];
}

- (NSString *)description
{
	return [realmesh description];
}

- (void)renderNode
{
//    if (enemyIndex == 0)
//    {
//        cml::matrix44d_c modelview, projection, viewport;
//        vector3f null = vector3f(0,0,0);
//        cml::matrix_viewport(viewport, (double)0.0, (double)[scene bounds].width, (double)0.0, (double)[scene bounds].height, cml::z_clip_neg_one);
//        cout << globalInfo.frame << endl;
//        cout << position << endl;
//        cout << cml::project_point([currentCamera viewMatrix],  [currentCamera projectionMatrix], viewport, position) << endl;
//    }

	if (game.flightMode < kFlightGame)
		return;


	if (/*(globalSettings.shadowMode < kEverything) &&*/ (currentRenderPass.settings == kMainRenderPass) && meshToRender && wasVisible && (length(position - [currentCamera aggregatePosition]) < BLOB_CONTRIBUTION_CULLING_DISTANCE))
	{
		[currentCamera push];
		[currentCamera identity];
		float rot = rotation[2];
		rotation[2] = 0;
		[self transform];
		rotation[2] = rot;
		matrix44f_c viewMatrix = [currentCamera modelViewMatrix];

		struct octree_node *n1 = (struct octree_node *) _NODE_NUM([meshToRender octree], 0);
		const float aabbOriginX = n1->aabbOriginX * 1.4f;
		const float aabbExtentX = n1->aabbExtentX * 1.4f;
		const float aabbOriginZ = n1->aabbOriginZ * 1.2f;
		const float aabbExtentZ = n1->aabbExtentZ * 1.2f;
		const float offset = -Y_OFFSET * 0.95f;

		vector4f v1 = viewMatrix * vector4f(aabbOriginX, offset, aabbOriginZ, 1.0f);
		vector4f v2 = viewMatrix * vector4f(aabbOriginX + aabbExtentX, offset, aabbOriginZ, 1.0f);
		vector4f v3 = viewMatrix * vector4f(aabbOriginX, offset, aabbOriginZ + aabbExtentZ, 1.0f);
		vector4f v4 = viewMatrix * vector4f(aabbOriginX + aabbExtentX, offset, aabbOriginZ + aabbExtentZ, 1.0f);

		const vertex vertices[6] = {
				{v1[0], v1[1], v1[2], umin, vmax},
				{v3[0], v3[1], v3[2], umin, vmin},
				{v2[0], v2[1], v2[2], umax, vmax},

				{v2[0], v2[1], v2[2], umax, vmax},
				{v3[0], v3[1], v3[2], umin, vmin},
				{v4[0], v4[1], v4[2], umax, vmin}};


		[[game dynamicNode] addVertices:vertices count:6];

		[currentCamera pop];
	}



	vector3f cp = [currentCamera aggregatePosition];
	float distFactor = vector3f(cp - position).length() / [realmesh radius];

	if (game.lodMode == 0) // high
		meshToRender = realmesh;
	else if (game.lodMode == 1) // auto
	{
		if ((distFactor / [currentRenderPass frame].size.width) < (10.0f / 800.0f))
			meshToRender = realmesh;
		else
			meshToRender = realmesh_lod;
	}
	else if (game.lodMode == 2) // low
		meshToRender = realmesh_lod;

	if (currentRenderPass.settings == kRenderPassUsePVS) // outline
	{
		float dist = vector3f(cp - position).length();
		if (dist < 50)
		{
			GLfloat lw = getLineWidth();
			if (dist > 10)
			{
				myLineWidth(lw / (dist / 10));
			}

			currentRenderPass.settings = (renderPassEnum) (currentRenderPass.settings | kRenderPassUpdateCulling);
			[meshToRender renderNode];
			currentRenderPass.settings = (renderPassEnum) (currentRenderPass.settings ^ kRenderPassUpdateCulling);

			if (dist > 10)
			{
				myLineWidth(lw);
			}
		}
	}
	else
		[meshToRender renderNode];



	if (currentRenderPass.settings == kMainRenderPass)
	{
		wasVisible = [meshToRender visibleNodeStackTop];
	}
}

- (void)setColor:(vector4f)newColor
{
	[realmesh setColor:newColor];
	[realmesh_lod setColor:newColor];
}

- (void)dealloc
{
	//   NSLog(@"es release");

	[[[game shieldSphereNode] children] removeObject:shieldSphereNode];
	[[[game damageSphereNode] children] removeObject:damageSphereNode];

	[collSoundNode release];
	[fire1 release];
	[fire2 release];
	[powerup release];
	[realmesh release];
	[realmesh_lod release];
	[hitSoundNode release];

	[super dealloc];
}

- (vector3f)speed
{
	vector3f currPoint = [game.currentTrack interpolatedPositionAtIndex:nearestTrackpoint forEnemy:enemyIndex];
	vector3f nextPoint = [game.currentTrack interpolatedPositionAtIndex:nearestTrackpoint + 1.0f forEnemy:enemyIndex];

	return nextPoint - currPoint;
}

- (int)currpoint
{
	return nearestTrackpoint;
}

- (int)currpointfull
{
	return nearestTrackpoint + _numPoints * (round - 1);
}

- (BOOL)coreModeActive
{
	return NO;
}

- (HUD *)ourHUD
{
	return nil;
}

- (PostprocessingShader *)_ourPP
{
	return nil;
}

- (void)hasHit:(BOOL)_deadly
{}

@end

/*

 - (void)adjustCamera:(BOOL)lookBack
 {
 [attachedCamera setPosition:vector3f(0, 0, -1)];
 [attachedCamera setRotation:vector3f(0, 0, 0)];
 }
 - (FireParticlesystem *)fire1
 {
 return [[SceneNode alloc] init];
 }
 - (FireParticlesystem *)fire2
 {
 return [[SceneNode alloc] init];
 }
 - (void)keyDown:(NSEvent *)theEvent {}
 - (void)keyUp:(NSEvent *)theEvent {}
 - (void)setExhaustLight:(Light *)ehl {}
 - (void)setOurHUD:(HUD *)ourHUD {}
 - (void)setOurPP:(PostprocessingShader *)_ourPP {}
*/