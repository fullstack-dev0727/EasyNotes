//
//  FileSelectViewController.h
//  EasyNotes
//
//  Created by Petar Vasilev on 8/4/15.
//  Copyright (c) 2015 Petar Vasilev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FileSelectViewController : UIViewController <UIAlertViewDelegate> {

}
- (IBAction)onCloseClick:(id)sender;
@property (weak, nonatomic) IBOutlet UITableView *filesTableView;
@property (nonatomic, strong) NSMutableArray* fileArray;
@property (nonatomic, strong) NSDictionary* selectedDic;
@property (nonatomic) NSInteger selectedIndex;
-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void) showEditNameAlert: (NSString*) currentTitle;
@end
