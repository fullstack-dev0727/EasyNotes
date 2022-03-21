//
//  TextEditorViewController.m
//  EasyNotes
//
//  Created by Petar Vasilev on 7/7/15.
//  Copyright (c) 2015 Petar Vasilev. All rights reserved.
//
#import "AppDelegate.h"
#import "TextEditorViewController.h"
#import "SaveViewController.h"

@interface TextEditorViewController ()

@end

@implementation TextEditorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [_filenameTextField setText:[_selectedDic objectForKey:@"title"]];
    [_editTextView setText:[_selectedDic objectForKey:@"content"]];

    CGRect textRect = _editTextView.frame;
    _contentHeight = textRect.size.height;
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardOnScreen:) name:UIKeyboardDidShowNotification object:nil];
    [center addObserver:self selector:@selector(keyboardOffScreen:) name:UIKeyboardDidHideNotification object:nil];
    
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapView:)];
    [self.view addGestureRecognizer:tapGesture];
}
- (void) tapView:(UITapGestureRecognizer*)gesture {
    if ( tapGesture ) {
        [_editTextView resignFirstResponder];
        [_filenameTextField resignFirstResponder];
    }
}

- (IBAction)onEmailClick:(id)sender {
    NSString* title = _filenameTextField.text;
    NSString* text = _editTextView.text;
    if (title.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"EasyNotes"
                                                        message:@"Title is empty!"
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    AppDelegate* appDelegate = APPDELEGATE;
    NSMutableArray* fileArray = [appDelegate getFileArray];
    [fileArray removeObjectAtIndex:_selectedIndex];
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
    [dic setValue:title forKey:@"title"];
    [dic setValue:text forKey:@"content"];
    [dic setValue:[NSDate date] forKey:@"date"];
    [fileArray addObject:dic];
    [appDelegate setFileArray:fileArray];
    
    [_editTextView resignFirstResponder];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:title];
    [mc setMessageBody:text isHTML:NO];
    
    // Present mail view controller on screen
    [self presentViewController:mc animated:YES completion:NULL];
}
-(void)keyboardOnScreen:(NSNotification *)notification
{
    AppDelegate* appDelegate = APPDELEGATE;
    NSInteger height = [appDelegate getHeight];
    CGRect textRect = _editTextView.frame;
    textRect.size = CGSizeMake(textRect.size.width, _contentHeight - height);
    [_editTextView setFrame:textRect];
  
}
-(void)keyboardOffScreen:(NSNotification *)notification
{
    [_doneView setHidden:YES];
    CGRect rect = _editTextView.frame;
    rect.size = CGSizeMake(rect.size.width, _contentHeight);
    [_editTextView setFrame:rect];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.

}
- (BOOL) textViewShouldBeginEditing:(UITextView *)textView {
    AppDelegate* appDelegate = APPDELEGATE;
    CGRect rect = _doneView.frame;
    rect.origin.y = self.view.frame.size.height - 40 - [appDelegate getHeight];
    [_doneView setFrame: rect];
    [_doneView setHidden:NO];
    return YES;
}
- (void)textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
- (IBAction)onDoneClick:(id)sender {
    [_doneView setHidden:YES];
    [_editTextView resignFirstResponder];
    
}
- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)onBackClick:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
