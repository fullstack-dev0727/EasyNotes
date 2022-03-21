//
//  ShareViewController.m
//  EasyNotes
//
//  Created by Petar Vasilev on 7/7/15.
//  Copyright (c) 2015 Petar Vasilev. All rights reserved.
//

#import "SaveViewController.h"
#import "AppDelegate.h"
#import "MBProgressHUD.h"
#import <StoreKit/StoreKit.h>

#define kPaidProduct @"com.easynotes.paid"
@interface SaveViewController () <SKProductsRequestDelegate, SKPaymentTransactionObserver> {
    SKProduct *curProduct;

}

@end

@implementation SaveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    AppDelegate* appDelegate = APPDELEGATE;
    appDelegate.isRestored = NO;
    // Do any additional setup after loading the view.
    _recognizedTextView.text = appDelegate.recognizedText;

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardOnScreen:) name:UIKeyboardDidShowNotification object:nil];
    [center addObserver:self selector:@selector(keyboardOffScreen:) name:UIKeyboardDidHideNotification object:nil];

}
-(void)keyboardOnScreen:(NSNotification *)notification
{
    AppDelegate* appDelegate = APPDELEGATE;
    NSDictionary *info  = notification.userInfo;
    NSValue      *value = info[UIKeyboardFrameEndUserInfoKey];
    CGRect rawFrame      = [value CGRectValue];
    [appDelegate setHeight:rawFrame.size.height];
    
    NSInteger height = [appDelegate getHeight];
    CGRect textRect = _recognizedTextView.frame;
    textRect.size = CGSizeMake(textRect.size.width, textRect.size.height + 52 - height);
    [_recognizedTextView setFrame:textRect];
   
}

-(void)keyboardOffScreen:(NSNotification *)notification
{
    [_doneView setHidden:YES];

    AppDelegate* appDelegate = APPDELEGATE;
    NSInteger height = [appDelegate getHeight];
    CGRect rect = _recognizedTextView.frame;
    rect.size = CGSizeMake(rect.size.width, rect.size.height + height - 52);
    [_recognizedTextView setFrame:rect];


}
- (IBAction)onDoneClick:(id)sender {
    [_doneView setHidden:YES];
    [_recognizedTextView resignFirstResponder];
    
}
#pragma mark UITextViewDelegate
- (BOOL) textViewShouldBeginEditing:(UITextView *)textView {
    AppDelegate* appDelegate = APPDELEGATE;
    CGRect rect = _doneView.frame;
    rect.origin.y = self.view.frame.size.height - 40 - [appDelegate getHeight];
    [_doneView setFrame: rect];
    [_doneView setHidden:NO];
    return YES;
}
- (BOOL) textViewShouldEndEditing:(UITextView *)textView {
    return YES;
}

- (void) purchaseItem {
    AppDelegate* appDelegate = APPDELEGATE;
    if (appDelegate.isRestored == NO)
        return;
    if([SKPaymentQueue canMakePayments]){
        NSLog(@"User can make payments");
        if (![appDelegate isPaidVersion]) {
            [MBProgressHUD showHUDAddedTo:self.view animated:NO];
            
            SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:kPaidProduct]];
            productsRequest.delegate = self;
            [productsRequest start];
        }
        
    }
    else{
        NSLog(@"User cannot make payments due to parental controls");
        //this is called the user cannot make payments, most likely due to parental controls
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onMoreTakeClick:(id)sender {
    AppDelegate* appDelegate = APPDELEGATE;
    if ([appDelegate isPaidVersion]) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"EasyNotes"
                                                        message:@"Unpaid Version! You want to purchase paid item?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Purchase", nil];
        [alert show];
    }
}

- (IBAction)onSaveClick:(id)sender {
    AppDelegate* appDelegate = APPDELEGATE;
    appDelegate.recognizedText = _recognizedTextView.text;
    NSMutableArray* fileArray = [appDelegate getFileArray];
    if (fileArray == nil) {
        fileArray = [[NSMutableArray alloc] init];
    }
    if (appDelegate.indexForAdd >= 0 && [fileArray count] > appDelegate.indexForAdd) {
        NSMutableDictionary* dic = [[fileArray objectAtIndex:appDelegate.indexForAdd] mutableCopy];
        NSString *content = [dic objectForKey:@"content"];
        content = [NSString stringWithFormat:@"%@\n\n%@", content, appDelegate.recognizedText];
        [dic setValue:content forKey:@"content"];
        [fileArray replaceObjectAtIndex:appDelegate.indexForAdd withObject:dic];
        [appDelegate setFileArray:fileArray];
        appDelegate.indexForAdd = -1;
    } else {
        int count = [fileArray count];
        NSString* title = @"File1";
        int index = 0;
        BOOL flag = true;
        while (flag) {
            title = [NSString stringWithFormat:@"File%d", ++index];
            flag = false;
            for (int i = 0; i < count; i++) {
                NSMutableDictionary* dic = [fileArray objectAtIndex:i];
                NSString *fileTitle = [dic objectForKey:@"title"];
                if ([title isEqual:fileTitle])
                    flag = true;
            }
            
        }
        
        NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
        [dic setValue:title forKey:@"title"];
        [dic setValue:[NSDate date] forKey:@"date"];
        [dic setValue:appDelegate.recognizedText forKey:@"content"];
        [fileArray addObject:dic];
        [appDelegate setFileArray:fileArray];
        appDelegate.recognizedText = @"";
    }
    [self performSegueWithIdentifier:@"fileselect" sender:self];
}

- (IBAction)onTrashClick:(id)sender {
    AppDelegate* appDelegate = APPDELEGATE;
    appDelegate.recognizedText = @"";
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)onBackClick:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) { // cancel

    } else {
        [self purchaseItem];
    }
}

- (void) purchase:(SKProduct *)product{
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response NS_AVAILABLE_IOS(3_0) {
    
    SKProduct *validProduct = nil;
    int count = [response.products count];
    if(count > 0){
        validProduct = [response.products objectAtIndex:0];
        NSLog(@"Products Available!");
        curProduct = validProduct;
        
        [self purchase:validProduct];
    }
    else if(!validProduct){
        [MBProgressHUD hideHUDForView:self.view animated:NO];
        NSLog(@"No products available, %@", response.debugDescription);
        //this is called if your product id is not valid, this shouldn't be called unless that happens.
    }
}

- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"received restored transactions: %i", queue.transactions.count);
    for(SKPaymentTransaction *transaction in queue.transactions){
        if(transaction.transactionState == SKPaymentTransactionStateRestored || transaction.transactionState == SKPaymentTransactionStatePurchased){
            //called when the user successfully restores a purchase
            
//            NSLog(@"Transaction state -> Restored, %@", transaction.payment.productIdentifier);
//            if ([transaction.payment.productIdentifier isEqualToString:kRemoveAdsProductIdentifier])
//                [self doRemoveAds];
//            else if ([transaction.payment.productIdentifier isEqualToString:kUnlimitedPlayProductIdentifier]) {
//                [[SharedDataManager instance] setIsUnlimitedPlay:YES];
//                [self removeLives];
//            }
            [MBProgressHUD hideHUDForView:self.view animated:NO];
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        }
    }
    AppDelegate* appDelegate = APPDELEGATE;
    appDelegate.isRestored = YES;
    [MBProgressHUD hideHUDForView:self.view animated:NO];
    //    [Utilities showMsg:@"Successfully Restored"];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
    
    AppDelegate* appDelegate = APPDELEGATE;
    
    for(SKPaymentTransaction *transaction in transactions){
        switch(transaction.transactionState){
            case SKPaymentTransactionStatePurchasing: NSLog(@"Transaction state -> Purchasing");
                //called when the user is in the process of purchasing, do not add any of your own code here.
                break;
            case SKPaymentTransactionStatePurchased:
                //this is called when the user has successfully purchased the package (Cha-Ching!)
                //you can add your code for what you want to happen when the user buys the purchase here, for this tutorial we use removing ads
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                

                NSLog(@"Transaction state -> Purchased");
                
//                if ([curProduct.productIdentifier isEqualToString:kRemoveAdsProductIdentifier])
//                    [self doRemoveAds];
//                else if ([curProduct.productIdentifier isEqualToString:kUnlimitedPlayProductIdentifier])
//                {
//                    [[SharedDataManager instance] setIsUnlimitedPlay:YES];
//                    [self removeLives];
//                }
               
               [MBProgressHUD hideHUDForView:self.view animated:NO];
                
                //                [Utilities showMsg:@"Successfully Purchased!"];
                [appDelegate setPaidVersion:YES];
                if (appDelegate.isRestored)
                    [self.navigationController popViewControllerAnimated:YES];
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"Transaction state -> Restored, %@", transaction.payment.productIdentifier);
                //add the same code as you did from SKPaymentTransactionStatePurchased here
//                if ([transaction.payment.productIdentifier isEqualToString:kRemoveAdsProductIdentifier])
//                    [self doRemoveAds];
//                else if ([transaction.payment.productIdentifier isEqualToString:kUnlimitedPlayProductIdentifier]) {
//                    [[SharedDataManager instance] setIsUnlimitedPlay:YES];
//                    [self removeLives];
//                }
                
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                   [MBProgressHUD hideHUDForView:self.view animated:NO];
                
                //                [Utilities showMsg:@"Successfully Restored!"];
                break;
            case SKPaymentTransactionStateFailed:
                //called when the transaction does not finish
                [MBProgressHUD hideHUDForView:self.view animated:NO];
                NSLog(@"Transaction state -> Cancelled %@", transaction.error.description);
                //                [Utilities showMsg:@"Transaction Failed!"];
                
                if(transaction.error.code == SKErrorPaymentCancelled){
                    NSLog(@"Transaction state -> Cancelled %@", transaction.error.description);
                    //the user cancelled the payment ;(
                }
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                
                [appDelegate setPaidVersion:NO];

                break;
        }
    }
}

@end
