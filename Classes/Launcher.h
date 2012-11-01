//
//  Launcher.h
//  Core3D
//
//  Created by CoreCode on 19.05.08.
//  Copyright 2008 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//



#ifdef TARGET_OS_MAC
    #import "AppController.h"
    #import <WebKit/WebKit.h>
    #import <QTKit/QTMovie.h>
    #import <QTKit/QTMovieView.h>
#endif

#import "CoreBreach.h"
#import "UpgradeHandler.h"


@interface PercentageIndicator : NSProgressIndicator
{}

- (void)startAnimation:(id)sender;
- (void)stopAnimation:(id)sender;
- (void)animate:(id)sender;
@end

@interface Launcher : NSObject
#ifdef TARGET_OS_MAC
    <NSTableViewDataSource>
#endif
{
	BOOL new_racetrack_hidden;
	BOOL new_spaceship_hidden;
	BOOL new_spaceship2_hidden;

	IBOutlet NSPopUpButton *difficultyCareer;
	IBOutlet NSPopUpButton *difficultyCustom;
	IBOutlet NSPopUpButton *difficultyMultiplayer;
	IBOutlet NSPopUpButton *roundsCustom;
	IBOutlet NSPopUpButton *roundsMultiplayer;
	IBOutlet NSPopUpButton *enemiesCustom;
	IBOutlet NSPopUpButton *enemiesMultiplayer;

	uint8_t savedDifficulty;
	BOOL loaded;
	shipAttributeEnum currentUpgradeMode;

	IBOutlet NSTextField *resolutionLabel;

	IBOutlet NSTextField *cashLabel;


	IBOutlet NSPopUpButton *player1InputDevicePopup;
	IBOutlet NSPopUpButton *player2InputDevicePopup;

	IBOutlet NSPopUpButton *shipPopupCareer;
	IBOutlet NSPopUpButton *shipPopupCustom;
	IBOutlet NSPopUpButton *shipPopupTimeAttack;
	IBOutlet NSPopUpButton *shipPopupMultiplayer1;
	IBOutlet NSPopUpButton *shipPopupMultiplayer2;

	IBOutlet NSPopUpButton *trackPopupCareer;
	IBOutlet NSPopUpButton *trackPopupCustom;
	IBOutlet NSPopUpButton *trackPopupTimeAttack;
	IBOutlet NSPopUpButton *trackPopupMultiplayer;

	IBOutlet NSProgressIndicator *trackLen;
	IBOutlet NSProgressIndicator *trackSpe;
	IBOutlet NSProgressIndicator *trackDif;

	IBOutlet NSProgressIndicator *trackCustomLen;
	IBOutlet NSProgressIndicator *trackCustomSpe;
	IBOutlet NSProgressIndicator *trackCustomDif;

	IBOutlet NSProgressIndicator *trackTimeattackLen;
	IBOutlet NSProgressIndicator *trackTimeattackSpe;
	IBOutlet NSProgressIndicator *trackTimeattackDif;

	IBOutlet NSProgressIndicator *trackMultiplayerLen;
	IBOutlet NSProgressIndicator *trackMultiplayerSpe;
	IBOutlet NSProgressIndicator *trackMultiplayerDif;


	IBOutlet NSBox *cashBox;
#ifdef TARGET_OS_MAC
	IBOutlet WebView			 *addThisWebview;
#endif

	IBOutlet PercentageIndicator *upgradeSheetCurrentIndicator;
	IBOutlet NSBox *upgradeSheetBox;

	IBOutlet NSProgressIndicator *shipTop;
	IBOutlet NSProgressIndicator *shipAcc;
	IBOutlet NSProgressIndicator *shipHan;

	IBOutlet NSProgressIndicator *shipCustomTop;
	IBOutlet NSProgressIndicator *shipCustomAcc;
	IBOutlet NSProgressIndicator *shipCustomHan;

	IBOutlet NSProgressIndicator *shipTimeattackTop;
	IBOutlet NSProgressIndicator *shipTimeattackAcc;
	IBOutlet NSProgressIndicator *shipTimeattackHan;

	IBOutlet NSProgressIndicator *shipMultiplayerTop;
	IBOutlet NSProgressIndicator *shipMultiplayerAcc;
	IBOutlet NSProgressIndicator *shipMultiplayerHan;

	IBOutlet NSProgressIndicator *shipMultiplayer2Top;
	IBOutlet NSProgressIndicator *shipMultiplayer2Acc;
	IBOutlet NSProgressIndicator *shipMultiplayer2Han;

#ifdef __APPLE__
	IBOutlet QTMovieView *shipMovie;
	IBOutlet QTMovieView *trackMovie;
	IBOutlet QTMovieView *shipCustomMovie;
	IBOutlet QTMovieView *trackCustomMovie;
	IBOutlet QTMovieView *shipTimeattackMovie;
	IBOutlet QTMovieView *trackTimeattackMovie;
	IBOutlet QTMovieView *shipMultiplayerMovie;
	IBOutlet QTMovieView *shipMultiplayer2Movie;
	IBOutlet QTMovieView *trackMultiplayerMovie;
#else
	IBOutlet NSImageView *shipImage;
    IBOutlet NSImageView *trackImage;
    IBOutlet NSImageView *shipCustomImage;
    IBOutlet NSImageView *trackCustomImage;
	IBOutlet NSImageView *shipTimeattackImage;
    IBOutlet NSImageView *trackTimeattackImage;
	IBOutlet NSImageView *shipMultiplayerImage;
	IBOutlet NSImageView *shipMultiplayer2Image;
    IBOutlet NSImageView *trackMultiplayerImage;
#endif


	IBOutlet NSButton *additionalTracksButton;


#ifndef __APPLE__
	IBOutlet NSPopUpButton *resolutionPopup;
    IBOutlet NSTabView *bigTabView;
#endif

#ifdef GNUSTEP
    IBOutlet NSTextField *shipUpgradeNoMoneyText;
    IBOutlet NSTextField *weaponUpgradeNoMoneyText;
#endif

	IBOutlet NSTableView *customInternetHighscoresTable;
	IBOutlet NSTableView *customLocalHighscoresTable;
	IBOutlet NSTableView *timeattackInternetHighscoresTable;
	IBOutlet NSTableView *timeattackLocalHighscoresTable;
	IBOutlet NSTableView *careerInternetHighscoresTable;
	IBOutlet NSTableView *careerLocalHighscoresTable;

	IBOutlet NSTableView *songListTable;

	IBOutlet NSButton *upgradeWeaponsButton;
	IBOutlet NSButton *upgradeHandlingButton;
	IBOutlet NSButton *upgradeTopSpeedButton;
	IBOutlet NSButton *upgradeAccelerationButton;

	IBOutlet NSTableView *objectivesTable;

	IBOutlet NSBox *player1Box;
	IBOutlet NSBox *player2Box;

	IBOutlet NSWindow *window;

	IBOutlet NSWindow *upgradeWeaponSheet;
	IBOutlet NSWindow *upgradeSheet;
	IBOutlet NSWindow *configureControlsSheet;
	IBOutlet NSWindow *configureAudioSheet;
	IBOutlet NSWindow *configureVideoSheet;
	IBOutlet NSWindow *configureGameSheet;
	IBOutlet NSWindow *highscoresSheet;

	IBOutlet NSBox *newsBox;

	IBOutlet NSButton *upgradeBombButton;
	IBOutlet NSButton *upgradeMinesButton;
	IBOutlet NSButton *upgradeWaveButton;
	IBOutlet NSButton *upgradeNitroButton;
	IBOutlet NSButton *upgradeDamageButton;

	IBOutlet NSImageView *bannerImage;
	NSArray *customHighscores;
	NSArray *timeattackHighscores;
	NSArray *carreerHighscores;

	IBOutlet NSView *contentView;
	BOOL launching;
	NSButton *upgradeHandlingAction;

	NSDate *controlWorkaroundDate;

#ifdef TARGET_OS_MAC
    IBOutlet AppController *appController;
#endif
}

- (void)updateTrackMenus:(NSNotification *)notification;
- (void)disableLockedMenuItems;

- (IBAction)careerDifficultyChanged:(id)sender;
- (IBAction)closeNewsButtonAction:(id)sender;
- (IBAction)configureHIDControl:(id)sender;
- (IBAction)songStateChanged:(id)sender;
- (IBAction)configureControlsHelpAction:(id)sender;
- (IBAction)configureControlsAction:(id)sender;
- (IBAction)configureAudioAction:(id)sender;
- (IBAction)configureVideoAction:(id)sender;
- (IBAction)configureGameAction:(id)sender;
- (IBAction)upgradeWeaponsAction:(id)sender;
- (IBAction)upgradeHandlingAction:(id)sender;
- (IBAction)upgradeTopSpeedAction:(id)sender;
- (IBAction)upgradeAccelerationAction:(id)sender;
- (IBAction)upgradeFinishedAction:(id)sender;
- (IBAction)buyUpgradeAction:(id)sender;
- (IBAction)upgradeWeaponsFinishedAction:(id)sender;
- (IBAction)upgradeWeaponAction:(id)sender;
- (void)updateWeaponsSheet;
#ifndef __APPLE__
- (IBAction)clickableImageClicked:(id)sender;
#endif
- (IBAction)sendFeedback:(id)sender;
- (IBAction)visitHomepage:(id)sender;
- (IBAction)openVersionHistory:(id)sender;
- (IBAction)additionalTracks:(id)sender;
- (IBAction)gameManual:(id)sender;

- (IBAction)carreerHighscoresAction:(id)sender;
- (IBAction)configureControlsFinishedAction:(id)sender;
- (IBAction)configureAudioFinishedAction:(id)sender;
- (IBAction)configureVideoFinishedAction:(id)sender;
- (IBAction)configureGameFinishedAction:(id)sender;

- (IBAction)carreerHighscoresFinishedAction:(id)sender;

- (IBAction)fullscreenResolutionAction:(id)sender;
#ifdef SDL
- (IBAction)configureControlsDevivePopupChangedAction:(id)sender;
#endif

- (IBAction)playAction:(id)sender;

- (IBAction)trackMultiplayerAction:(id)sender;
- (IBAction)shipMultiplayerAction:(id)sender;
- (IBAction)shipMultiplayer2Action:(id)sender;
- (IBAction)shipAction:(id)sender;
- (IBAction)trackAction:(id)sender;
- (IBAction)shipTimeattackAction:(id)sender;
- (IBAction)trackTimeattackAction:(id)sender;
- (IBAction)shipCustomAction:(id)sender;
- (IBAction)trackCustomAction:(id)sender;

@property (copy) NSArray *customHighscores;
@property (copy) NSArray *timeattackHighscores;
@property (copy) NSArray *carreerHighscores;

@property (assign, nonatomic) BOOL new_racetrack_hidden;
@property (assign, nonatomic) BOOL new_spaceship_hidden;
@property (assign, nonatomic) BOOL new_spaceship2_hidden;

@end

