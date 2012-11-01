CoreBreach v1.1.5

INTRODUCTION:
CoreBreach is THE brand-new futuristic "anti-gravity" racing game with combat-based gameplay.
To launch the game double-click "CoreBreach.sh".
The game manual is available in the main menu of CoreBreach, click on the button labeled "Game Manual".


DEPENDENCIES:
CoreBreach requires the installation of (at least) the following packages to run:
* SDL (libsdl1.2)
* SDL_mixer (libsdl-mixer1.2)
* OpenAL (libopenal1)
* OpenGL (libgl1)
* Cairo (libcairo2)
* GTK+ (libgtk2.0-0)
* libXt (libxt6)
* zlib (zlib1g)


SYSTEM REQUIREMENTS:
* 32 or 64 bit Intel-compatible processor (i386 / x86_64)
* Linux 2.6.32 or later with glibc 2.11.1 or later
* 1GB available disk space
* 512MB RAM
* 1024x768 or higher screen resolution
* Up-to-date proprietary OpenGL drivers from ATI or NVIDIA
* Video card with at least 256MB video memory and support for OpenGL 2.1:
	* ATI Radeon HD 2400 or higher
	* NVIDIA GeForce 7300 or higher ("Optimus" not supported)


KNOWN LINUX PROBLEMS:
* CoreBreach may run very slowly or display garbage using old OpenGL drivers. Please update to the latest proprietary binary drivers provided directly from ATI or nVIDIA (especially if you don't see the racetrack).
* CoreBreach is not compatible with 3rd party projects for using NVIDIA Optimus under Linux (Bumblebee and Ironhide), the game will crash if you try to run it with "optirun". This is a bug in "VirtualGL" (SourceForge bug #3459360).
* There are numerous problems when using the (unsupported) MESA ATI driver. Setting the "Lighting" to "Static" in the video-preferences, CoreBreach may trigger a driver bug on open-source MESA ATI drivers resulting in the racetrack being black (FreeDesktop bug #43520). Additionally the high quality shadows don't appear and FSAA doesn't work.
* When running the game on a INTEL graphics card (which is unsupported) there may be many graphical problems (FreeDesktop bugs #43580, #43581, #43582).
* The Linux technology "Compiz" may severely impact any 3D OpenGL application, including CoreBreach. More specifically, using "Compiz" makes CoreBreach display garbage during startup, display very ugly (FSAA disabled regardless of the preferences) and perform slowly on ATI systems (Compiz bug #1335 & #1364). Turn off "Compiz" before running CoreBreach, e.g. using "Compiz-Switch" or "Fusion-Icon".
* CoreBreach may trigger a problem in "PulseAudio", causing the game to crash - this may occur with PulseAudio 0.9.22 (FreeDesktop bug #43351). If you have more information or know how to reproduce the problem please let us know.
* Some functions of the main user-interface like viewing the manual, opening the website or version history depend on installation of: internet browser, e-mail client, PDF viewer and RTF-compatible word processor.
* The menu in in the main window may disappear after the first game.

HINTS:
* Press F9 to make a screenshot into your home-directory.