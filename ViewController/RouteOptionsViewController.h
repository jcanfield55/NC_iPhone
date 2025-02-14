//
// RouteOptionsViewController.h
// Nimbler World, Inc.
//
// Created by John Canfield on 1/20/12.
// Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Plan.h"
#import "enums.h"
#import "RouteDetailsViewController.h"
#import "UberDetailViewController.h"
#import "PlanStore.h"

@interface RouteOptionsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, RKRequestDelegate,
NewPlanAvailableDelegate>

@property(nonatomic, strong) IBOutlet UITableView* mainTable; // Table listing route options
@property(nonatomic, strong) IBOutlet UILabel* noItineraryWarning;
@property(nonatomic, strong) IBOutlet UIView* modeBtnView;  // Container for mode selector buttongs
@property(nonatomic, strong) IBOutlet UILabel* travelByLabel; 
@property(nonatomic, strong, readonly) Plan *plan; // use newPlanAvailable method to update the plan
@property(nonatomic, strong) UIButton *btnGoToNimbler;
@property( readwrite) BOOL isReloadRealData;
@property (nonatomic, strong) PlanRequestParameters *planRequestParameters;
@property(nonatomic, strong) RouteDetailsViewController* routeDetailsVC;
@property(nonatomic, strong) UberDetailViewController* uberDetailsVC;
@property(nonatomic, strong) PlanStore* planStore;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) NSTimer *timerGettingRealDataByItinerary;
@property (nonatomic, strong) NSTimer *timerRealtime;
@property (nonatomic) int remainingCount;
@property (nonatomic, strong) IBOutlet UIButton *btnFeedBack;

- (void) decrementCounter;
-(void)hideUnUsedTableViewCell;
-(void)setFBParameterForPlan;
-(void)popOutToNimbler;

- (void) reloadData:(Plan *)newPlan;
-(void) toggleExcludeButton:(id)sender;

- (int) calculateTotalHeightOfButtonView;
- (void) createViewWithButtons:(int)height;
- (void) changeMainTableSettings;

- (void) requestServerForRealTime;

- (IBAction)feedBackClicked:(id)sender;

@end