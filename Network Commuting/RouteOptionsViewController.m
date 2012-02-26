//
//  RouteOptionsViewController.m
//  Network Commuting
//
//  Created by John Canfield on 1/20/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "RouteOptionsViewController.h"
#import "Leg.h"
#import <math.h>

@implementation RouteOptionsViewController

@synthesize plan;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        [[self navigationItem] setTitle:@"Itineraries"];
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
    return [[plan itineraries] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Check for a reusable cell first, use that if it exists
    UITableViewCell *cell =
    [tableView dequeueReusableCellWithIdentifier:@"UIRouteOptionsViewCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle 
                                      reuseIdentifier:@"UIRouteOptionsViewCell"];
    }
    // Get the requested itinerary
    Itinerary *itin = [[plan sortedItineraries] objectAtIndex:[indexPath row]];

    // Set title
    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:14.0]];
    NSString *titleText = [NSString stringWithFormat:@"%@ - %@ (%d minutes)", 
                          [timeFormatter stringFromDate:[itin startTime]],
                          [timeFormatter stringFromDate:[itin endTime]],
                          (int) round([[itin duration] floatValue] / (1000.0 * 60.0))];
    [[cell textLabel] setText:titleText];
    
    // Set sub-title (show each leg's mode and route if available)
    NSMutableString *subTitle = [NSMutableString stringWithCapacity:30];
    NSArray *sortedLegs = [itin sortedLegs];
    for (int i = 0; i < [sortedLegs count]; i++) {
        Leg *leg = [sortedLegs objectAtIndex:i];
        if ([leg mode] && [[leg mode] length] > 0) {
            if (i > 0) {
                [subTitle appendString:@" -> "];
            }
            [subTitle appendString:[[leg mode] capitalizedString]];
            if ([leg route] && [[leg route] length] > 0) {
                [subTitle appendString:@" "];
                [subTitle appendString:[leg route]];
            }
        }
    }
    [[cell detailTextLabel] setText:subTitle];
    
    return cell;
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
