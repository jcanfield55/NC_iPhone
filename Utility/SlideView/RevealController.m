/* 
 
 Copyright (c) 2011, Philip Kluz (Philip.Kluz@zuui.org)
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 * Neither the name of Philip Kluz, 'zuui.org' nor the names of its contributors may 
 be used to endorse or promote products derived from this software 
 without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL PHILIP KLUZ BE LIABLE FOR ANY DIRECT, 
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */

#import "RevealController.h"

#import "ToFromViewController.h"
#import "twitterViewController.h"
#import "nc_AppDelegate.h"
#import "FeedBackForm.h"
#import "SettingInfoViewController.h"
#import "SettingDetailViewController.h"

@implementation RevealController

#pragma mark - Initialization

- (id)initWithFrontViewController:(UIViewController *)aFrontViewController rearViewController:(UIViewController *)aBackViewController
{
	self = [super initWithFrontViewController:aFrontViewController rearViewController:aBackViewController];
	
	if (nil != self)
	{
		self.delegate = self;
	}
	
	return self;
}

#pragma - ZUUIRevealControllerDelegate Protocol.

/*
 * All of the methods below are optional. You can use them to control the behavior of the ZUUIRevealController, 
 * or react to certain events.
 */
- (BOOL)revealController:(ZUUIRevealController *)revealController shouldRevealRearViewController:(UIViewController *)rearViewController
{
	return YES;
}

- (BOOL)revealController:(ZUUIRevealController *)revealController shouldHideRearViewController:(UIViewController *)rearViewController 
{
	return YES;
}

- (void)revealController:(ZUUIRevealController *)revealController willRevealRearViewController:(UIViewController *)rearViewController 
{
   UINavigationController *navController = (UINavigationController *) ((UITabBarController *) rearViewController).selectedViewController;
   twitterViewController *twitterVC = (twitterViewController *)navController.topViewController;
    if([twitterVC isKindOfClass:[twitterViewController class]]){
        [twitterVC getAdvisoryData];
        [nc_AppDelegate sharedInstance].isNotificationsButtonClicked = YES;
        [nc_AppDelegate sharedInstance].isTwitterView = YES;
    }
    if([twitterVC isKindOfClass:[twitterViewController class]] || [twitterVC isKindOfClass:[SettingInfoViewController class]] || [twitterVC isKindOfClass:[FeedBackForm class]]){
        [twitterVC hideTabBar];
    }
}

- (void)revealController:(ZUUIRevealController *)revealController didRevealRearViewController:(UIViewController *)rearViewController
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)revealController:(ZUUIRevealController *)revealController willHideRearViewController:(UIViewController *)rearViewController
{
    [nc_AppDelegate sharedInstance].isNotificationsButtonClicked = NO;
    [nc_AppDelegate sharedInstance].isTwitterView = NO;
    UINavigationController *navController = (UINavigationController *) ((UITabBarController *) rearViewController).selectedViewController;
    FeedBackForm *feedbackVC = (FeedBackForm *)navController.topViewController;
    if([feedbackVC isKindOfClass:[FeedBackForm class]]){
        if([feedbackVC.txtFeedBack isFirstResponder]){
            [feedbackVC.txtFeedBack resignFirstResponder];
        }
        if([feedbackVC.txtEmailId isFirstResponder]){
           [feedbackVC.txtEmailId resignFirstResponder]; 
        }
    }
    
    // Fixed DE-383
    SettingInfoViewController *settingsVC = (SettingInfoViewController *)navController.topViewController;
    if([settingsVC isKindOfClass:[SettingInfoViewController class]]){
        [settingsVC saveSetting];
    }
    
    SettingDetailViewController*settingsDetailVC = (SettingDetailViewController *)navController.topViewController;
    if([settingsVC isKindOfClass:[SettingDetailViewController class]]){
        [settingsDetailVC clearCacheAndSaveSettingsToServer];
    }
	NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)revealController:(ZUUIRevealController *)revealController didHideRearViewController:(UIViewController *)rearViewController 
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)revealController:(ZUUIRevealController *)revealController willResignRearViewControllerPresentationMode:(UIViewController *)rearViewController
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)revealController:(ZUUIRevealController *)revealController didResignRearViewControllerPresentationMode:(UIViewController *)rearViewController
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)revealController:(ZUUIRevealController *)revealController willEnterRearViewControllerPresentationMode:(UIViewController *)rearViewController
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)revealController:(ZUUIRevealController *)revealController didEnterRearViewControllerPresentationMode:(UIViewController *)rearViewController
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return (toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end