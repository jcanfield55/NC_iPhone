//
//  RouteDetailsViewController.m
//  Network Commuting
//
//  Created by John Canfield on 2/25/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "RouteDetailsViewController.h"
#import "Leg.h"
#import "LegMapViewController.h"

@implementation RouteDetailsViewController

@synthesize itinerary;

/*
 DE4 Solution  
 */
int const START_STOP = 45;
int const REAL_ROOT = 68;
int const STR_LIMIT = 40;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        [[self navigationItem] setTitle:@"Route"];
        timeFormatter = [[NSDateFormatter alloc] init];
        [timeFormatter setTimeStyle:NSDateFormatterShortStyle];
        
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

// Table view management methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[itinerary legs] count] > 0) {
        return [[itinerary legs] count]+2;  // # of legs plus start & end point
    }
    else {
        return 0;  // TODO come up with better handling for no legs in this itinerary
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Check for a reusable cell first, use that if it exists
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"UIRouteDetailsViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
                                      reuseIdentifier:@"UIRouteDetailsViewCell"];
    }

    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]];
    [[cell detailTextLabel] setFont:[UIFont systemFontOfSize:14.0]];

    NSString *titleText;
    NSString *subTitle;
    if ([indexPath row] == 0) { // if first row, put in start point
        titleText = [NSString stringWithFormat:@"Start at %@", [[itinerary from] name]];
    }
    else if ([indexPath row] == [[itinerary sortedLegs] count] + 1) { // if last row, put in end point
        titleText = [NSString stringWithFormat:@"End at %@", [[itinerary to] name]];
    }
    else {  // otherwise, it is one of the legs
        Leg *leg = [[itinerary sortedLegs] objectAtIndex:([indexPath row]-1)];
        titleText = [leg directionsTitleText];
        subTitle = [leg directionsDetailText];
       
        
/*
 DE4 Fix - Apprika Systems
 Edited by Sitanshu Joshi.
 */
    
         if ([subTitle length] > 70) {
             NSString * add1;
             NSString * add2;
            
             NSLog(@"more %@",subTitle);
             NSArray *firstSplit = [subTitle componentsSeparatedByString:@"\n"];
             NSLog(@"%@",firstSplit);
             for(int i=0;i<[firstSplit count];i++){
                 NSString *str=[firstSplit objectAtIndex:i];               
                 if ([str length] > STR_LIMIT) {
                     str = [str substringToIndex:STR_LIMIT];
                     if(i==0){
                         add1 = [str stringByAppendingString:@"...\n"];
                         NSLog(@"Saperate %@",str);
                     }else if(i==1){
                         add2 = [str stringByAppendingString:@"..."];
                         NSLog(@"Saperate %@",str);
                     }
                 } else {
                     if(i==0){
                         add1 = [str stringByAppendingString:@"\n"];
                     } else if(i==1){
                         add2 = [str stringByAppendingString:@" "];
                     }
                 }          
                             
             }
             subTitle = [add1 stringByAppendingString:add2];  
        }
              
    }
    
    [[cell textLabel] setText:titleText];
    [[cell detailTextLabel] setLineBreakMode:UILineBreakModeWordWrap];
    [[cell detailTextLabel] setNumberOfLines:0];
    [[cell detailTextLabel] setText:subTitle];
    
    if (subTitle && [subTitle length] > 40) {
       [[cell detailTextLabel] sizeToFit];
    }

    return cell;
}

// If selected, show the LegMapViewController
- (void) tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Initialize the LegMapView Controller
    LegMapViewController *legMapVC = [[LegMapViewController alloc] initWithNibName:nil bundle:nil];

    // Initialize the leg VC with the full itinerary and the particular leg object chosen
    [legMapVC setItinerary:itinerary itineraryNumber:[indexPath row]];
    
    [[self navigationController] pushViewController:legMapVC animated:YES];
}

/*
 DE4 Fix - Apprika Systems
 Edited by Sitanshu Joshi.
 
 */
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{

        return REAL_ROOT;

}



@end
