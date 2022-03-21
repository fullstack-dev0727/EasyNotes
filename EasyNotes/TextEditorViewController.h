//
//  TextEditorViewController.h
//  EasyNotes
//
//  Created by Petar Vasilev on 7/7/15.
//  Copyright (c) 2015 Petar Vasilev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface TextEditorViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate, MFMailComposeViewControllerDelegate> {
    UITapGestureRecognizer* tapGesture;
}
@property (nonatomic) NSInteger selectedIndex;
@property (nonatomic) NSInteger contentHeight;
@property (nonatomic, strong) NSDictionary* selectedDic;
@property (weak, nonatomic) IBOutlet UITextField *filenameTextField;
@property (weak, nonatomic) IBOutlet UITextView *editTextView;
@property (weak, nonatomic) IBOutlet UIView *doneView;
- (IBAction)onDoneClick:(id)sender;
- (IBAction)onBackClick:(id)sender;
- (void) tapView:(UITapGestureRecognizer*)gesture;
- (IBAction)onEmailClick:(id)sender;
@end
