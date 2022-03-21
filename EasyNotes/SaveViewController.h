//
//  ShareViewController.h
//  EasyNotes
//
//  Created by Petar Vasilev on 7/7/15.
//  Copyright (c) 2015 Petar Vasilev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SaveViewController : UIViewController <UITextViewDelegate, UIAlertViewDelegate> {

}

@property (weak, nonatomic) IBOutlet UITextView *recognizedTextView;

@property (weak, nonatomic) IBOutlet UIView *doneView;
- (IBAction)onMoreTakeClick:(id)sender;
- (IBAction)onSaveClick:(id)sender;
- (IBAction)onTrashClick:(id)sender;
- (IBAction)onBackClick:(id)sender;
- (IBAction)onDoneClick:(id)sender;
@end
