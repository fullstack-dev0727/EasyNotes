//
//  AppDelegate.h
//  EasyNotes
//
//  Created by Petar Vasilev on 5/31/15.
//  Copyright (c) 2015 Petar Vasilev. All rights reserved.
//

#import <UIKit/UIKit.h>
#define APPDELEGATE (AppDelegate *)[[UIApplication sharedApplication] delegate]
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) NSString* recognizedText;
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) BOOL isRestored;
@property (nonatomic) int indexForAdd;
- (NSMutableArray*) getFileArray;
- (void) setFileArray:(NSMutableArray*) value;
- (BOOL) isPaidVersion;
- (void) setPaidVersion:(BOOL) value;
- (NSInteger) getHeight;
- (void) setHeight:(NSInteger) value;

@end

