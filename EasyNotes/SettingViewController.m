//
//  SettingViewController.m
//  EasyNotes
//
//  Created by Petar Vasilev on 7/7/15.
//  Copyright (c) 2015 Petar Vasilev. All rights reserved.
//
#import "AppDelegate.h"
#import "SettingViewController.h"
#import <StoreKit/StoreKit.h>
#import "MBProgressHUD.h"
#define kPaidProduct @"com.easynotes.paid"

@interface SettingViewController () <SKProductsRequestDelegate, SKPaymentTransactionObserver> {
    SKProduct *curProduct;
    BOOL isRestored;
}

@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
- (void) restoreFunc {
    [MBProgressHUD showHUDAddedTo:self.view animated:NO];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}
- (IBAction)onFaqClick:(id)sender {
    [self performSegueWithIdentifier:@"faq" sender:self];
}

- (IBAction)onFeedbackClick:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.apple.com"]];
}

- (IBAction)onRestorePurchaseClick:(id)sender {
    [self restoreFunc];
}

- (IBAction)onBackClick:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response NS_AVAILABLE_IOS(3_0) {
    SKProduct *validProduct = nil;
    int count = [response.products count];
    if(count > 0){
        validProduct = [response.products objectAtIndex:0];
        NSLog(@"Products Available!");
        curProduct = validProduct;
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
    if (queue.transactions.count > 0) {
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
        
    }
    isRestored = YES;
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
