//
// RouteDetailsViewController.h
// Nimbler World, Inc.
//
// Created by John Canfield on 2/25/12.
// Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Itinerary.h"
#import "LegMapViewController.h"
#import "TTTAttributedLabel.h"

@interface RouteDetailsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,RKRequestDelegate,UIGestureRecognizerDelegate,UIWebViewDelegate,TTTAttributedLabelDelegate>
{
    NSDateFormatter *timeFormatter;
    UIBarButtonItem *twitterCaltrain;
    UIActivityIndicatorView *activityIndicatorView;
    float yPos;
}
@property(nonatomic, strong) IBOutlet UITableView* mainTable; // Table listing route details
@property(nonatomic, strong) IBOutlet MKMapView *mapView;
@property(nonatomic, strong) LegMapViewController* legMapVC; // View Controller for managing the map
@property(nonatomic, strong) Itinerary *itinerary;
@property(nonatomic) int itineraryNumber; // selected row on the itinerary list

@property(nonatomic, strong) UIButton *btnBackItem;
@property(nonatomic, strong) UIButton *btnForwardItem;
@property(nonatomic, strong) UIButton *btnGoToItinerary;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) int count;
@property (nonatomic, strong) IBOutlet UILabel* lblNextRealtime;
@property (nonatomic, strong) IBOutlet UIButton* handleControl;
@property (nonatomic, strong) NSLayoutConstraint* handleVerticalConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* mapToTableRatioConstraint;
@property (nonatomic) int mapHeight;
@property (nonatomic) int tableHeight;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) IBOutlet UIButton *btnFeedBack;

- (IBAction)navigateBack:(id)sender;
- (IBAction)navigateForward:(id)sender;
-(void)ReloadLegWithNewData;
-(void)setFBParameterForItinerary;
-(void)popOutToItinerary;
-(void)setFBParamater:(int)ss;
-(void)setFBParameterForLeg:(NSString *)legId;
-(void)newItineraryAvailable:(Itinerary *)newItinerary
                      status:(ItineraryStatus)status ItineraryNumber:(int)itiNumber;
- (void) intermediateStopTimesReceived:(NSArray *)stopTimes Leg:(Leg *)leg;
- (void)openUrl:(NSURL *)url;

// return Formatted string like 00:58
- (NSString *) returnFormattedStringFromSeconds:(int) seconds;
- (IBAction)feedBackClicked:(id)sender;
@end