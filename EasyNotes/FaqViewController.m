//
//  FaqViewController.m
//  EasyNotes
//
//  Created by Petar Vasilev on 10/7/15.
//  Copyright © 2015 Petar Vasilev. All rights reserved.
//

#import "FaqViewController.h"

@interface FaqViewController ()

@end

@implementation FaqViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [_contentScrollView setContentSize:CGSizeMake(self.view.frame.size.width, 800)];
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

- (IBAction)onBackClick:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
@end
