//
//  UIImage+Category.m
//  ImageOverlay
//
//  Created by Georg Tremmel on 29/04/2010.
//

#import "UIImage+Category.h"

@implementation UIImage (combine)


- (UIImage*)overlayWith:(UIImage*)overlayImage {
	
	// size is taken from the background image
	UIGraphicsBeginImageContext(self.size);
	
	[self drawAtPoint:CGPointZero];
	[overlayImage drawAtPoint:CGPointZero];
	
	/*
	// If Image Artefacts appear, replace the "overlayImage drawAtPoint" , method with the following
	// Yes, it's a workaround, yes I filed a bug report
	CGRect imageRect = CGRectMake(0, 0, self.size.width, self.size.height);
	[overlayImage drawInRect:imageRect blendMode:kCGBlendModeOverlay alpha:0.999999999];
	*/
	
	UIImage *combinedImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return combinedImage;
}

@end
