//
//  RumexCustomTabBar.h
//  
//
//  Created by Oliver Farago on 19/06/2010.
//  Copyright 2010 Rumex IT All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RXCustomTabBar : UITabBarController {
	UIButton *btn1;
	UIButton *btn2;
	UIButton *btn3;
    UIImageView *barBackground;
	UIButton *btn4;
}

@property (nonatomic, strong) UIButton *btn1;
@property (nonatomic, strong) UIButton *btn2;
@property (nonatomic, strong) UIButton *btn3;
@property (nonatomic, strong) UIImageView *barBackground;
@property (nonatomic, strong) UIButton *btn4;

-(void) hideTabBar;
-(void) addCustomElements;
-(void) selectTab:(int)tabID;

-(void) hideNewTabBar;
- (void)buttonClicked:(id)sender;
- (void)showNewTabBar;

- (void) hideAllElements;
- (void) showAllElements;

@end
