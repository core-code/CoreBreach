//
//  main.mm
//  CoreBreach
//
//  Created by CoreCode on 01.01.11.
//  Copyright 2011 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//
#import "Core3D.h"



#ifndef APPLICATIONCLASS
#define APPLICATIONCLASS NSApplication
#else

@interface APPLICATIONCLASS : NSApplication;
@end

#endif

/*
 lightless 
 
 NVIDIA GeForce GT 120 
 NVIDIA GeForce GT 130 
 NVIDIA GeForce 320 
 NVIDIA GeForce 9600
 ATI Radeon HD 2600 
 ATI Radeon X1900 
 
 lightless + hwpcf + fsaa
 
 Intel HD Graphics 3000 
 ATI Radeon X1600 
 NVIDIA GeForce 7600
 NVIDIA GeForce 8600
 
 lightless + fsaa + hwpcf + texfiltering 
 
 ATI Radeon HD 2400
 NVIDIA GeForce 7300
 NVIDIA GeForce 9400 

 */
void CheckOpenGLAndInitSuckyness(void)
{
	globalInfo.properOpenGL = FALSE;


	if (!glGetString(GL_VERSION) || !glGetString(GL_RENDERER))
		return;

	NSString *versionFull = [NSString stringWithUTF8String:(const char *) glGetString(GL_VERSION)];
	NSString *versionOnlyString = [[versionFull componentsSeparatedByString:@" "] objectAtIndex:0];
	NSArray *version = [versionOnlyString componentsSeparatedByString:@"."];
	if (([[version objectAtIndex:0] intValue] == 2 && [[version objectAtIndex:1] intValue] >= 1) ||
			[[version objectAtIndex:0] intValue] > 2)
	{
		globalInfo.properOpenGL = TRUE;
	}
	else
		NSLog(@"Error: OpenGL environment doesn't meet minimum specs because the version needs to be >= 2.1");


	if (!HasExtension(@"EXT_framebuffer_object"))
	{
		NSLog(@"Error: OpenGL environment doesn't meet minimum specs because EXT_framebuffer_object needs to be supported");
		globalInfo.properOpenGL = FALSE;
	}

	GLint test;
	glGetIntegerv(GL_MAX_TEXTURE_SIZE, &test);
	if (test < 4096)
	{
		NSLog(@"Error: OpenGL environment doesn't meet minimum specs because textures of size 4096 are not supported");
		globalInfo.properOpenGL = FALSE;
	}


	glGetIntegerv(GL_NUM_COMPRESSED_TEXTURE_FORMATS, &test);

	BOOL hasDXT1 = FALSE, hasDXT5 = FALSE;

	if (test > 0 && test < 255)
	{
		GLint *testarray = (GLint *) calloc(1, (sizeof( int ) * test));

		glGetIntegerv(GL_COMPRESSED_TEXTURE_FORMATS, &testarray[0]);


		for (GLint idx = 0; idx < test; ++idx)
		{

			if (testarray[idx] == GL_COMPRESSED_RGB_S3TC_DXT1_EXT)
				hasDXT1 = TRUE;
			else if (testarray[idx] == GL_COMPRESSED_RGBA_S3TC_DXT5_EXT)
				hasDXT5 = TRUE;
		}
		free(testarray);
	}
	if (!hasDXT1 || !hasDXT5)
	{

		NSLog(@"Error: OpenGL environment doesn't meet minimum specs because DXT1 or DXT5 compression is not supported");
		globalInfo.properOpenGL = FALSE;
	}


	NSString *renderer = [NSString stringWithUTF8String:(const char *) glGetString(GL_RENDERER)];


	for (NSString *name in $array(@"Software", @"Generic"))
		if (CONTAINS(renderer, name))
			globalInfo.properOpenGL = FALSE;


	for (NSString *name in $array(@"GeForce GT 120", @"GeForce GT 130", @"GeForce 320", @"GeForce 9600", @"Radeon HD 2600", @"Radeon X1900"))
		if (CONTAINS(renderer, name))
			globalInfo.gpuSuckynessClass = 1;


	for (NSString *name in $array(@"GeForce 7600", @"GeForce 8600", @"HD Graphics 3000", @"Radeon X1600"))
		if (CONTAINS(renderer, name))
			globalInfo.gpuSuckynessClass = 2;


	for (NSString *name in $array(@"GeForce 7300", @"GeForce 9400", @"Radeon HD 2400"))
		if (CONTAINS(renderer, name))
			globalInfo.gpuSuckynessClass = 3;

#ifdef TIMEDEMO
	globalInfo.gpuSuckynessClass = 0;
#endif

	NSString *vendor = [NSString stringWithUTF8String:(const char *) glGetString(GL_VENDOR)];


	for (NSString *searchString in $array(@"X.Org ", @"Gallium", @"Mesa"))
		for (NSString *string in $array(renderer, vendor, versionFull))
			if (CONTAINS(string, searchString))
				globalInfo.gpuVendor = kVendorMesa;


	if (CONTAINS(vendor, @"ati"))
		globalInfo.gpuVendor = kVendorATI;


	if (CONTAINS(vendor, @"nvidia"))
		globalInfo.gpuVendor = kVendorNVIDIA;



#ifndef TARGET_OS_MAC
	NSLog(@"Info: properOpenGL %i gpuVendor %i gpuSuckynessClass %i (GL_VERSION: %s GL_RENDERER: %s GL_VENDOR: %s)", globalInfo.properOpenGL, globalInfo.gpuVendor, globalInfo.gpuSuckynessClass, glGetString(GL_VERSION), glGetString(GL_RENDERER), glGetString(GL_VENDOR));
#endif
}

#if !defined(WIN32) && !defined(__linux__)
void PreCheckOpenGL(void)
{
	CGLPixelFormatAttribute attribs[] = {kCGLPFAAccelerated, (CGLPixelFormatAttribute) NULL};
	CGLPixelFormatObj pixelFormat = NULL;
	long numPixelFormats = 0;
	CGLContextObj myCGLContext = 0, curr_ctx = CGLGetCurrentContext();
	CGLChoosePixelFormat(attribs, &pixelFormat, (GLint *) &numPixelFormats);
	if (pixelFormat)
	{
		CGLCreateContext(pixelFormat, NULL, &myCGLContext);
		CGLDestroyPixelFormat(pixelFormat);
		CGLSetCurrentContext(myCGLContext);

		if (myCGLContext)
		{

			GLint value;
			GLint nrend;
			CGLRendererInfoObj rend;
			CGLQueryRendererInfo(CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay), &rend, &nrend);
			CGLDescribeRenderer(rend, 0, kCGLRPMaxSamples, &value);
//            NSLog(@" max samples %i", value);
			globalInfo.maxMultiSamples = value;

			// what is the VRAM
			GLint vram = 0;
			CGLDescribeRenderer(rend, 0, kCGLRPVideoMemory, &vram);
			globalInfo.VRAM = vram;

			CheckOpenGLAndInitSuckyness();

			CGLDestroyRendererInfo(rend);
		}
	}
	CGLDestroyContext(myCGLContext);
	CGLSetCurrentContext(curr_ctx);

	return;
}

void PreCheckOpenGL3(void)
{
	CGLContextObj curr_ctx = CGLGetCurrentContext();
	CGLContextObj ctx;
	CGLPixelFormatObj pix;
	GLint npix;
	CGLPixelFormatAttribute attribs[] = {
			kCGLPFAAccelerated,
			(CGLPixelFormatAttribute) kCGLPFAOpenGLProfile, (CGLPixelFormatAttribute) kCGLOGLPVersion_3_2_Core,
			(CGLPixelFormatAttribute) 0
	};

	CGLChoosePixelFormat(attribs, &pix, &npix);
	if (pix)
	{
		CGLCreateContext(pix, NULL, &ctx);
		CGLDestroyPixelFormat(pix);
		CGLSetCurrentContext(ctx);
		if (ctx && glGetString(GL_VERSION))
		{
			NSString *versionFull = [NSString stringWithUTF8String:(const char *) glGetString(GL_VERSION)];
			NSString *versionOnlyString = [[versionFull componentsSeparatedByString:@" "] objectAtIndex:0];
			NSArray *version = [versionOnlyString componentsSeparatedByString:@"."];
			if ([[version objectAtIndex:0] intValue] >= 3)
			{
				globalInfo.modernOpenGL = TRUE;
			}
		}
		if (ctx)
			CGLDestroyContext(ctx);
	}
	CGLSetCurrentContext(curr_ctx);
}
#endif


int main(int argc, char *argv[])
{
//#ifdef WIN32
//    freopen( "CON", "w", stdout );
//#warning todo remove -mconsole
//#endif


#ifdef TARGET_OS_MAC
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    
    
	[APPLICATIONCLASS sharedApplication];

    PreCheckOpenGL();
//    if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_7)
//        PreCheckOpenGL3();
	if (!globalInfo.properOpenGL)
	{
		NSRunAlertPanel(@"Error", @"CoreBreach requires an OpenGL 2.1 compliant video card with support for EXT_framebuffer_object (Radeon HD 2400 / GeForce 7300 / HD Graphics 3000). Trying to play the game on your hardware may result in crashes or even freeze your Mac - continue at your own risk!", @"OK", nil, nil);
	}
    

	NSMutableArray *tmp = [NSMutableArray array];
	for(int i=1; i < argc; i++)
	{
		[tmp addObject:[NSString stringWithUTF8String:argv[i]]];
	}
    globalInfo.commandLineParameters = [[NSArray alloc] initWithArray:tmp];
	
	
    [NSBundle loadNibNamed:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSMainNibFile"] owner:NSApp];
    
	[pool release];
	[NSApp run];
#else
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];


	SDL_Init(SDL_INIT_VIDEO | SDL_INIT_JOYSTICK);


	SDL_SetVideoMode(4, 4, 0, SDL_NOFRAME | SDL_OPENGL);

	CheckOpenGLAndInitSuckyness();

	SDL_Quit();
//#warning revert

	NSMutableArray *tmp = [NSMutableArray array];
	for (int i = 1; i < argc; i++)
	{
		[tmp addObject:[NSString stringWithUTF8String:argv[i]]];
	}
	globalInfo.commandLineParameters = [[NSArray alloc] initWithArray:tmp];

	[pool release];


	return NSApplicationMain(argc, (const char **) argv);
#endif
}