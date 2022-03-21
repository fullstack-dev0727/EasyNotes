//
//  UIImage+OpenCVExtensions.h
//  TesseractOCRTestLib
//
//  Created by admin on 9/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "allheaders.h"
#import "environ.h"
#import "pix.h"
@interface UIImage (OpenCVExtensions)
+(UIImage *) GetImageFromPix:(Pix *)thePix;
- (UIImage *)fixOrientation;
- (UIImage *)grayScaleImage ;

@end
