//
//  Playership.m
//  Core3D
//
//  Created by CoreCode on 04.05.08.
//  Copyright 2008 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "Game.h"
#import "UpgradeHandler.h"


#define kVectorSteerLeft 2
#define kVectorSteerRight 1
#define kVectorAccelerate 0
#ifdef TARGET_OS_IPHONE
#define kMaxFallingCount 10
#else
#define kMaxFallingCount 5
#endif

@implementation Playership

@synthesize attachedCamera, placing, powerup, round, currpoint, currpointfull, velocity, ghostData, playerNumber, fire1, fire2, alwaysLeading, noWallhit, ourHUD, exhaustLight, _ourPP, shieldVisible, damageVisible, isHit, core, coreModeActive, slowmoFired, speed, spark, coreModeIntensity, isRescuing, collSoundNode, coreModeFinish, slowmoFinish;//, rp;

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithOctree:(NSURL *)file andName:(NSString *)_name
{
	if ((self = [super initWithOctree:file andName:_name]))
	{
		if ($defaulti(kParticleQualityKey) < 2)
		{
			spark = [[FireParticlesystem alloc] initWithParticleCount:50 andTextureNamed:kSpriteSparkTexture];
			[spark setBasePointSize:50];
			[spark setDstBlend:GL_ONE_MINUS_SRC_ALPHA];
			[spark setDontDepthtest:TRUE];
			[spark setEnabled:NO];
		}

		alwaysLeftHack = YES;

		damageSphereNode = [[SceneNode alloc] init];
		[damageSphereNode setRelativeModeTarget:self];
		[[damageSphereNode children] addObject:[game damageSphere]];
		[[[game damageSphereNode] children] addObject:damageSphereNode];
		[damageSphereNode release];
		[damageSphereNode setEnabled:FALSE];

		shieldSphereNode = [[SceneNode alloc] init];
		[shieldSphereNode setRelativeModeTarget:self];
		[[shieldSphereNode children] addObject:[game shieldSphere]];
		[[[game shieldSphereNode] children] addObject:shieldSphereNode];
		[shieldSphereNode release];
		[shieldSphereNode setEnabled:FALSE];

		powerup = [[Powerup alloc] initWithOwner:self];

		velocity = vector3f(0.0f, 0.0f, 0.0f);

		shipAcceleration = shipTopSpeed = shipHandling = shipWallhitAccelerationSlowdownFactor = 1.0;

		weaponSlowdownFactor = 1.0f;

		trackSpeedModifier = [[game.trackProperties objectForKey:@"speedfactor"] floatValue];
#ifdef TARGET_OS_IPHONE
		trackSpeedModifier *= kIphoneTrackSpeedModifier;
#endif

#ifndef TARGET_OS_IPHONE        
        hid = [[HIDSupport sharedInstance] retain];
#else
		const float fieldWidthMax = (IOS_SCREEN_WIDTH - 2 * 64);
		const float fieldWidthMin = (34 + 34 + 34 + 48 + 48);

		fieldWidth = fieldWidthMin + $defaultf(kIOSTouchfieldWidth) * (fieldWidthMax - fieldWidthMin);
#endif

		wallSoundNode = [[SceneNode alloc] init];
		[wallSoundNode attachSoundNamed:@"collision_wall"];

//        hitSoundNode = [[SceneNode alloc] init];
//        [hitSoundNode attachSoundNamed:@"hit"];
		for (int i = 0; i < 5; i++)
		{
			hitSoundArray[i] = LoadSound(@"hit");
		}


		lastEnemyCollision = -FLT_MAX;
		lastWallCollision = -FLT_MAX;

		if (game.gameMode == kGameModeTimeAttack)
		{
			ghostData = [[NSMutableData alloc] initWithCapacity:2 * 3 * sizeof(float) * 30 * 150];
		}

#ifdef DEBUG
		didntCheat = YES;
#else
		didntCheat = NO;
#endif
        NSArray *keyNames = KEYS
        for (uint32_t i = 0; i < [keyNames count]; i++)
        {
            keys[i] = [$default([keyNames objectAtIndex:i]) intValue];
        }
		
        [self resetLapObjectives];

		_numPoints = [game.currentTrack trackPoints];
	}

	return self;
}

- (void)setPlayerNumber:(uint8_t)_npn
{
	playerNumber = _npn;

	cameraMode = $defaulti($stringf(kCameraModeIKey, playerNumber));

#ifndef TARGET_OS_IPHONE
    invertAccel = playerNumber ? $defaulti(kPlayer2AccelerateInvertedKey) : $defaulti(kPlayer1AccelerateInvertedKey);
    useController = playerNumber ? $defaulti(kPlayer2InputDeviceIndexKey) : $defaulti(kPlayer1InputDeviceIndexKey);
    halfAccel = playerNumber ? $defaulti(kPlayer2AccelerateHalfKey) : $defaulti(kPlayer1AccelerateHalfKey);

    int addition = playerNumber ? kKeyCount : 0;

//    NSLog(@"single steer test: %@ %@ %i", [hid nameOfItem:1 + addition], [hid nameOfItem:2 + addition], [[hid nameOfItem:1 + addition] isEqualToString:[hid nameOfItem:2 + addition]]);
                                           
//    if ([[hid nameOfItem:1 + addition] isEqualToString:[hid nameOfItem:2 + addition]])
    if ([hid item:1 + addition identicalToItem:2 + addition])    
        singleSteer = YES;
    
    if ([hid isButton:1 + addition] && [hid isButton:2 + addition])
        binarySteer = YES;
#ifdef DEBUG
    NSArray *keyNames = KEYS
    if (useController)
    {
        for (int i = addition; i < addition + kKeyCount; i++)
        {
            NSLog(@"%@", [keyNames objectAtIndex:i]);
            [hid printItem:i];
        }
    }
#endif    
#endif
}

+ (void)setupFire1:(FireParticlesystem *)fire1 andFire2:(FireParticlesystem *)fire2 forShipNum:(uint8_t)shipNum
{
	if (shipNum == 0)
	{
		[fire1 setPosition:vector3f(0.39, -0.02, 1.00)];
		[fire2 setPosition:vector3f(-0.39, -0.02, 1.00)];
	}
	else if (shipNum == 1)
	{
		[fire1 setPosition:vector3f(0.39, -0.05, 1.00)];
		[fire2 setPosition:vector3f(-0.39, -0.05, 1.00)];
	}
	else if (shipNum == 2)
	{
		[fire1 setPosition:vector3f(0.34, -0.20, 1.4)];
		[fire2 setPosition:vector3f(-0.34, -0.20, 1.4)];
	}
	else if (shipNum == 3)
	{
		[fire1 setPosition:vector3f(0.36, -0.18, 1.35)];
		[fire2 setPosition:vector3f(-0.36, -0.18, 1.35)];
	}
	else if (shipNum == 4)
	{
		[fire1 setPosition:vector3f(0.18, -0.1, 1)];
		[fire2 setPosition:vector3f(-0.18, -0.1, 1)];
	}
	else if (shipNum == 5)
	{
		[fire1 setPosition:vector3f(0.18, -0.1, 0.95)];
		[fire2 setPosition:vector3f(-0.18, -0.1, 0.95)];
	}
	else if (shipNum == 6)
	{
		[fire1 setPosition:vector3f(0.19, -0.02, 1.90)];
		[fire2 setPosition:vector3f(-0.19, -0.02, 1.90)];
	}
}

- (void)setShipNum:(int)_shipNum
{
	shipNum = _shipNum;

	int particlecount;

	if ($defaulti(kParticleQualityKey) == 0)
		particlecount = 4096;
	else if ($defaulti(kParticleQualityKey) == 1)
		particlecount = 2048;
	else
		particlecount = 1024;

	fire1 = [[FireParticlesystem alloc] initWithParticleCount:particlecount andTextureNamed:kSpriteParticleTexture];
	[fire1 setSize:0.1];
	[fire1 setRelativeModeTarget:self];

	fire2 = [[FireParticlesystem alloc] initWithParticleCount:particlecount andTextureNamed:kSpriteParticleTexture];
	[fire2 setRelativeModeTarget:self];
	[fire2 setSize:0.1];

	[Playership setupFire1:fire1 andFire2:fire2 forShipNum:shipNum];


	float a = (game.gameMode == kGameModeCareer) ? [UpgradeHandler currentUpgradedValue:kAcceleration forShip:shipNum] : [[kShipAcceleration objectAtIndex:shipNum] floatValue];
	shipAcceleration = cml::map_range(a, 3.8f, 5.6f, 0.7f, 1.3f);
	float h = (game.gameMode == kGameModeCareer) ? [UpgradeHandler currentUpgradedValue:kHandling forShip:shipNum] : [[kShipHandling objectAtIndex:shipNum] floatValue];
	shipHandling = cml::map_range(h, 3.9f, 8.1f, 0.87f, 1.30f);
	float s = (game.gameMode == kGameModeCareer) ? [UpgradeHandler currentUpgradedValue:kTopSpeed forShip:shipNum] : [[kShipTopspeed objectAtIndex:shipNum] floatValue];
	shipTopSpeed = cml::map_range(s, 3.9f, 8.3f, 0.95f, 1.3f);

	//NSLog(@"ship acceleration handling topspeed %f %f %f", shipAcceleration, shipHandling, shipTopSpeed);



	if (shipNum == 5)
		maxpitch = 2.4;
	else if (shipNum == 6)
		maxpitch = 4.0;
	else if (shipNum == 3)
		maxpitch = 3.1;
	else
		maxpitch = 2.8;



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
}

- (void)recordGhost
{
	if (!game.paused)
	{
		[ghostData appendBytes:position.data() length:3 * sizeof(float)];
		[ghostData appendBytes:rotation.data() length:3 * sizeof(float)];
	}
}

- (void)resetGhostData
{
	[ghostData setData:[NSData data]];
}

#ifndef TARGET_OS_IPHONE
- (void)keyDown:(NSEvent *)theEvent
{
	int addition = playerNumber ? kKeyCount : 0;

	if ([theEvent keyCode] == keys[kLookBackKey+addition])
	{
        [self adjustCamera:YES];
	}
}

- (void)keyUp:(NSEvent *)theEvent
{
	int addition = playerNumber ? kKeyCount : 0;

	if ([theEvent keyCode] == keys[kLookBackKey+addition])
	{
        [self adjustCamera:NO];
	}
}
#endif

- (void)handleFire:(BOOL)nitro
{
	if (coreModeActive && !slowmoFired)
	{
		slowmoFired = TRUE;

		if ([powerup activePowerupOrLoadedPowerup] != kSpeedup)
		{
			globalSettings.slowMotion = kWeaponSlowmo;
			[game performBlockAfterDelay:1.0 block:^
			{globalSettings.slowMotion = kNoSlowmo;}];
			slowmoFinish = game.simTime + 1.0;
		}
		else
		{
			globalSettings.slowMotion = kNitroSlowmo;
			[game performBlockAfterDelay:2.0 block:^
			{globalSettings.slowMotion = kNoSlowmo;}];
			slowmoFinish = game.simTime + 2.0;
		}
	}
	else
	{
		if ([powerup canDeploy])
			[powerup deploy:nitro];
	}
}

- (void)handleFirePressed
{
	if (!lastFrameFire)
	{
		fireButtonStart = game.simTime;
	}
	else
	{
		if (game.simTime - fireButtonStart > 1.0 && fireButtonStart > 0.1)
		{
			[self handleFire:TRUE];
			fireButtonStart = 0.0;
		}
	}

	lastFrameFire = TRUE;
}

- (void)handleFireNotPressed
{
	if (lastFrameFire && fireButtonStart > 0.1) // activate on release
		[self handleFire:FALSE];

	lastFrameFire = FALSE;
}

- (void)handleCamera
{
	cameraMode++;
	if (cameraMode > 2)
		cameraMode = 0;

	$setdefaulti(cameraMode, $stringf(kCameraModeIKey, playerNumber));

	[self adjustCamera:NO];
}

#ifndef TARGET_OS_IPHONE
- (vector3f)processInputController:(vector3f)oldInput
{
    int addition = playerNumber ? 6 : 0;
    vector3f inp = vector3f(0.0f, 0.0f, 0.0f);

   // NSLog(@" %f %f %f %f %f %f",     [[HIDSupport sharedInstance] valueOfItem:0+addition],     [[HIDSupport sharedInstance] valueOfItem:1+addition],     [[HIDSupport sharedInstance] valueOfItem:2+addition],     [[HIDSupport sharedInstance] valueOfItem:3+addition],     [[HIDSupport sharedInstance] valueOfItem:4+addition],     [[HIDSupport sharedInstance] valueOfItem:5+addition]);


	if (game.flightMode == kFlightGame)
	{
        inp[0] = [hid valueOfItem:kAccelKey + addition];
        if (invertAccel)
            inp[0] = 1.0 - inp[0];
        if (halfAccel)
            inp[0] = (inp[0] - 0.5f) * 2.0;
        inp[0] *= 10.0;

        if (singleSteer)
        {
            float steer = ([hid valueOfItem:kSteerLeftKey + addition] - 0.5) * 20.0;

            if (steer > 0)
                inp[1] = steer;
            else
                inp[2] = -steer;
            
            if (alwaysLeftHack)
            {
                if (steer < -9.9)
                    inp[2] = 0.0f;
                else
                    alwaysLeftHack = NO;
            }
        }
        else
        {
            if (binarySteer)
            {
                inp[1] = oldInput[1];
                inp[2] = oldInput[2];

                if ([hid valueOfItem:kSteerRightKey + addition] > 0.9)
                    inp[1] += 4.0;
                if ([hid valueOfItem:kSteerLeftKey + addition] > 0.9)
                    inp[2] += 4.0;

                inp[1] -= 3.0f;
                inp[2] -= 3.0f;
            }
            else
            {
                inp[1] = [hid valueOfItem:kSteerRightKey + addition] * 10.0;
                inp[2] = [hid valueOfItem:kSteerLeftKey + addition] * 10.0;
            }
        }

        if ([hid valueOfItem:kFireWeaponKey + addition] > 0.9)
        {
            [self handleFirePressed];
        }
        else
        {
            [self handleFireNotPressed];
        }


        if ([hid valueOfItem:kChangeCameraKey + addition] > 0.9)
        {
            if (!lastFrameCamera)
                [self handleCamera];

            lastFrameCamera = TRUE;
        }
        else
            lastFrameCamera = FALSE;


        if  ([hid valueOfItem:kLookBackKey + addition] > 0.9)
        {
            if (!lastFrameLookback)
                [self adjustCamera:YES];

            lastFrameLookback = TRUE;
        }
        else
        {
            if (lastFrameLookback)
                [self adjustCamera:NO];

            lastFrameLookback = FALSE;
        }
    }
    return inp;
}

- (vector3f)processInput:(vector3f)oldInput
{
	float newInput[3] = {oldInput[0], oldInput[1], oldInput[2]};
	NSNumber *keyToErase = nil;
	int addition = playerNumber ? kKeyCount : 0;
    BOOL firePressed = FALSE;

	if (game.flightMode == kFlightGame)
	{
     //   NSLog(@"waiting to process input");
#ifndef SDL
        @synchronized(pressedKeys)
#endif
        {
       //             NSLog(@" process input %@", [pressedKeys description]);
            for (NSNumber *keyHit in pressedKeys)
            {
                if ([keyHit intValue] == keys[kChangeCameraKey+addition])
                {
                    [self handleCamera];

                    keyToErase = keyHit;
                }
                else if ([keyHit intValue] == keys[kFireWeaponKey+addition])
                {
                    firePressed = TRUE;
                }
                else if ([keyHit intValue] == keys[kAccelKey+addition])
                {
                    newInput[kVectorAccelerate] += 4;
                }
                else if ([keyHit intValue] == keys[kSteerLeftKey+addition])
                {
                    newInput[kVectorSteerLeft] += 4;
            //        NSLog(@"left pressed");
                }
                else if ([keyHit intValue] == keys[kSteerRightKey+addition])
                {
                    newInput[kVectorSteerRight] += 4;
                }
            }

#ifdef __COCOTRON__
            if (keyToErase)	[pressedKeys removeObject:$numui([keyToErase unsignedIntValue])];
#else
            if (keyToErase)	[pressedKeys removeObject:keyToErase];
#endif
        }
	}
    if (firePressed)
        [self handleFirePressed];
    else
        [self handleFireNotPressed];


	newInput[0] -= 3.0f;
	newInput[1] -= 3.0f;
	newInput[2] -= 3.0f;

#ifdef __COCOTRON__
	return vector3f(newInput[0], newInput[1], newInput[2]);
#else
	return newInput;
#endif
}
#else

- (vector3f)processInput:(vector3f)oldInput
{
	vector3f newInput;
	BOOL fired = NO;
	const float s = controlButtonSize;
	NSMutableArray *touchesToRemove = [[NSMutableArray alloc] initWithCapacity:5];
	const CGRect rightBottom = CGRectMake(IOS_SCREEN_WIDTH - controlButtonSize, IOS_SCREEN_HEIGHT - s, s, s);
	const CGRect rightAdjacentBottom = CGRectMake(IOS_SCREEN_WIDTH - s * 2, IOS_SCREEN_HEIGHT - s, s, s);
	const CGRect leftBottom = CGRectMake(0, IOS_SCREEN_HEIGHT - s, s, s);
	const CGRect leftBottomAdjacent = CGRectMake(s, IOS_SCREEN_HEIGHT - s, s, s);


	// accelerometerSensitivity = 1.0 need full 90% rotation for full steering
	// accelerometerSensitivity = 0.5 need 50% rotation for full steering
	// accelerometerSensitivity = 0.0 full steering at 0 % rotation ;)

	// responseExponent transformation of the input for non-linear steering
	// responseExponent = 1.0 linear steering
	// responseExponent = 2.0
	// y=x^{e}\cdot \left( \frac{1}{s^{e}} \right),e=2.0,s=0.45

	if (game.accelWeapon && accelerometerChanges[2] < -0.1)
	{
		[self handleFirePressed];
		fired = YES;
	}



	const float responseExponent = 2.0;

	if (STEERING_ACCELEROMETER)
	{
		static float stretchingFactor = 1.0 / pow_f(game.accelerometerSensitivity, responseExponent);
		newInput = vector3f(oldInput[0], 0.0f, 0.0f);


		if (accelerometerGravity[1] > 0)
			newInput[(globalInfo.interfaceOrientation == UIInterfaceOrientationLandscapeRight) ? kVectorSteerLeft : kVectorSteerRight] = pow_f(accelerometerGravity[1], responseExponent) * stretchingFactor * 10.0;
		else
			newInput[(globalInfo.interfaceOrientation == UIInterfaceOrientationLandscapeRight) ? kVectorSteerRight : kVectorSteerLeft] = pow_f(-accelerometerGravity[1], responseExponent) * stretchingFactor * 10.0;


		for (UITouch *t in activeTouches)
		{
			CGPoint p = [t locationInView:[t view]];

			if (CGRectContainsPoint(rightBottom, p))
				newInput[0] += 4;
			else if (!game.accelWeapon && CGRectContainsPoint(leftBottom, p))
			{
				[self handleFirePressed];
				[touchesToRemove addObject:t];
				fired = YES;
			}
		}
		newInput -= vector3f(3.0f, 0.0f, 0.0f);
	}
	else if (STEERING_BUTTONS)
	{
		newInput = vector3f(oldInput);
		//  newInput[0] += 4;

		//cout << "new " << endl;
		//cout << newInput << endl;

		for (UITouch *t in activeTouches)
		{
			CGPoint p = [t locationInView:[t view]];

			if (CGRectContainsPoint(rightBottom, p))
				newInput[kVectorSteerRight] += 4;
			else if (CGRectContainsPoint(rightAdjacentBottom, p))
				newInput[kVectorSteerLeft] += 4;
			else if (CGRectContainsPoint(leftBottom, p))
				newInput[kVectorAccelerate] += 4;
			else if (!game.accelWeapon && CGRectContainsPoint(leftBottomAdjacent, p))
			{
				[self handleFirePressed];
				[touchesToRemove addObject:t];
				fired = YES;
			}
		}

		newInput -= vector3f(3.0f, 3.0f, 3.0f);
	}
	else if (STEERING_TOUCHPAD)
	{
		newInput = vector3f(oldInput[0], 0.0f, 0.0f);

		// we always track the whole width, because tracking the true size would mean we switch
		// to STRAIGHT if the touch moves just one pixel left outside of the tracking field

		const CGRect steeringField = CGRectMake(2 * 64, IOS_SCREEN_HEIGHT - 64, IOS_SCREEN_WIDTH- 2 * 64, 64);
		for (UITouch *t in activeTouches)
		{
			CGPoint p = [t locationInView:[t view]];

			if (CGRectContainsPoint(steeringField, p))
			{
				const float tmp = (((p.x - (IOS_SCREEN_WIDTH- fieldWidth)) / fieldWidth) - 0.5) * 20;


				newInput[kVectorSteerRight] = tmp > 0 ? tmp : 0;
				newInput[kVectorSteerLeft] = tmp < 0 ? -tmp : 0;
			}
			else if (CGRectContainsPoint(leftBottom, p))
				newInput[kVectorAccelerate] += 4;
			else if (!game.accelWeapon && CGRectContainsPoint(leftBottomAdjacent, p))
			{
				[self handleFirePressed];
				[touchesToRemove addObject:t];
				fired = YES;
			}
		}
		newInput -= vector3f(3.0f, 0.0f, 0.0f);
	}

	[activeTouches removeObjectsInArray:touchesToRemove];
	[touchesToRemove release];



	if (!fired)
		[self handleFireNotPressed];

	return newInput;
}
#endif

- (void)collideWithBonusboxes:(vector3f)oldPosition
{
	BOOL canPickupNitro = [powerup canPickupNitro];
	BOOL canPickupWeapon = [powerup canPickupWeapon];

	if (canPickupNitro || canPickupWeapon)
	{
		for (BonusBox *bonusbox in game.bonusboxen)
		{
			if ([bonusbox enabled])
			{
				BOOL isSpeedbox = [bonusbox isSpeedbox];

				if ((isSpeedbox && canPickupNitro) ||
						(!isSpeedbox && canPickupWeapon))
				{
					if (length([bonusbox position] - position) > 30)
						continue;

					TriangleIntersectionInfo tif = [bonusbox intersectWithNode:self];
					BOOL intersects = FALSE;

					if (tif.intersects)
					{
						intersects = TRUE;
					}
					else if (vector3f(oldPosition - position).length() > (octree->rootnode.aabbExtentZ + 1.5))
					{
						vector3f ip = [bonusbox intersectWithLineStart:oldPosition end:position];
						intersects = (ip[1] != FLT_MAX);
					}

					if (intersects)
					{
						[bonusbox playSound];
						[bonusbox setEnabled:NO];

						[game performBlockAfterDelay:2.0 block:^
						{[bonusbox setEnabled:YES];}];

						[powerup pickup:isSpeedbox forShip:self];
						return;
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

		if (length([mine position] - position) > 30)
			continue;


		BOOL intersects = FALSE;

		if ([self intersectsWithNode:mine])
		{
			intersects = TRUE;
		}
		else if (vector3f(oldPosition - position).length() > (octree->rootnode.aabbExtentZ + 1.5))
		{
			vector3f ip = [mine intersectWithLineStart:oldPosition end:position];
			intersects = (ip[1] != FLT_MAX);
		}

		if (intersects)
		{
			[self hit:kLittleHit];
			[ourHUD addWeaponMessage:$stringf(@"%@ tripped onto an anonymous mine!", [self name])];

			[tmp addObject:mine];
			[mine setEnabled:NO];
		}
	}
	[[game.mineNode children] removeObjectsInArray:tmp];
	[tmp release];
}

- (void)updateNode
{
	//  NSLog(@"update PS frmae %i", globalInfo.frame);
	[shieldSphereNode setEnabled:shieldVisible];
	[damageSphereNode setEnabled:damageVisible];

	if (((game.flightMode == kFlightGame && [game flightTime] > 3.0f) || (game.flightMode == kFlightEpilogue)) &&
			!isRescuing)
	{
		vector3f oldPosition = position;
		static int dumbcoll = 0;
		int prevdumb = dumbcoll;
		BOOL collided = FALSE;

		//NSLog(@"ps update");

		if ([self round] == 0)
		{
			[self setRound:1];

			input = vector3f(5, 0, 0);
		}
		else
		{
			if (!useController)
				input = [self processInput:input];
#ifndef TARGET_OS_IPHONE            
            else
                input = [self processInputController:input];
#endif
		}

		// check keys, fire1 powerup, calculate pressed times

		//     cout << input << endl;
		for (uint8_t v = 0; v < 3; v++)
		{
			if (input[v] < 0) input[v] = 0;
			if (input[v] > 10) input[v] = 10;
		}

		// calculate forces
#ifndef TARGET_OS_IPHONE
        float collisionDelay = game.simTime - lastWallCollision;
        shipWallhitAccelerationSlowdownFactor = (collisionDelay > 1.0) ? 1.0 : sin(collisionDelay*M_PI/2.0f);
#endif
		// cout << shipWallhitAccelerationSlowdownFactor << endl;
		float frameFactor = (globalInfo.frameDiff / (16666.6 / 1000000.0));
		rotation[2] = 0.0;
		vector3f acceleration = vector3f(0, 0, 0);
		vector3f forward = [self getLookAt];
		vector3f forwardAccelerationForce = forward * ((input[0] / 200.0f) + ((game.flightMode == kFlightGame) ? 0.001f : 0.00001f) - (velocity.length() * 0.025f)) * (shipAcceleration * shipWallhitAccelerationSlowdownFactor);
		vector3f rightAccelerationForce = vector3f(-forward[2], forward[1], forward[0]) * ((input[1] / 500.0f) * (velocity.length() + 0.1f)) * shipHandling;
		vector3f leftAccelerationForce = vector3f(forward[2], forward[1], -forward[0]) * ((input[2] / 500.0f) * (velocity.length() + 0.1f)) * shipHandling;
		//   cout << leftAccelerationForce << endl;
		acceleration += forwardAccelerationForce;
		acceleration += rightAccelerationForce;
		acceleration += leftAccelerationForce;

		acceleration[1] = 0;  // HACKALARM: why do we need this
		acceleration *= (globalInfo.frameDiff / 0.01668);

		velocity += acceleration;
		velocity *= 1.0 - (1.0 - weaponSlowdownFactor) / 4.0;

		if (fabsf(velocity[0]) < 0.001f) velocity[0] = 0;    // HACKALARM: could this be eliminated?
		if (fabsf(velocity[2]) < 0.001f) velocity[2] = 0;    // HACKALARM: could this be eliminated?


		speed = velocity * shipTopSpeed * trackSpeedModifier;
		if ([powerup speedUp])
			speed *= 1.0f + [powerup speedUp] * 0.7;


		float speedMag = speed.length();

		if (globalInfo.frame % 2 == 0)
		{
			float pitch = speedMag / shipTopSpeed / trackSpeedModifier;
			pitch = MIN(pitch, maxpitch);
			[self setPitch:0.5 + pitch / 1.7];
		}
		[fire1 setSize:0.1 + (isRescuing ? 0.0 : speedMag) / 1.5];
		[fire2 setSize:0.1 + (isRescuing ? 0.0 : speedMag) / 1.5];

		if ([powerup speedUp])
			[attachedCamera setFov:kGameFov + [powerup speedUp] * 30];



		// collision against track border and enemies
		float div = (octree->rootnode.aabbExtentX * 3 < octree->rootnode.aabbExtentZ) ? octree->rootnode.aabbExtentX * 3 : octree->rootnode.aabbExtentZ;
		div *= 0.3; // TODO: THIS IS A HACKWORKAROUND

		uint8_t times = (speedMag * frameFactor) / div;
//        if (globalInfo.frame % 30 == 0)
//            printf(" %f ", (speedMag * frameFactor));

		times++;
		vector3f addition = (speed * frameFactor) / times;

		//NSLog(@"accel speed realspeed %f %f %f", acceleration.length(), speedMag, addition.length());
//        printf("\nstarting coll testing: %f %f %i %f\n", div, addition.length(), times, frameFactor);
//        NSLog(@"pos, add, velo");
//        cout << position << "  " << addition << "  "  << velocity << endl;

		for (int i = 1; i <= times; i++)
		{
			[self setPosition:position + addition];

			//printf(" advancing\n");
			//cout << position << endl;

			TriangleIntersectionInfo firsttif = [game.currentTrackBorder intersectWithNode:self];

			if (firsttif.intersects)
			{
				//NSLog(@"  intersects\n");

				vector3f normal = firsttif.normal;//unit_cross(tif.v1 - tif.v2, tif.v1 - tif.v3);

				float angle = fabsf(cml::deg(unsigned_angle(normal, velocity)) - 90.0f);

				//cout << normal << endl;

				//				BOOL done = FALSE;
				//				while (!done)
				//				{
				//					[self setPosition:position - addition/5.0];
				//					printf("moving back");
				//					TriangleIntersectionInfo tif = [game.currentTrackBorder intersectWithNode:self];
				//					done = !tif.intersects;
				//
				//					cout << position << endl;
				//				}

				//				[self setPosition: position - addition];
				[self setPosition:position + (normal * firsttif.depth)];
				//	cout << "  set back" << (position + (normal * firsttif.depth)) << "  " << position << "  " << normal << "  " << firsttif.depth << endl;


				TriangleIntersectionInfo tif = [game.currentTrackBorder intersectWithNode:self];
				if (tif.intersects)
				{
					//     	NSLog(@"still intersects, another setback");
					[self setPosition:position - (normal * tif.depth) - addition];
				}
				//	cout << "  set back" << (position + (normal * tif.depth)) << "  " << position << "  " << normal << "  " << tif.depth << endl;

				normal *= sinf(cml::rad(angle + 1)) * velocity.length() * (iOS ? 1.4f : 0.8f);
				velocity += normal;
				velocity[1] = 0;
				// cout << angle << endl;

				float cosinus = cosf(cml::rad(MAX(10, angle)));
				cosinus *= cosinus;

				if (cosinus > 0.2f)
					velocity *= cosinus - 0.05f;
				else
					velocity = (iOS) ? normal : vector3f(0, 0, 0);
				//		velocity *= (cosinus > 0.2f ? cosinus - 0.05f : 0.0f);
//                if (cosinus <= 0.2f)
//                    printf("  zeroing velocity");





				[wallSoundNode setPosition:position];
				[wallSoundNode updateSound];
				[wallSoundNode playSound];


				noWallhit = FALSE;

				if (angle < 10.0f && spark)
				{
					[spark setEnabled:YES];
					[spark setPosition:firsttif.point - forward - vector3f(0, 0.5, 0)];

					//                [spark setRotationFromLookAt:firsttif.point + cml::cross(firsttif.normal, vector3f(0,1,0))];
					//                [spark setSize:15 * speedMag];
					[spark setRotation:[self rotation]];
					[spark setSize:speedMag];


					//                [game addAnimationWithDuration:1.0
					//                                     animation:^(double delay){   [spark setSize:sinf(delay*M_PI) * 15 * speedMag];}
					//                                    completion:^{[spark setEnabled:FALSE];}];

					[game performBlockAfterDelay:0.5 block:^
					{[spark setEnabled:FALSE];}];
				}

				if (game.simTime - lastWallCollision > 1.0f)
				{
					core -= 7;
					core = MAX(0, core);
				}
				collided = TRUE;
				lastWallCollision = game.simTime;

				break;
			}
			else if (game.gameMode != kGameModeTimeAttack)
			{
				for (SceneNode <Ship> *e in game.ships)
				{
					if (e == self || ![e enabled])
						continue;

					if (abs(currpointfull - [e currpointfull]) > 10)
						continue;

					if (length(position - [e position]) > 6)
						continue;

					TriangleIntersectionInfo enemytif = [e intersectWithNode:self];

					if (enemytif.intersects)
					{
						//printf("  intersects\n");

						vector3f normal = enemytif.normal;//unit_cross(tif.v1 - tif.v2, tif.v1 - tif.v3);


						//cout << normal << endl;

						//				BOOL done = FALSE;
						//				while (!done)
						//				{
						//					[self setPosition:position - addition/5.0];
						//					printf("moving back");
						//					TriangleIntersectionInfo tif = [game.currentTrackBorder intersectWithNode:self];
						//					done = !tif.intersects;
						//
						//					cout << position << endl;
						//				}

						//				[self setPosition: position - addition];
						[self setPosition:position + (normal * enemytif.depth)];
						//  	cout << "  set back" << (position + (normal * tif.depth)) << "  " << position << "  " << normal << "  " << enemytif.depth << endl;


						TriangleIntersectionInfo tif = [e intersectWithNode:self];
						if (tif.intersects)
						{
							//	NSLog(@"still intersects, another setback");
							[self setPosition:position - (normal * tif.depth) - addition];
						}
						//		cout << "  set back" << (position + (normal * tif.depth)) << "  " << position << "  " << normal << "  " << tif.depth << endl;


						velocity *= 0.7;
						collided = TRUE;
						lastEnemyCollision = game.simTime;

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

						if ((length([e position] - position) < 1.5))
						{
							dumbcoll++;
							if (dumbcoll > 30)
							{
								falling = 200;
							}
						}

						break;
					}
				}
			}
			//			else
			//				printf(" doesn't intersect\n");
		}
		//		printf("done\n");

		// adjust elevation
		vector3f intersectionPoint = [game.currentTrack intersectWithLineStart:(position + vector3f(0, 35, 0)) end:(position - vector3f(0, 35, 0))];
		if ((intersectionPoint[1] != FLT_MAX) && (falling < kMaxFallingCount))
		{
			[self setPosition:vector3f(position[0], intersectionPoint[1] + Y_OFFSET, position[2])];
			falling = 0;
		}
		else
		{
			falling++;
			if (falling < 100)
				position[1] -= 0.004 * pow_f(falling, 1.5);

			if (falling >= 60)
			{
				core = MAX(core - 10, 0);
				//disable coremode
				coreModeActive = NO;
				slowmoFinish = game.simTime;
				coreModeFinish = game.simTime;
				globalSettings.slowMotion = kNoSlowmo;


				isRescuing = YES;
				[ourHUD addMessage:@"Rescue in progress" urgent:NO];

				velocity = vector3f(0, 0, 0);
				[self setPitch:0.5];

				vector3f currpos = position;

				vector3f dest = [game.currentTrack positionAtIndex:currpoint]; // + vector3f(0,1,0);
				vector3f diff = dest - position;

				vector3f currrot = rotation;
				static const vector3f forward = vector3f(0, 0, -1);
				vector3f diffrot = [game.currentTrack positionAtIndex:currpoint + 1] - dest;
				vector3f direction_without_y = vector3f(diffrot[0], 0, diffrot[2]);
				float yrotdeg = cml::deg(unsigned_angle(forward, direction_without_y));
				float angleY = diffrot[0] > 0 ? -yrotdeg : yrotdeg;
				vector3f destRot = vector3f(currrot[0], angleY, currrot[2]);

				vector3f yDiff = diff;
				yDiff[0] = 0;
				yDiff[2] = 0;
				if (falling < 100)
					yDiff[1] += 4;

				vector3f xzDiff = diff;
				xzDiff[1] = 0.0;

				[game addAnimationWithDuration:2.0
				                     animation:^(double delay)
				                     {
					                     if (delay <= 1.0)
						                     [self setPosition:currpos + yDiff * delay];
					                     else
						                     [self setPosition:currpos + yDiff + xzDiff * (delay - 1)];
					                     [self setRotation:currrot * (1.0 - delay / 2.0) + destRot * (delay / 2.0)];
				                     }
						            completion:^
						            {
							            isRescuing = FALSE;
							            falling = 0;
							            hasBeenFalling = TRUE;
						            }];

				[game performBlockAfterDelay:3.0 block:^
				{hasBeenFalling = FALSE;}];
			}
		}
		//NSLog(@"update frame playernumber %i %i", globalInfo.frame, playerNumber);
		// calculate nearest trackpoint, advance round, check direction
		BOOL done = FALSE;
		short ocp = currpoint;
		currpoint -= 5;
		if (currpoint < 0)
			currpoint = _numPoints + currpoint;
		vector3f cp = [game.currentTrack positionAtIndex:currpoint];

		float bestDistance = length(position - cp);
		while (!done)
		{
			int np = currpoint + 1;
			if (np >= _numPoints)
				np = 0;

			cp = [game.currentTrack positionAtIndex:currpoint];

			float dist = length(position - cp);
			if (dist > bestDistance)
				done = TRUE;
			else
			{
				bestDistance = dist;
				currpoint = np;
			}
		}


		int c = min((int) ((float) currpoint / ((float) _numPoints / (float) globalInfo.pvsCells)), globalInfo.pvsCells - 1);
		rp.currentPVSCell = c;

		if (game.trackNum > kNumTracks) // should be >= but track 7 has its own pvs
			rp.currentPVSCell = globalInfo.pvsCells - 1 - rp.currentPVSCell;

		if (fabsf(_numPoints / 2 - currpoint) < 50)
		{
			didntCheat = YES;
			//	NSLog(@"didnt cheat");
		}

		if ((ocp - currpoint) > 200 && didntCheat)
		{
			[self setRound:round + 1];

#ifndef DEBUG
			didntCheat = NO;
#endif
		}
		else if (ocp > currpoint)
		{
			if (!falling && !hasBeenFalling)
				[ourHUD addMessage:@"Wrong way" urgent:NO];
		}
		currpointfull = currpoint + _numPoints * (round - 1);
		//NSLog(@" %i %i %f", ocp, currpoint, bestDistance);



		// calculate rotation
		if (velocity.length() > 0.005)    // HACKALARM: could this be eliminated?
		{
			vector3f normalizedVelocity = normalize(velocity);
			vector3f newLookAt = position + normalizedVelocity;

			vector3f oldforward = vector3f(forward[0], velocity[1], forward[2]);
			float angle = cml::deg(unsigned_angle(oldforward, velocity));
			if (oldforward[2] * velocity[0] - oldforward[0] * velocity[2] < 0)
				angle = -angle;

			if (fabsf(angle) / frameFactor > 8.0)
			{
				//NSLog(@"Warning: too big a rotation detected, correcting! %f", angle);
				vector3f perp = normalize(cross(oldforward, velocity));
				vector3f nearlyForward = rotate_vector(oldforward, perp, cml::rad(8.0f));

				//NSLog(@"result %f %f ",  cml::deg(unsigned_angle(oldforward, nearlyForward)),  cml::deg(unsigned_angle(velocity, nearlyForward)));
//
//                cout << perp << endl;
//
//                cout << oldforward << endl;
//                cout << velocity << endl;
//                cout << nearlyForward << endl;
				//NSLog(@" lengths %f %f %f", oldforward.length(), velocity.length(),  nearlyForward.length());

				velocity = nearlyForward * velocity.length();
				normalizedVelocity = normalize(velocity);
				newLookAt = position + normalizedVelocity;

				if (angle > 0)
					angle = 8.0 * frameFactor;
				else
					angle = -8.0 * frameFactor;
			}

			vector3f intersectionPointFront = [game.currentTrack intersectWithLineStart:newLookAt end:vector3f(newLookAt[0], -10000, newLookAt[2])];

			if (intersectionPointFront[1] != FLT_MAX && (falling < kMaxFallingCount))
			{
				[self setRotationFromLookAt:vector3f(newLookAt[0], intersectionPointFront[1] + Y_OFFSET, newLookAt[2])];
				rotationXRingbuffer[globalInfo.frame % kX_RBSize] = rotation[0];

				float sum = 0.0;

				for (int i = 0; i < kX_RBSize; i++)
					sum += rotationXRingbuffer[i];

				rotation[0] = sum / (float) kX_RBSize;
			}
			else
			{
				[self setRotationFromLookAt:vector3f(newLookAt[0], newLookAt[1], newLookAt[2])];
//				NSLog(@"Warning: we seem to be off track!");
			}

			// NSLog(@"velocityrot %f mag %f ", cml::deg(unsigned_angle(vector3f(0,0,1), velocity)), velocity.length());

//			vector3f newforward = [self getLookAt];
//			newforward[1] = forward[1];
//			float angle = cml::deg(unsigned_angle(forward, newforward));
			//			if (angle > 4.5) angle = 4.5;

			vector3f sideDir = normalize(cross(vector3f(0.0f, 1.0f, 0.0f), normalizedVelocity)) * 0.5;
			vector3f sidePoint = position + sideDir;
			vector3f intersectionPointSide = [game.currentTrack intersectWithLineStart:sidePoint end:vector3f(sidePoint[0], -10000, sidePoint[2])];
			vector3f intersectionPointSideCorrected = intersectionPointSide + vector3f(0.0, Y_OFFSET, 0.0f);
			float sideAngle = cml::deg(unsigned_angle(vector3f(0.0f, 1.0f, 0.0f), (intersectionPointSideCorrected - position)));
			// cout << sideAngle << endl;

			if (!collided && intersectionPointSide[1] != FLT_MAX)
				rotation[2] = sideAngle - 90.0f + (angle * 10 / frameFactor);
			else
				rotation[2] = 0;
			rotationZRingbuffer[globalInfo.frame % kZ_RBSize] = rotation[2];

			float sum = 0;
			for (int i = 0; i < kZ_RBSize; i++)
			{
				sum += rotationZRingbuffer[i];
			}
			rotation[2] = sum / (float) kZ_RBSize;


			//if (rotation[2] > 40)
			//	NSLog(@"doh");

			//NSLog(@"angle %0.2f speed %0.4f %0.4f %0.4f (%0.4f) accel frl %.4f %.4f %.4f ", angle / frameFactor, speed[0], speed[1], speed[2], speedMag, forwardAccelerationForce.length(), rightAccelerationForce.length(), leftAccelerationForce.length());
			//cout << intersectionPoint << endl;
			//cout << rotation << endl;
		}
		else
		{
			//	NSLog(@"skipping rotation");
		}

		[self collideWithBonusboxes:oldPosition];
		[self collideWithMines:oldPosition];

		if ((game.gameMode == kGameModeCareer || game.gameMode == kGameModeCustomGame) && (game.flightMode != kFlightEpilogue) && !falling && !isRescuing)
		{
			core += frameFactor / 40.0;

			if (core > 100 && [powerup loaded])
			{
				slowmoFired = FALSE;
				coreModeFinish = game.simTime + 5.0f;
				coreModeActive = TRUE;
				shipTopSpeed += 0.1f;
				shipHandling += 0.1f;
				coreModeIntensity = 0.0f;
				int tmpOutlines = globalSettings.outlineMode;
				globalSettings.outlineMode = 3;
				[ourHUD addMessage:@"CoreMode Activated" urgent:NO];

				[game addAnimationWithDuration:5.0f
				                     animation:^(double delay)
				                     {coreModeIntensity = MIN(1.0f, sinf(delay * M_PI / 5.0f) * 2.5f);}
						            completion:^
						            {
							            coreModeActive = FALSE;
							            globalSettings.outlineMode = tmpOutlines;
							            shipTopSpeed -= 0.1f;
							            shipHandling -= 0.1f;
						            }];
				core -= 100;
				Play_Sound(sounds.coremode);
			}
		}

		if (dumbcoll == prevdumb)
			dumbcoll = 0;
	}


	// update placing
	if (game.gameMode != kGameModeTimeAttack)
	{
		int pos = [game.ships count];
		short disabled = 0;
		for (SceneNode <Ship> *e in game.ships)
		{
			if (e == self)
				continue;

			if ([e enabled])
			{
				if (currpointfull > [e currpointfull])
				{
					pos--;

					//NSLog(@" enemy behind %i %i (self %i %i)", [e currpoint],[e round], currpoint, round);
				}
			}
			else
				disabled++;
		}
		[self setPlacing:pos - disabled];

		if (placing != 1)
			alwaysLeading = FALSE;
	}
	//[super updateNode];



	// adjust shipcolor based on track lighting
#ifndef WIN32
	if (!isHit && game.flightMode == kFlightGame)
	{
		float l = [game.currentTrack lightAtPoint:CGPointMake(position[0], position[2])];
		if (l > 0.0f)
		{
			float intensity = 0.4f + (l * 0.6f);
			[self setColor:vector4f(1.0f, 1.0f, 1.0f, 1.0f / 0.4f) * intensity];
		}
		else
			[self setColor:vector4f(1.0f, 1.0f, 1.0f, 1.0f)];
	}
#endif

	//cout << position << endl;

	// adjust wallhit B&W postproc
	float lastCollision = MAX(lastEnemyCollision, lastWallCollision);
	if (game.simTime - lastCollision < 1.3f)
	{
		if (game.postProcessingLevel > 1)
		{
			[_ourPP setGrayEnabled:YES];
			[_ourPP setGrayIntensity:MIN(1.3f - (game.simTime - lastCollision), 1.0f)];
		}
	}
	else
	{
		if (game.postProcessingLevel > 1)
			[_ourPP setGrayEnabled:NO];
	}


	if (game.gameMode == kGameModeTimeAttack)
	{
		float time = [ourHUD timeInCurrentRound];
		int snapshotCount = time * 30.0f;

		while ([ghostData length] < 2 * 3 * sizeof(float) * snapshotCount)
			[self recordGhost];
	}
}

- (NSString *)name
{
	return playerNumber ? $default(kSecondNicknameKey) : $default(kNicknameKey);
}

- (void)resetLapObjectives
{
	alwaysLeading = TRUE;
	noWallhit = TRUE;
}

- (void)adjustCamera:(BOOL)lookBack
{
	if (cameraMode == 0)
	{
		[game.shieldSphere setDoubleSided:NO];
		[game.damageSphere setDoubleSided:NO];

		[attachedCamera setPosition:vector3f(0, 3.75, lookBack ? -6 : 6)];
		[attachedCamera setRotation:vector3f(lookBack ? 10 : -10, lookBack ? 180 : 0, 0)];

		[attachedCamera setRelativeModeAxisConfiguration:AXIS_CONFIGURATION( kYAxis, kDisabledAxis, kDisabledAxis)];
//        [attachedCamera setRelativeModeAxisConfiguration:AXIS_CONFIGURATION(kZAxis, kXAxis, kYAxis)];
	}
	else if (cameraMode == 1)
	{
		[game.shieldSphere setDoubleSided:NO];
		[game.damageSphere setDoubleSided:NO];

		if (shipNum == 2 || shipNum == 3)
			[attachedCamera setPosition:vector3f(0, 0.9, lookBack ? -2.25 : 2.55)];
		else
			[attachedCamera setPosition:vector3f(0, 1, lookBack ? -2.25 : 2.25)];
		[attachedCamera setRotation:vector3f(lookBack ? 10 : -10, lookBack ? 180 : 0, 0)];

//		[attachedCamera setRelativeModeAxisConfiguration:AXIS_CONFIGURATION(kXAxis, kYAxis, kDisabledAxis)];
		[attachedCamera setRelativeModeAxisConfiguration:AXIS_CONFIGURATION(kZAxis, kXAxis, kYAxis)];
	}
	else if (cameraMode == 2)
	{
		[game.shieldSphere setDoubleSided:YES];
		[game.damageSphere setDoubleSided:YES];

		[attachedCamera setPosition:vector3f(0, 0, lookBack ? 1 : -1)];
		[attachedCamera setRotation:vector3f(0, lookBack ? 180 : 0, 0)];

//		[attachedCamera setRelativeModeAxisConfiguration:AXIS_CONFIGURATION(kXAxis, kYAxis, kDisabledAxis)];
		[attachedCamera setRelativeModeAxisConfiguration:AXIS_CONFIGURATION(kZAxis, kXAxis, kYAxis)];
	}
}

- (void)renderNode
{
	if (currentCamera != attachedCamera ||
			cameraMode != 2) if (!globalSettings.shadowMode && currentRenderPass.settings == kMainRenderPass && !falling)
	{
		[currentCamera push];
		[currentCamera identity];
		float rot = rotation[2];
		rotation[2] = 0;
		[self transform];
		rotation[2] = rot;
		matrix44f_c viewMatrix = [currentCamera modelViewMatrix];

		struct octree_node const *const n1 = (struct octree_node *) NODE_NUM(0);
		const float aabbOriginX = n1->aabbOriginX * 1.4;
		const float aabbExtentX = n1->aabbExtentX * 1.4;
		const float aabbOriginZ = n1->aabbOriginZ * 1.2;
		const float aabbExtentZ = n1->aabbExtentZ * 1.2;
		const float offset = -Y_OFFSET * 0.95;

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

	if (currentRenderPass.settings == kMainRenderPass)
		[exhaustLight setLinearAttenuation:0.5 + MAX((-speed.length() / 2) + 1, 0)];

	if (currentCamera != attachedCamera ||
			cameraMode != 2)
	{
//        if (falling >= kMaxFallingCount)
//        {
//            BlendFunc(GL_CONSTANT_ALPHA, GL_ONE_MINUS_CONSTANT_ALPHA);
//            BlendColor(1.0, 1.0, 1.0, 0.4);
//        }

		[super renderNode];
	}
}

- (void)render
{
	rotation[1] += weaponYRotAddition;

	[super render];

	rotation[1] -= weaponYRotAddition;
}

- (void)dealloc
{
	//  NSLog(@"s release");

	[[[game shieldSphereNode] children] removeObject:shieldSphereNode];
	[[[game damageSphereNode] children] removeObject:damageSphereNode];

#ifndef TARGET_OS_IPHONE
    [hid release];
#endif

	[collSoundNode release];
	if (spark)
		[spark release];

	[powerup release];

	[ghostData release];
	[fire1 release];
	[fire2 release];
	[wallSoundNode release];
//    [hitSoundNode release];
	for (int i = 0; i < 5; i++)
		UnloadSound(hitSoundArray[i]);

	[super dealloc];
}

- (void)hasHit:(BOOL)_deadly
{
	core += _deadly ? 40 : 15;

	if (_deadly)
	{
		[ourHUD addMessage:@"CoreBreach" urgent:YES];
		[ourHUD addAward:kAwardCorebreach];
		globalSettings.slowMotion = kNitroSlowmo;

		[game performBlockAfterDelay:0.5 block:^
		{globalSettings.slowMotion = kNoSlowmo;}];
	}
	else
		[ourHUD addAward:kAwardObtainHit];
}

- (void)hit:(hitEnum)severity
{
	if (game.flightMode == kFlightEpilogue)
		return;

	isHit = YES;
	[self setColor:vector4f(1.0, 0.0, 0.0, 1.0)];


#ifndef DISABLE_SOUND
	if (globalSettings.soundEnabled)
	{
		//    [hitSoundNode playSound];
		//  [(NSSound *)[NSSound soundNamed:@"hit"] play];
		hitSoundIndex++;
		if (hitSoundIndex == 5)
			hitSoundIndex = 0;

		Play_Sound(hitSoundArray[hitSoundIndex]);
	}
#endif

	core -= 20;
	core = MAX(0, core);

	[_ourPP setGlassEnabled:YES];

	if (severity != kDeadlyHit)
	{
		[self setDamageVisible:[self damageVisible] + 1];

		float duration = 0, factor = 0, addition = 0;
		if (severity == kLittleHit)
		{
			duration = 1.0f;
			factor = 0.3f;
			addition = 0.7f;
		}
		else if (severity == kMediumHit)
		{
			duration = 1.1f;
			factor = 0.4f;
			addition = 0.6f;
		}
		else if (severity == kBigHit)
		{
			duration = 1.2f;
			factor = 0.5f;
			addition = 0.5f;
		}

		[game addAnimationWithDuration:duration
		                     animation:^(double delay)
		                     {
			                     weaponSlowdownFactor = cosf(delay * M_PI * 2.0 / duration) * factor + addition;
			                     weaponYRotAddition = 360 - (delay * 360 / duration);
			                     [fire1 setEnabled:NO];
			                     [fire2 setEnabled:NO];
			                     [self setColor:vector4f(1.0, delay / duration, delay / duration, 1.0)];
			                     [_ourPP setGlassIntensity:sinf(delay * M_PI)];
		                     }
				            completion:^
				            {
					            isHit = FALSE;
					            [_ourPP setGlassEnabled:NO];
					            [self setDamageVisible:[self damageVisible] - 1];
					            weaponYRotAddition = 0;
					            [fire1 setEnabled:YES];
					            [fire2 setEnabled:YES];
				            }];
	}
	else
	{
		[ourHUD addMessage:@"You have been CoreBreached" urgent:YES];

		[game addAnimationWithDuration:2.0
		                     animation:^(double delay)
		                     {
			                     weaponSlowdownFactor = 1.0 - (delay * delay) / 5.0;
			                     [_ourPP setGlassIntensity:delay];
		                     }
				            completion:^
				            {
					            isHit = FALSE;
					            [game advanceFlightMode];
				            }];
	}
}

#ifdef __COCOTRON__
- (void)setRound:(short)_round
{
    [self willChangeValueForKey:@"round"];
    round = _round;
    [self didChangeValueForKey:@"round"];
}
#endif
@end