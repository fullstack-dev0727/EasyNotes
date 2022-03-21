//
//  ViewController.m
//  EasyNotes
//
//  Created by Petar Vasilev on 5/31/15.
//  Copyright (c) 2015 Petar Vasilev. All rights reserved.
//

#import "TakePictureViewController.h"
#import "MBProgressHUD.h"
#import "TextEditorViewController.h"
#include "baseapi.h"
#import "SettingViewController.h"
#include "environ.h"
#import "pix.h"
#import "SaveViewController.h"
#import "UIImage+Util.h"
#import "AppDelegate.h"

@interface TakePictureViewController ()

@end

@implementation TakePictureViewController
@synthesize progressHud;
@synthesize viewLayer;
@synthesize pictureImageView;
typedef enum {
    ALPHA = 0,
    BLUE = 1,
    GREEN = 2,
    RED = 3
} PIXELS;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (void) viewWillAppear:(BOOL)animated {
   // [pictureImageView setImage:[UIImage imageNamed:@"sample4.jpg"]];
    viewLayer.layer.borderColor = [UIColor whiteColor].CGColor;
    viewLayer.layer.borderWidth = 1.0;

}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self initTessdata];
    [pictureImageView setHidden:YES];
    [self initializeCamera];
    
}
- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    delete tesseract;
    tesseract = nil;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) initTessdata {
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = ([documentPaths count] > 0) ? [documentPaths objectAtIndex:0] : nil;
    
    NSString *dataPath = [documentPath stringByAppendingPathComponent:@"tessdata"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // If the expected store doesn't exist, copy the default store.
    if (![fileManager fileExistsAtPath:dataPath]) {
        // get the path to the app bundle (with the tessdata dir)
        NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
        NSString *tessdataPath = [bundlePath stringByAppendingPathComponent:@"tessdata"];
        if (tessdataPath) {
            [fileManager copyItemAtPath:tessdataPath toPath:dataPath error:NULL];
        }
    }
    
    setenv("TESSDATA_PREFIX", [[documentPath stringByAppendingString:@"/"] UTF8String], 1);
    
    // init the tesseract engine.
    tesseract = new tesseract::TessBaseAPI();
    tesseract->Init([dataPath cStringUsingEncoding:NSUTF8StringEncoding], "eng");
}

- (void)setTesseractImage:(UIImage *)image
{
    free(pixels);
    
    CGSize size = [image size];
    int width = size.width;
    int height = size.height;
    
    if (width <= 0 || height <= 0)
        return;
    
    // the pixels will be painted to this array
    pixels = (uint32_t *) malloc(width * height * sizeof(uint32_t));
    memset(pixels, 0, width * height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // create a context with RGBA pixels
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    
    // paint the bitmap to our context which will fill in the pixels array
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
    
    // we're done with the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    tesseract->SetImage((const unsigned char *) pixels, width, height, sizeof(uint32_t), width * sizeof(uint32_t));
}

- (int) getMaxColor:(uint8_t*) rgbaPixel {
    return MAX(MAX(rgbaPixel[RED], rgbaPixel[GREEN]),rgbaPixel[BLUE]);
}
- (int) getMinColor:(uint8_t*) rgbaPixel {
    return MIN(MIN(rgbaPixel[RED], rgbaPixel[GREEN]),rgbaPixel[BLUE]);
}
- (UIImage *)convertToGrayscale:(UIImage *)i {
    CGSize size = [i size];
    int width = size.width;
    int height = size.height;
    
    // the pixels will be painted to this array
    uint32_t *rgbcolor = (uint32_t *) malloc(width * height * sizeof(uint32_t));
    
    // clear the pixels so any transparency is preserved
    memset(rgbcolor, 0, width * height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // create a context with RGBA pixels
    CGContextRef context = CGBitmapContextCreate(rgbcolor, width, height, 8, width * sizeof(uint32_t), colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    
    // paint the bitmap to our context which will fill in the pixels array
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [i CGImage]);
    
    for(int y = 0; y < height; y++) {
        for(int x = 0; x < width; x++) {
            uint8_t *rgbaPixel = (uint8_t *) &rgbcolor[y * width + x];
            
            // convert to grayscale using recommended method: http://en.wikipedia.org/wiki/Grayscale#Converting_color_to_grayscale
            uint32_t gray = 0.3 * rgbaPixel[RED] + 0.59 * rgbaPixel[GREEN] + 0.11 * rgbaPixel[BLUE];
            
            // set the pixels to gray
            rgbaPixel[RED] = gray;
            rgbaPixel[GREEN] = gray;
            rgbaPixel[BLUE] = gray;
        }
    }
    
    // create a new CGImageRef from our context with the modified pixels
    CGImageRef image = CGBitmapContextCreateImage(context);
    
    // we're done with the context, color space, and pixels
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(rgbcolor);
    
    // make a new UIImage to return
    UIImage *resultUIImage = [UIImage imageWithCGImage:image];
    
    // we're done with image now too
    CGImageRelease(image);
    
    return resultUIImage;
}
-(UIImage *) getImageWithUnsaturatedPixelsOfImage:(UIImage *)image {
    
    CGRect imageRect = CGRectMake(0, 0, image.size.width * 2, image.size.height * 2);
    
    int width = imageRect.size.width, height = imageRect.size.height;
    
    uint32_t * filterPixels = (uint32_t *) malloc(width*height*sizeof(uint32_t));
    memset(filterPixels, 0, width * height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(filterPixels, width, height, 8, width * sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
    
    float average = 0.0f;
    for(int y = 0; y < height; y++) {
        for(int x = 0; x < width; x++) {
            uint8_t * rgbaPixel = (uint8_t *) &filterPixels[y*width+x];
            float brightness = rgbaPixel[RED] / 255.0f;
            average += brightness;
        }
    }
    average = average / (width * height);
    for(int y = 0; y < height; y++) {
        for(int x = 0; x < width; x++) {
            uint8_t * rgbaPixel = (uint8_t *) &filterPixels[y*width+x];
            float rcolor = rgbaPixel[RED] / 255.0f;
            if (rcolor > average - 0.1f) {
                rgbaPixel[RED] = 255;
                rgbaPixel[GREEN] = 255;
                rgbaPixel[BLUE] = 255;
            } else if (rcolor < average - 0.3f) {
                rgbaPixel[RED] = 0;
                rgbaPixel[GREEN] = 0;
                rgbaPixel[BLUE] = 0;
            }
           
        }
    }
    
    CGImageRef newImage = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(filterPixels);
    
    UIImage * resultUIImage = [UIImage imageWithCGImage:newImage scale:2 orientation:0];
    CGImageRelease(newImage);
    
    return resultUIImage;
}
- (BOOL) isHightlightPoint:(uint8_t *) rgbaPixel {
    float rcolor = rgbaPixel[RED];
    float gcolor = rgbaPixel[GREEN];
    float bcolor = rgbaPixel[BLUE];
    float maxVal = MAX(MAX(rcolor, gcolor), bcolor);
    float minVal = MIN(MIN(rcolor, gcolor), bcolor);
    if ((maxVal - minVal) > 100 && [self getCount:rgbaPixel] > 1) {
        return YES;
    }
    return NO;
}
- (int) getCount:(uint8_t *) rgbaPixel {
    int count = 0;
    if (rgbaPixel[RED] > 200)
        count++;
    if (rgbaPixel[GREEN] > 200)
        count++;
    if (rgbaPixel[BLUE] > 200)
        count++;
    return count;
}
-(void) getImageWithUnsaturatedPixelsOfEntire:(UIImage *)image {
    
    CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    int width = imageRect.size.width, height = imageRect.size.height;
    
    uint32_t * filterPixels = (uint32_t *) malloc(width*height*sizeof(uint32_t));
    memset(filterPixels, 0, width * height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(filterPixels, width, height, 8, width * sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
    
    NSMutableArray *yArray = [NSMutableArray array];
    BOOL isHighlightedLine = NO;
    for(int y = 0; y < height; y++) {
        isHighlightedLine = NO;
        for(int x = 0; x < width; x++) {
            uint8_t * rgbaPixel = (uint8_t *) &filterPixels[y*width+x];
            if ([self isHightlightPoint:rgbaPixel]) {
                isHighlightedLine = YES;
                [yArray addObject:[NSNumber numberWithInteger:y]];
                continue;
            }
        }
    }
    if ([yArray count] == 0)
        return;
    int delta = 30;
    int startHighLightY = [[yArray objectAtIndex:0] intValue];
    _croppedImageArray = [[NSMutableArray alloc] init];
    
    for (int i = 1; i < yArray.count; i++) {
        if (i == yArray.count - 1) {
            CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, startHighLightY - 10, width, [[yArray objectAtIndex:i] intValue] - startHighLightY + 20));
            UIImage* paragraph = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
            if (paragraph != nil)
                [_croppedImageArray addObject:paragraph];
        } else if ([[yArray objectAtIndex:(i + 1)] intValue] - [[yArray objectAtIndex:i] intValue] > 2 * delta ) {
            CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, startHighLightY - 10, width, [[yArray objectAtIndex:i] intValue] - startHighLightY + 20));
            UIImage* paragraph = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
            if (paragraph != nil)
                [_croppedImageArray addObject:paragraph];
            startHighLightY = [[yArray objectAtIndex:(i + 1)] intValue];
        }
    }
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(filterPixels);
}

- (void)processOcrAt:(UIImage *)sampleImage {
//    sampleImage = [UIImage imageNamed:@"sample4.jpg"];
    sampleImage = [sampleImage fixOrientation];
    [self getImageWithUnsaturatedPixelsOfEntire: sampleImage];
//    [pictureImageView setImage:sampleImage];
//    [pictureImageView setImage:[_croppedImageArray objectAtIndex:0]];
    [self recognizeFunc:[_croppedImageArray objectAtIndex:recogCount]];
}
- (void) recognizeFunc:(UIImage*) croppedImage {
    if (croppedImage == nil) {
        [self showErrorMessage];
        return;
    }
    UIImage* grayImage = [self convertToGrayscale: croppedImage];
    if (croppedImage == nil) {
        [self showErrorMessage];
        return;
    }
    UIImage* filteredImage = [self getImageWithUnsaturatedPixelsOfImage: grayImage];
    if (filteredImage == nil) {
        [self showErrorMessage];
        return;
    }
    [self setTesseractImage:filteredImage];
    
    tesseract->Recognize(NULL);
    char* utf8Text = tesseract->GetUTF8Text();
    if (utf8Text == nil) {
        [self showErrorMessage];
        return;
    }
        
    [self performSelectorOnMainThread:@selector(ocrProcessingFinished:)
                           withObject:[NSString stringWithUTF8String:utf8Text]
                        waitUntilDone:NO];
}
- (void) showErrorMessage {
    [[[UIAlertView alloc] initWithTitle:@"EasyNotes"
                                message:@"It seems not to have highlighted texts. Please try to do again."
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles:@"OK", nil] show];
    [pictureImageView setHidden:YES];
    [self initializeCamera];
}
- (void)ocrProcessingFinished:(NSString *)result
{
    if ([recognizedText length] == 0)
        recognizedText = result;
    else if (result != nil)
        recognizedText = [NSString stringWithFormat:@"%@&#&%@", recognizedText, result];
    if (recogCount < [_croppedImageArray count] - 1) {
        [self recognizeFunc:[_croppedImageArray objectAtIndex:++recogCount]];
    } else {
        recognizedText = [recognizedText stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        recognizedText = [recognizedText stringByReplacingOccurrencesOfString:@"&#&" withString:@"\n\n"];
        [self.progressHud removeFromSuperview];
        [self performSegueWithIdentifier:@"addmore" sender:self];
    }

//    [[[UIAlertView alloc] initWithTitle:@"Tesseract Sample"
//                                message:[NSString stringWithFormat:@"Recognized:\n%@", result]
//                               delegate:nil
//                      cancelButtonTitle:nil
//                      otherButtonTitles:@"OK", nil] show];
}

- (IBAction)onClickSetting:(id)sender {
    [self performSegueWithIdentifier:@"setting" sender:self];
}

- (IBAction)onClickScan:(id)sender {

    recogCount = 0;
    recognizedText = @"";
    [self capImage];
    
//    _capturedImage = [UIImage imageNamed:@"sample4.jpg"];
//    [pictureImageView setImage:_capturedImage];
//    [pictureImageView setHidden:NO];
//    
//    if (_capturedImage != nil) {
//        self.progressHud = [[MBProgressHUD alloc] initWithView:self.view];
//        self.progressHud.labelText = @"Please wait...";
//        [self.view addSubview:self.progressHud];
//        //UIImage* stretchedImage = [self imageWithImage:_capturedImage scaledToSize:CGSizeMake(_capturedImage.size.width, _capturedImage.size.height)];
//        [self.progressHud showWhileExecuting:@selector(processOcrAt:) onTarget:self withObject:_capturedImage animated:YES];
//    }
}

- (IBAction)onClickOCR:(id)sender {
    [self performSegueWithIdentifier:@"fileselect" sender:self];
    
}
- (void) flashlight
{
    AVCaptureDevice *flashLight = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([flashLight isTorchAvailable] && [flashLight isTorchModeSupported:AVCaptureTorchModeOn])
    {
        BOOL success = [flashLight lockForConfiguration:nil];
        if (success)
        {
            if ([flashLight isTorchActive]) {
                [flashLight setTorchMode:AVCaptureTorchModeOff];
            } else {
                [flashLight setTorchMode:AVCaptureTorchModeOn];
            }
            [flashLight unlockForConfiguration];
        }
    }
}
- (IBAction)onClickFlash:(id)sender {
    [self flashlight];
}
- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     if ([segue.identifier isEqualToString:@"addmore"]) {
         AppDelegate* appDelegate = APPDELEGATE;
         if ([appDelegate isPaidVersion]) {
             appDelegate.recognizedText = [NSString stringWithFormat:@"%@\n%@", appDelegate.recognizedText, recognizedText];
         } else {
             appDelegate.recognizedText = recognizedText;
         }

     }
}

#pragma mark initilize camera method
- (void) initializeCamera
{
    if (session_cam)
        session_cam=nil;
    
    session_cam = [[AVCaptureSession alloc] init];
    session_cam.sessionPreset = AVCaptureSessionPresetPhoto;
    
    if (captureVideoPreviewLayer)
        captureVideoPreviewLayer=nil;
    
    captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session_cam];
    [captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    captureVideoPreviewLayer.frame = self.cameraView.bounds;
    [self.cameraView.layer addSublayer:captureVideoPreviewLayer];
    
    CGRect bounds = [self.cameraView bounds];
    [captureVideoPreviewLayer setFrame:bounds];
    
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *backCamera=nil;
    
    // check if device available
    if (devices.count==0) {
        // [self disableCameraDeviceControls];
        return;
    }
    
    for (AVCaptureDevice *device in devices)
    {
        if ([device hasMediaType:AVMediaTypeVideo]) {
            if ([device position] == AVCaptureDevicePositionBack) {
                backCamera = device;
            }
        }
    }
    
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
    if (input) {
        [session_cam addInput:input];
    }

    if (stillImageOutput)
        stillImageOutput=nil;
    
    stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [stillImageOutput setOutputSettings:outputSettings];
    
    [session_cam addOutput:stillImageOutput];
    
    [session_cam startRunning];
}
- (void) capImage
{ //method to capture image from AVCaptureSession video feed
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in stillImageOutput.connections)
    {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        
        if (videoConnection) {
            break;
        }
    }
    
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
        
        if (imageSampleBuffer != NULL) {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
            [session_cam stopRunning];
            _capturedImage =[UIImage imageWithData:imageData];
            [pictureImageView setImage:_capturedImage];
            [pictureImageView setHidden:NO];
            
            if (_capturedImage != nil) {
                self.progressHud = [[MBProgressHUD alloc] initWithView:self.view];
                self.progressHud.labelText = @"Please wait...";
                [self.view addSubview:self.progressHud];

                [self.progressHud showWhileExecuting:@selector(processOcrAt:) onTarget:self withObject:_capturedImage animated:YES];
            }
        }
    }];
}

@end
