//
//  FileTableViewCell.h
//  EasyNotes
//
//  Created by Petar Vasilev on 8/4/15.
//  Copyright (c) 2015 Petar Vasilev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FileTableViewCell : UITableViewCell {
    
}
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
- (IBAction)onShareClick:(id)sender;

@end
