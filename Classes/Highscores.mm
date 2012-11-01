//
//  Highscores.m
//  CoreBreach
//
//  Created by CoreCode on 11.01.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#import "CoreBreach.h"
#import "Core3D.h"
#import "Highscores.h"


#ifdef __APPLE__
#include <CommonCrypto/CommonDigest.h>


#else
#include <sha1.h>
#endif



#ifdef SDL
int synchronousRequesThread(void *param)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSURLRequest *request = (NSURLRequest *)param;
   // NSLog([request description]);

    //	NSData *result = 
    [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:NULL];
   // 	NSString* aStr;
    //	aStr = [[NSString alloc] initWithData:result encoding:NSASCIIStringEncoding];
    // 	NSLog(@"result %@", aStr);
    [request release];
    [pool release];
    
#ifdef GNUSTEP
    pthread_exit(NULL);
#endif
    return(0);
}
#endif

@implementation Highscores

+ (NSString *)sha1:(NSString *)input
{
#ifdef __APPLE__
	NSData *d = [input dataUsingEncoding:NSUTF8StringEncoding];
	unsigned char result[CC_SHA1_DIGEST_LENGTH];
	CC_SHA1([d bytes], [d length], result);
	NSMutableString *ms = [NSMutableString string];

	for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
	{
		[ms appendFormat:@"%02x", (int) (result [i])];
	}

//	NSLog(@"%@", ms);

	return [[ms copy] autorelease];
#else
    NSData *d = [input dataUsingEncoding:NSUTF8StringEncoding];
	NSMutableString *ms = [NSMutableString string];

    SHA1Context sha;
    SHA1Reset(&sha);
    SHA1Input(&sha, (const unsigned char *) [d bytes], [d length]);
    
    if (!SHA1Result(&sha))
    {
        fprintf(stderr, "ERROR-- could not compute message digest\n");
    }
    else
    {
        //printf("\t");
        for(int i = 0; i < 5 ; i++)
        {
            [ms appendFormat: @"%08x", sha.Message_Digest[i]];
        }
    }
    
    return [[ms copy] autorelease];
#endif
}

- (void)storeHighscore:(float)time forMode:(int)mode forNickname:(NSString *)nickname onTrack:(uint32_t)track withShip:(uint8_t)ship
{
	NSString *modeStr = [$array(@"Career", @"Custom", @"TimeAttack") objectAtIndex:mode];

	NSString *key = $stringf(@"Highscores%@Track%i", modeStr, track);

	NSMutableArray *hs = [[NSMutableArray alloc] initWithArray:$default(key)];

	int insert = [hs count];
	for (uint32_t i = 0; i < [hs count]; i++)
	{
		if ([[[hs objectAtIndex:i] valueForKey:@"time"] floatValue] > time)
		{
			insert = i;
			break;
		}
	}

	NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:$numd(time), @"time",
	                                                                  nickname, @"nickname",
	                                                                  $numi(ship), @"ship", nil];

	[hs insertObject:dict
	         atIndex:insert];

	$setdefault(hs, key);

#ifdef __APPLE__
	dispatch_async(dispatch_get_global_queue(0, 0), ^
	{
		$defaultsync;
	});
#endif

	[hs release];
	[dict release];
}

- (void)sendHighscore:(float)time forMode:(int)mode forNickname:(NSString *)nickname onTrack:(uint32_t)track withShip:(uint8_t)ship withData:(NSData *)_data
{
    NSLog(@"send highscore unimplemented in open source builds");
}

- (NSArray *)getHighscoresForMode:(int)mode forNickname:(NSString *)nickname onTrack:(uint32_t)track
{
	//NSLog(@"getting highscores");
	nickname = [nickname stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

	NSString *modeStr = [$array(@"career", @"custom", @"timeattack") objectAtIndex:mode];
#ifdef TARGET_OS_IPHONE
	NSString *urlString = $stringf(@"http://corebreach.corecode.at/cgi-bin/gethighscore-ios.cgi?mode=%@&track=%i&nickname=%@", modeStr, track, nickname);
#else
	NSString *urlString = $stringf(@"http://corebreach.corecode.at/cgi-bin/gethighscore.cgi?mode=%@&track=%i&nickname=%@", modeStr, track, nickname);
#endif
	NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

	[request setTimeoutInterval:10.0];

	NSError *_error = nil;
	NSHTTPURLResponse *response = NULL;
	NSData *_data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&_error];

	if (_data
			&& response && ([response statusCode] == 200)
			&& (_error == nil))
	{

		NSXMLParser *parser = [[NSXMLParser alloc] initWithData:_data];

		//NSLog(@"datasizte %i", [_data length]);
		//NSLog([_data description]);

		highscores = [[NSMutableArray alloc] init];


		[parser setDelegate:self];
		[parser setShouldProcessNamespaces:NO];
		[parser setShouldReportNamespacePrefixes:NO];
		[parser setShouldResolveExternalEntities:NO];

		[parser parse];

		if ([parser parserError])
			printf("Error: error parsing  highscores");

		[parser release];

		// NSLog([highscores description]);

		return [highscores autorelease];
	}
	else
	{
		//NSLog(@"Warning: couldnt get highscores %x %x %i %x %@", _data, response, [response statusCode], _error, [_data description]);

		return nil;
	}
}

- (void)dealloc
{
	[super dealloc];
}

#pragma mark NSXMLParser delegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if ([elementName isEqualToString:@"score"])
	{
		[highscores addObject:[[attributeDict copy] autorelease]];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
}
@end