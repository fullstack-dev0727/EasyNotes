//
//  ViewController.h
//  EasyNotes
//
//  Created by Petar Vasilev on 5/31/15.
//  Copyright (c) 2015 Petar Vasilev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DLCImagePickerController.h"
#import "UIRotateImageView.h"

@class MBProgressHUD;
namespace tesseract {
    class TessBaseAPI;
};

@interface TakePictureViewController : UIViewController <DLCImagePickerDelegate> {

    MBProgressHUD *progressHud;
    tesseract::TessBaseAPI *tesseract;
    uint32_t *pixels;
    NSString* recognizedText;
    int recogCount;
    AVCaptureSession *session_cam;
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
    AVCaptureStillImageOutput *stillImageOutput;
}

@property (weak, nonatomic) IBOutlet UIView *viewLayer;
@property (weak, nonatomic) IBOutlet UIImageView *pictureImageView;
@property (nonatomic, retain) UIImage *capturedImage;
@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (nonatomic, strong) MBProgressHUD *progressHud;
@property (nonatomic, strong) NSMutableArray *croppedImageArray;

- (IBAction)onClickSetting:(id)sender;
- (IBAction)onClickScan:(id)sender;
- (IBAction)onClickOCR:(id)sender;
- (IBAction)onClickFlash:(id)sender;
- (void)setTesseractImage:(UIImage *)image;
- (void) initTessdata;
- (void) initializeCamera;

@end

