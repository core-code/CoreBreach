//
//  proAlertView.h
//  Key Chain
//
//  Created by Jonah on 11-05-10.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


@interface proAlertView : UIAlertView
{
	
	int canIndex;
	BOOL disableDismiss;
    BOOL canVirate;
}

-(void) setBackgroundColor:(UIColor *) background 
			withStrokeColor:(UIColor *) stroke;

- (void)disableDismissForIndex:(int)index_;
- (void)dismissAlert;
- (void)vibrateAlert:(float)seconds;

- (void)moveRight;
- (void)moveLeft;

- (void)hideAfter:(float)seconds;

- (void)stopVibration;


@end
