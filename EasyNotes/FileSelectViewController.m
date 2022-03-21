//
//  FileSelectViewController.m
//  EasyNotes
//
//  Created by Petar Vasilev on 8/4/15.
//  Copyright (c) 2015 Petar Vasilev. All rights reserved.
//
#import "TextEditorViewController.h"
#import "FileSelectViewController.h"
#import "AppDelegate.h"
#import <StoreKit/StoreKit.h>
#import "MBProgressHUD.h"

#define kPaidProduct @"com.easynotes.paid"
@interface FileSelectViewController () <SKProductsRequestDelegate, SKPaymentTransactionObserver> {
    SKProduct *curProduct;
}
@end

@implementation FileSelectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _filesTableView.allowsMultipleSelectionDuringEditing = NO;

    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 1.0; //seconds
    lpgr.delegate = self;
    [_filesTableView addGestureRecognizer:lpgr];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    AppDelegate* appDelegate = APPDELEGATE;
    _fileArray = [appDelegate getFileArray];
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    _fileArray= [[_fileArray sortedArrayUsingDescriptors:@[sort]] mutableCopy];
    
    [_filesTableView reloadData];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"texteditor"]) {
        TextEditorViewController* textEditorViewController = (TextEditorViewController*) segue.destinationViewController;
        textEditorViewController.selectedDic = _selectedDic;
        textEditorViewController.selectedIndex = _selectedIndex;
    }
}


- (IBAction)onCloseClick:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - UITableView Delegate & Datasrouce -
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([_fileArray count] > 0)
        return [_fileArray count];
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"fileTableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    NSDictionary* dic = [_fileArray objectAtIndex:indexPath.row];
    
    UILabel* titleLabel = (UILabel*) [cell.contentView viewWithTag:100];
    [titleLabel setText:[dic objectForKey:@"title"]];

    UILabel* dateLabel = (UILabel*) [cell.contentView viewWithTag:200];
    NSDate* currentDate = [dic objectForKey:@"date"];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"dd MMM yy"];
    NSString *dateString = [dateFormat stringFromDate:currentDate];
    [dateLabel setText:dateString];

    return cell;
}
- (void) shareFunc {
    [self performSegueWithIdentifier:@"texteditor" sender:self];
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedDic = [_fileArray objectAtIndex:indexPath.row];
    _selectedIndex = indexPath.row;
   [self shareFunc];
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}
-(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    AppDelegate* appDelegate = APPDELEGATE;
    UITableViewRowAction *editAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Add" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        //insert your editAction here
        if ([appDelegate isPaidVersion]) {
            appDelegate.indexForAdd = indexPath.row;
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"EasyNotes"
                                                            message:@"Unpaid Version! You want to purchase paid item?"
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Purchase", nil];
            alert.tag = 200;
            [alert show];
        }
    }];
    editAction.backgroundColor = [UIColor greenColor];
    
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Delete"  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
        //insert your deleteAction here
        [_fileArray removeObjectAtIndex:indexPath.row];
        [appDelegate setFileArray:_fileArray];
        [_filesTableView reloadData];
    }];
    deleteAction.backgroundColor = [UIColor redColor];
    return @[deleteAction,editAction];
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
}
- (void) showEditNameAlert: (NSString*) currentTitle {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter File Name"
                                                    message:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"OK", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert textFieldAtIndex:0].text = currentTitle;
    alert.tag = 100;
    [alert show];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        if (alertView.tag == 100) {
            NSString *title = [alertView textFieldAtIndex:0].text;
            if (title.length == 0) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"EasyNotes"
                                                                message:@"Name is empty!"
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
                return;
            }
            BOOL flag = false;
            for (int i=0;i<[_fileArray count]; i++) {
                NSMutableDictionary *dic = [_fileArray objectAtIndex:i];
                NSString *fileName = [dic objectForKey:@"title"];
                if ([title isEqual:fileName])
                    flag = true;
            }
            if (flag) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"EasyNotes"
                                                                message:@"File Name is already taken!"
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
                return;
            }
            _selectedDic = [_fileArray objectAtIndex:_selectedIndex];
            NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
            [dic setValue:title forKey:@"title"];
            [dic setValue:[_selectedDic objectForKey:@"date"] forKey:@"date"];
            [dic setValue:[_selectedDic objectForKey:@"content"] forKey:@"content"];
            
            [_fileArray removeObjectAtIndex:_selectedIndex];
            [_fileArray insertObject:dic atIndex:_selectedIndex];
            
            AppDelegate* appDelegate = APPDELEGATE;
            [appDelegate setFileArray:_fileArray];
            
            [_filesTableView reloadData];
            
        } else if (alertView.tag == 200) {
            [self purchaseItem];
        }
    }
}
-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:_filesTableView];
    
    NSIndexPath *indexPath = [_filesTableView indexPathForRowAtPoint:p];
    if (indexPath == nil) {
        NSLog(@"long press on table view but not on a row");
    } else if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        NSLog(@"long press on table view at row %d", indexPath.row);
        _selectedIndex = indexPath.row;
        NSMutableDictionary *dic = [_fileArray objectAtIndex:indexPath.row];
        [self showEditNameAlert:[dic objectForKey:@"title"]];
    } else {
        NSLog(@"gestureRecognizer.state = %d", gestureRecognizer.state);
    }
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
