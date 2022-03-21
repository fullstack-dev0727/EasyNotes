//
//  UIImage+OpenCVExtensions.m
//  TesseractOCRTestLib
//
//  Created by admin on 9/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UIImage+OpenCVExtensions.h"


@implementation UIImage (OpenCVExtensions)


- (UIImage *)grayScaleImage {
    // Create image rectangle with current image width/height
    CGRect imageRect = CGRectMake(0, 0, self.size.width * self.scale, self.size.height * self.scale);
    // Grayscale color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    // Create bitmap content with current image size and grayscale colorspace
    CGContextRef context = CGBitmapContextCreate(nil, self.size.width * self.scale, self.size.height * self.scale, 8, 0, colorSpace, kCGImageAlphaNone);
    // Draw image into current context, with specified rectangle
    // using previously defined context (with grayscale colorspace)
    CGContextDrawImage(context, imageRect, [self CGImage]);
    // Create bitmap image info from pixel data in current context
    CGImageRef grayImage = CGBitmapContextCreateImage(context);
    // release the colorspace and graphics context
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    // make a new alpha-only graphics context
    context = CGBitmapContextCreate(nil, self.size.width * self.scale, self.size.height * self.scale, 8, 0, nil, kCGImageAlphaOnly);
    // draw image into context with no colorspace
    CGContextDrawImage(context, imageRect, [self CGImage]);
    // create alpha bitmap mask from current context
    CGImageRef mask = CGBitmapContextCreateImage(context);
    // release graphics context
    CGContextRelease(context);
    // make UIImage from grayscale image with alpha mask
    UIImage *grayScaleImage = [UIImage imageWithCGImage:CGImageCreateWithMask(grayImage, mask) scale:self.scale orientation:self.imageOrientation];
    // release the CG images
    CGImageRelease(grayImage);
    CGImageRelease(mask);
    // return the new grayscale image
    return grayScaleImage;
}





+(UIImage *) GetImageFromPix:(Pix *)thePix
{
    CGColorSpaceRef colorSpace;
    uint32_t *bitmapData;
    
    size_t bitsPerComponent = thePix->d;
    
    size_t width = thePix->w;
    size_t height = thePix->h;
    
    size_t bytesPerRow = thePix->wpl * 4;
    
    colorSpace = CGColorSpaceCreateDeviceGray();
    
    if(!colorSpace) {
        NSLog(@"Error allocating color space Gray\n");
        return NULL;
    }
    
    // Allocate memory for image data
    bitmapData = thePix->data;
    
    if(!bitmapData) {
        NSLog(@"Error allocating memory for bitmap\n");
        CGColorSpaceRelease(colorSpace);
        return NULL;
    }
    
    //Create bitmap context
    
    CGContextRef context = CGBitmapContextCreate(bitmapData, 
                                                 width, 
                                                 height, 
                                                 bitsPerComponent, 
                                                 bytesPerRow, 
                                                 colorSpace, 
                                                 kCGImageAlphaNone); 
    if(!context) {
        free(bitmapData);
        NSLog(@"Bitmap context not created");
    }
    
    CGColorSpaceRelease(colorSpace);
    
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    UIImage * result = [UIImage imageWithCGImage:imgRef];
    CGImageRelease(imgRef);
    CGContextRelease(context);
    
    return result;
}


- (CGAffineTransform)transformForOrientationDrawnTransposed:(BOOL *)drawTransposed
{
    UIImageOrientation imageOrientation = [self imageOrientation];
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGSize size = [self size];  // already transposed by UIImage
    
    switch (imageOrientation) {
        case UIImageOrientationDown:           // EXIF orientation 3
        case UIImageOrientationDownMirrored:   // EXIF orientation 4
            transform = CGAffineTransformTranslate(transform, size.width, size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:           // EXIF orientation 6
        case UIImageOrientationLeftMirrored:   // EXIF orientation 5
            transform = CGAffineTransformTranslate(transform, size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:          // EXIF orientation 8
        case UIImageOrientationRightMirrored:  // EXIF orientation 7
            transform = CGAffineTransformTranslate(transform, 0, size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (imageOrientation) {
        case UIImageOrientationUpMirrored:     // EXIF orientation 2
        case UIImageOrientationDownMirrored:   // EXIF orientation 4
            transform = CGAffineTransformTranslate(transform, size.width, 0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationLeftMirrored:   // EXIF orientation 5
        case UIImageOrientationRightMirrored:  // EXIF orientation 7
            transform = CGAffineTransformTranslate(transform, size.height, 0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
        default:
            break;
    }
    
    if (drawTransposed) {
        switch (imageOrientation) {
            case UIImageOrientationLeft:
            case UIImageOrientationLeftMirrored:
            case UIImageOrientationRight:
            case UIImageOrientationRightMirrored:
                *drawTransposed = YES;
                break;
                
            default:
                *drawTransposed = NO;
        }
    }
    
    return transform;
}

- (UIImage *)fixOrientation {
    
    // No-op if the orientation is already correct
    if (self.imageOrientation == UIImageOrientationUp) return self;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (self.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, self.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, self.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (self.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, self.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, self.size.width, self.size.height,
                                             CGImageGetBitsPerComponent(self.CGImage), 0,
                                             CGImageGetColorSpace(self.CGImage),
                                             CGImageGetBitmapInfo(self.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (self.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.height,self.size.width), self.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,self.size.width,self.size.height), self.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}


@end
