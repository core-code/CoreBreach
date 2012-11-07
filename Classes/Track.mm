//
//  Racetrack.m
//  Core3D
//
//  Created by CoreCode on 07.05.08.
//  Copyright 2008 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "Game.h"


#define NORMALIZED_INDEX(index) (((index < 0) ? (trackPoints + index) : index) % trackPoints)

extern float qdTrackpoint;

@implementation Racetrack

@synthesize trackPoints;

- (id)init
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithOctreeNamed:(NSString *)_name
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (id)initWithTracknumber:(uint8_t)_tracknum andMeshtracknumber:(uint8_t)_meshnum
{

	if (game.trackName)
		self = [super initWithOctree:[NSURL fileURLWithPath:[[APPLICATION_SUPPORT_DIR stringByAppendingPathComponent:[game.trackName stringByAppendingString:@".cbtrack"]] stringByAppendingPathComponent:@"trackbase_collision.octree"]] andName:@"trackbase_collision"];
	else
		self = [super initWithOctreeNamed:$stringf(@"track%ubase_collision", _meshnum)];

	if (self)
	{
		meshnum = _meshnum;
		tracknum = _tracknum;
		NSString *trackDataPath;
		if (game.trackName)
			trackDataPath = [[APPLICATION_SUPPORT_DIR stringByAppendingPathComponent:[game.trackName stringByAppendingString:@".cbtrack"]] stringByAppendingPathComponent:@"track.path"];
		else
			trackDataPath = [[NSBundle mainBundle] pathForResource:$stringf(@"track%u", tracknum) ofType:@"path"];

		NSData *trackData = [NSData dataWithContentsOfFile:trackDataPath];
		if (!trackData) fatal("Error: there is no trackData for track %u", tracknum);

		trackPath = (float *) malloc([trackData length]);
		trackPoints = (([trackData length] / 3) / sizeof(float)) - 1;

//		cout << trackPoints << endl;
		[trackData getBytes:trackPath];


		short i;
		for (i = 0; i < MAX_ENEMIES; i++)
		{
			NSString *etrackDataPath;
			if (game.trackName)
				etrackDataPath = [[APPLICATION_SUPPORT_DIR stringByAppendingPathComponent:[game.trackName stringByAppendingString:@".cbtrack"]] stringByAppendingPathComponent:$stringf(@"track.path%i", i)];
			else
				etrackDataPath = [[NSBundle mainBundle] pathForResource:$stringf(@"track%u", tracknum) ofType:$stringf(@"path%i", i)];
			NSData *enemyData = [NSData dataWithContentsOfFile:etrackDataPath];
			if (!trackData) fatal("Error: there is no enemyData for track %u", tracknum);
			enemyPath[i] = (float *) malloc([enemyData length]);
			enemyPoints[i] = (([enemyData length] / 3) / sizeof(float)) - 1;
			[enemyData getBytes:enemyPath[i]];
		}

#ifndef NODATA
#ifndef TARGET_OS_IPHONE
        if (!game.trackName)
        {
#ifndef __COCOTRON__            
            NSImage *img = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:$stringf(@"track%ulight", meshnum) ofType:@"png"]];
   //         trackLightBitmap = [[NSBitmapImageRep imageRepWithData:[img TIFFRepresentation]] retain];

            trackLightBuffer = (char *)malloc(4096 * 4096);
            NSData *d = [img TIFFRepresentationUsingCompression:NSTIFFCompressionNone factor:0.0];
            [d getBytes:trackLightBuffer length:4096 * 4096];


            [img release];
#else
            // cocotron: TIFFRepresentationUsingCompression random crashes
            NSData *lightData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:$stringf(@"track%ulight", meshnum) ofType:@"raw"]];
            if (!lightData) fatal("Error: loading light failed");
            
            trackLightBuffer = (char *)malloc(4096 * 4096);
            [lightData getBytes:trackLightBuffer length:4096 * 4096];
#endif     
            
            // warmup buffer
            float lightSum = 0;
            for (i = 0; i < trackPoints; i++)
            {
                vector3f pos = [self positionAtIndex:i];
                lightSum += [self lightAtPoint:CGPointMake(pos[0], pos[2])];
            }
            trackLightBuffer[0] = (char)(lightSum / trackPoints);
        }
#endif
#endif
	}

	return self;
}

//- (void)renderNode
//{
//	//[super renderNode];
//
//	GLint prog;
//	glDisable(GL_LIGHTING);
//	glGetIntegerv(GL_CURRENT_PROGRAM, &prog);
//	glUseProgram(0);
//
//	int i;
//	myColor(1.0, 0.0, 0.0, 1.0);
//	myPointSize(20);
//	glBegin(GL_POINTS);
//	for (i = 0; i < trackPoints; i++)
//	{
//		myColor(1.0/i, 1.0, 1.0/i, 1.0);
//
//        if (i == (int)[[game ship] currpoint])
//            myColor(1.0, 0, 0, 1.0);
//
//		vector3f cur = [self positionAtIndex:i];
//		glVertex3fv(cur.data());
//
//		vector3f up = vector3f(0, 1, 0);
//		vector3f next = [self positionAtIndex:i+1];
//
////		vector3f perp = cross(up, next-cur).normalize();
////		vector3f side = cur + perp * 18;
////		vector3f oside = cur - perp * 18;
////
////		glVertex3fv(side.data());
////		glVertex3fv(oside.data());
//
//	}
//	int v;
////	for (v = 0; v < 8; v++)
////	{
////		for (i = 0; i < enemyPoints[v]; i++)
////		{
////			myColor(1.0/i, 1.0/v+2, 1.0/i, 1.0);
////			glVertex3f(*(enemyPath[v]+(i)*3+0), *(enemyPath[v]+(i)*3+1) + 2, *(enemyPath[v]+(i)*3+2));
////		}
////	}
//
//	//	myColor(0.4, 0.1, 0.1, 1.0);
//	//	glVertex3f(TRACKX(currpoint), TRACKY(currpoint)+1.1, TRACKZ(currpoint));
//	glEnd();
//	globalInfo.drawCalls++;
///*DRAW_CALL*/
//	glEnable(GL_LIGHTING);
//	glUseProgram(prog);
//}

- (float)lightAtPoint:(CGPoint)point
{
#ifdef TARGET_OS_IPHONE
	return 1.0;
#else
/*
track2
   x scale 3123,31 = 3164 1,013027845458824 0,987139696586599
   x -2068,734 = 0
   x -1390.57 = 687
   x 1732.74  = 3851

   y scale 1700,954 = 1722 1,012373056531805 0,987778164924506
   y -1829,242 = 0
   y -343.624 = 1504
   y 1357.33  = 3226

track3
    xscale 3391,99 = 2970                  1,142084175084175
    x -2308,3260 = 0
    x -1411.79 = 785
    x 1980.2   = 3755

    yscale 2945,15 = 2561              1,15
    y  -2396,67        = 0
    y -1644.57  = 654
    y 1300.58  =  3215


track4
    x scale 3050,52 = 2538   0,831989300184887  1,20193853427896
    x -2453,1112 = 0
    x -1069.68 = 1151
    x 1980.84 = 3689

    y scale 2860,15 = 2373 0,829676765204622 1,205288664138222
    y -2539,9502 = 0
    y -1682.99  =  711
    y 1177.16  =  3084

track5
   x scale 2789,657 = 2405  0,862113155846758 1,159940540540541
   x -1821,687 = 0
   x -863.577 = 826
   x 1926.08 = 3231

   y scale 2080,061 = 1792                    1,160748325892857
   y -2495,22859 = 0positionAtIndex
   y -1520.2 =  840
   y 559.861  =  2632

track6
   xscale 3764,89 = 2908                      1,29466643741403
   x -2910,8779 = 0
   x -2670.07 = 186
   x 1094.82 = 3094

   yscale 2176,971 = 1676                     1,298908711217184
   y -2648,9751 = 0
   y -1440.99  =  930
   y 735.981  =  2606
*/
    int x = 0,y = 0;


    if (meshnum == 1)
    {
        x = (point.x - (-582.3305)) / 0.284;
        y = (point.y - (-436.212)) / 0.284;
    }
    else if (meshnum == 2)
    {
        x = (point.x - (-2068.734)) / 0.987139696586599;
        y = (point.y - (-1829.242)) / 0.987778164924506;
    }
    else if (meshnum == 3)
    {
        x = (point.x - (-2308.3260)) / 1.142084175084175;
        y = (point.y - (-2396.67)) / 1.15;
    }
    else if (meshnum == 4)
    {
        x = (point.x - (-2453.1112)) / 1.20193853427896;
        y = (point.y - (-2539.9502)) / 1.205288664138222;
    }
    else if (meshnum == 5)
    {
        x = (point.x - (-1821.687)) / 1.159940540540541;
        y = (point.y - (-2495.22859)) / 1.160748325892857;
    }
    else if (meshnum == 6)
    {
        x = (point.x - (-2910.8779)) / 1.29466643741403;
        y = (point.y - (-2648.9751)) / 1.298908711217184;
    }
    else if (meshnum == 7)
    {
        x = (point.x - (-582.3305)) / 0.284;
        y = (point.y - (-436.212)) / 0.284;
    }

    //c = [trackLightBitmap colorAtX:x y:y];

    if (meshnum >= 1 && meshnum <= 7)
    {
#ifdef __COCOTRON__
        unsigned char bla = 255 - trackLightBuffer[y * 4096 + x];
#else
        unsigned char bla = trackLightBuffer[y * 4096 + x];
#endif

        return (float)bla / 255.0f;
    }
    else
        return 1.0f;
#endif
}

- (vector3f)positionAtIndex:(int)index
{
	int normalizedIndex = NORMALIZED_INDEX(index);

	return vector3f(*(trackPath + (normalizedIndex) * 3 + 0), *(trackPath + (normalizedIndex) * 3 + 1) + Y_OFFSET, *(trackPath + (normalizedIndex) * 3 + 2));
}

- (vector3f)positionAtIndex:(int)index forEnemy:(uint8_t)enemy
{
	int normalizedIndex = NORMALIZED_INDEX(index);

	return vector3f(*(enemyPath[enemy] + (normalizedIndex) * 3 + 0),
			*(enemyPath[enemy] + (normalizedIndex) * 3 + 1) + Y_OFFSET,
			*(enemyPath[enemy] + (normalizedIndex) * 3 + 2));
}

- (vector3f)interpolatedPositionAtIndex:(float)indexf forEnemy:(uint8_t)enemy
{
	int indexLow = floorf(indexf);
	int indexHigh = ceilf(indexf);
	int normalizedIndexLow = NORMALIZED_INDEX(indexLow);
	int normalizedIndexHigh = NORMALIZED_INDEX(indexHigh);

	vector3f currposition = vector3f(*(enemyPath[enemy] + (normalizedIndexLow) * 3 + 0),
			*(enemyPath[enemy] + (normalizedIndexLow) * 3 + 1),
			*(enemyPath[enemy] + (normalizedIndexLow) * 3 + 2));

	vector3f nextposition = vector3f(*(enemyPath[enemy] + (normalizedIndexHigh) * 3 + 0),
			*(enemyPath[enemy] + (normalizedIndexHigh) * 3 + 1),
			*(enemyPath[enemy] + (normalizedIndexHigh) * 3 + 2));

	float factor;

	if (normalizedIndexHigh < normalizedIndexLow)
		factor = 1.0 - (normalizedIndexHigh - indexf);
	else
		factor = (indexf - normalizedIndexLow);

	vector3f result = currposition + ((nextposition - currposition) * factor);


	result[1] += Y_OFFSET;

	return result;
}

- (uint16_t)enemyPointsForEnemy:(uint8_t)enemy
{
	return enemyPoints[enemy];
}

- (void)dealloc
{
	//[trackLightBitmap release];
	free(trackLightBuffer);
	free(trackPath);

	for (int i = 0; i < MAX_ENEMIES; i++)
		free(enemyPath[i]);


	[super dealloc];
}
@end