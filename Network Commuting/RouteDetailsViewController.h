//
//  RouteDetailsViewController.h
//  Network Commuting
//
//  Created by John Canfield on 2/25/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Itinerary.h"

@interface RouteDetailsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    NSDateFormatter *timeFormatter;
    
    UIBarButtonItem *twitterCaltrain;
    UIBarButtonItem *map;
    
}
@property(nonatomic, strong) IBOutlet UITableView* mainTable; // Table listing route options
@property(nonatomic, strong) IBOutlet UIButton* feedbackButton; 
@property(nonatomic, strong) IBOutlet UIButton* advisoryButton;  // Button to pull up Twitter feeds
@property(nonatomic, strong) Itinerary *itinerary;

@property(strong, nonatomic) id liveFeed;
@property( readwrite) BOOL isReload;
- (IBAction)feedbackButtonPressed:(id)sender forEvent:(UIEvent *)event;
- (IBAction)advisoryButtonPressed:(id)sender forEvent:(UIEvent *)event;

- (void) setLegRealtimeData:(NSString *)legId arrivalTime:(NSString *)arrivalTime arrivalFlag:(NSString *)arrivalFlag;
@end
