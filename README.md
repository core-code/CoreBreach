CoreBreach
==========

CoreBreach is THE brand-new futuristic "anti-gravity" racing game with combat-based gameplay.


1. Checkout Core3D next to Core3D-Example

		git clone https://github.com/core-code/Core3D.git
	
		git clone https://github.com/core-code/CoreBreach.git

2. 
	* Mac: Open CoreBreach.xcodeproj in Xcode 4.x and hit the build button
	* Win: Buy a Mac, [install clang-compatible Cocotron](http://code.google.com/r/glennganz-cocotron1-clang/) and then open CoreBreach.xcodeproj in Xcode 4.x, select the win32 target and hit the build button.
	* Lin:
		1. Install [clang 3.0](http://clang.llvm.org) or newer either from your system package management (if recent enough) or from source.
		2. Install *from source* recent versions from [GNUstep](http://www.gnustep.org/) (base >= 1.24.0, gui 0.22) and libobjc2 (version >= 1.5.0). The reason to install these from source is that linux distributions either don't have these packages (libobjc2) or don't have recent enough versions (GNUstep). Beware, what debian/ubuntu calls libobjc2 in their package system actually is not libobjc2 at all, you need the REAL libobjc2 from [here](http://download.gna.org/gnustep/).  At this point you should verify that you are able to build gnustep projects and your system compiler defaults to clang.
		3. Install the development versions of OpenGL, OpenAL, SDL, SDL_mixer & freetype using your native package management	
		4. Then compile & run like any other GNUstep project using the GNUmakefile, i.e.:

				cd CoreBreach; make	; openapp ./CoreBreach.app
				
			If the last step fails you probably need to specify the library path (replace 32 with 64 on 64-bit systems):
				
				export LD_LIBRARY_PATH=/path/to/CoreBreach/_DEPENDENCIES/libs-linux32/:$LD_LIBRARY_PATH
		
	* BSD:
		Building the project on BSD or other Unix systems should be similar to Linux with the exception that you need to provide some missing libraries that are provided pre-built on Linux: 
		* Engine-dependencies: Core3D/_DEPENDENCIES/libs-linux*/:
			* Bullet: you should compile the version provided in Core3D/_DEPENDENCIES/sources/bullet/ using gcc 
	
			* Alut: install using system package management
		* CoreBreach-dependencies: CoreBreach/_DEPENDENCIES/libs-linux*/:
			* libavcodec 0.8.x: install using system package management
			* libffplay: install from [here](https://github.com/core-code/ffplaylib)
		

