//
//  AppDelegate.m
//  EasyNotes
//
//  Created by Petar Vasilev on 5/31/15.
//  Copyright (c) 2015 Petar Vasilev. All rights reserved.
//

#import "AppDelegate.h"
#import <StoreKit/StoreKit.h>

#define kPaidProduct @"com.easynotes.paid"

@interface AppDelegate () <SKProductsRequestDelegate, SKPaymentTransactionObserver> {
    SKProduct *curProduct;
}

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    AppDelegate* appDelegate = APPDELEGATE;
    appDelegate.recognizedText = @"";
    _indexForAdd = -1;
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

    
}
- (void) restoreFunc {
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}
- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [self restoreFunc];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (NSMutableArray*) getFileArray {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray* array = [[defaults valueForKey:@"filearray"] mutableCopy];
    return array;
}
- (void) setFileArray:(NSMutableArray*) value {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:@"filearray"];
    [defaults synchronize];
}
- (BOOL) isPaidVersion {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL flag = [[defaults valueForKey:@"paidVersion"] boolValue];
    return flag;
}
- (void) setPaidVersion:(BOOL) value {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:value forKey:@"paidVersion"];
    [defaults synchronize];
}
- (NSInteger) getHeight {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger flag = [[defaults valueForKey:@"keyboardheight"] integerValue];
    return flag;
}
- (void) setHeight:(NSInteger) value {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:value forKey:@"keyboardheight"];
    [defaults synchronize];
}
#pragma mark - SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response NS_AVAILABLE_IOS(3_0) {
    
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
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        }
    }
    AppDelegate* appDelegate = APPDELEGATE;
    appDelegate.isRestored = YES;
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
                
                //                [Utilities showMsg:@"Successfully Restored!"];
                break;
            case SKPaymentTransactionStateFailed:
                //called when the transaction does not finish
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
