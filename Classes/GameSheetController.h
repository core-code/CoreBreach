//
//  GameSheetController.h
//  CoreBreach
//
//  Created by CoreCode on 07.11.10.
//  Copyright 2010 - 2012 CoreCode. Licensed under the GPL License, see LICENSE.txt
//

#ifdef SDL
#import "SDLRenderViewController.h"
#else
#import "MacRenderViewController.h"


#endif

#ifdef __APPLE__
#import <QTKit/QTMedia.h>

#import <QTKit/QTMovie.h>
#import <QTKit/QTMovieView.h>


#endif

@interface GameSheetController : NSObject
{
	IBOutlet NSButton *viewScoreButton;

	IBOutlet RenderViewController *renderViewController;
	IBOutlet NSWindow *pauseSheet;
	IBOutlet NSWindow *finishSheet;

	IBOutlet NSTextField *finishResultText, *multiplayerP1ResultText, *multiplayerP2ResultText;
	IBOutlet NSTextField *carrerHighscoreResult, *customHighscoreResult, *timeattackHighscoreResult;

	IBOutlet NSBox *careerBox;
	IBOutlet NSBox *customBox;
	IBOutlet NSBox *timeattackBox;
	IBOutlet NSBox *multiplayerBox;
	IBOutlet NSButton *skipMovieButton;
	IBOutlet NSImageView *player1Image;
	IBOutlet NSImageView *player2Image;

	IBOutlet NSTableView *objectivesCareerTable;
	IBOutlet NSTableView *objectivesMultiplayer1Table;
	IBOutlet NSTableView *objectivesMultiplayer2Table;
	IBOutlet NSTableView *objectivesCustomTable;

	IBOutlet NSImageView *finishBanner;
	IBOutlet NSTableView *awardsCareerTable;
	IBOutlet NSTableView *statusCareerTable;

	IBOutlet NSTableView *laptimesTimeattackTable;
	IBOutlet NSTableView *laptimesCustomTable;
	IBOutlet NSTableView *laptimesMultiplayer1Table;
	IBOutlet NSTableView *laptimesMultiplayer2Table;


	IBOutlet NSTableView *highscoresCareerTable;
	IBOutlet NSTableView *highscoresCustomTable;
	IBOutlet NSTableView *highscoresTimeattackTable;
#ifdef __APPLE__
	IBOutlet QTMovieView *storyMovieView;
#endif
	NSArray *laptimes, *laptimes2, *awards, *awards2;
	NSArray *reallaptimes;
	NSArray *newhighscoreindices;
	NSArray *highscores;

	NSDictionary *result, *result2, *settings;

	IBOutlet NSButton *tryAgainButton;
	IBOutlet NSTextField *withNewShipTextField;
	int bestnewplace;
}

+ (GameSheetController *)sharedController;
- (BOOL)isVideoNeccessary;
- (void)fetchResults;
#ifndef SDL
- (void)presentPauseSheet;
- (IBAction)movieDidEnd:(id)bla;
- (IBAction)quitAction:(id)sender;
- (IBAction)continueAction:(id)sender;
#else
- (IBAction)quitAction:(id)sender
#ifdef __clang__
	__attribute__((__noreturn__));
#else
;
#endif
#endif
- (IBAction)viewScoreAction:(id)sender;
- (IBAction)quitFromScoresAction:(id)sender;
- (IBAction)mainmenuAction:(id)sender;
- (IBAction)retryAction:(id)sender;
- (void)showResults;

@property (copy) NSArray *highscores;

@end
