//
//  twitterViewController.m
//  Nimbler
//
//  Created by JaY Kumbhani on 6/21/12.
//  Copyright (c) 2012 Nimbler World, Inc.. All rights reserved.
//

#import "twitterViewController.h"
#import "UtilityFunctions.h"
#import <RestKit/RKJSONParserJSONKit.h>
#import "nc_AppDelegate.h"
#import "QuartzCore/QuartzCore.h"
#import "NMWebView.h"
#import "SettingInfoViewController.h"
#import "FeedBackForm.h"

#define TWEETERVIEW_MANE        @"Advisories"
#define TABLE_CELL              @"Cell"
#define CALTRAIN_CELL_HEADER    @"Caltrain @Caltrain"
#define TWEET                   @"tweet"
#define TWEET_TIME              @"time"
#define TWEET_SOURCE            @"source"
#define CALTRAIN_IMG            @"caltrain.jpg"

#define MAXLINE_TAG             5
#define CELL_HEIGHT             110
#define REFRESH_HEADER_HEIGHT 52.0f

@interface twitterViewController()
{
    // Variables for internal use
    NSStringDrawingContext *drawingContext;  // Drawing context for attributed strings
}
@end


@implementation twitterViewController
UITableViewCell *cell;
NSUserDefaults *prefs;

@synthesize mainTable,twitterData,dateFormatter,reload,isFromAppDelegate,isTwitterLiveData,noAdvisory,getTweetInProgress,timerForStopProcees,arrayTweet,strAllAdvisories,activityIndicatorView;

@synthesize textPull, textRelease, textLoading, refreshHeaderView, refreshLabel, refreshArrow, refreshSpinner;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self != nil) {
        [self setupStrings];
        drawingContext = [[NSStringDrawingContext alloc] init];
        drawingContext.minimumScaleFactor = 0.0;  // Specifies no scaling
    }
    return self;
}

-(void)hideUnUsedTableViewCell{
    UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    view.backgroundColor = [UIColor clearColor];
    [mainTable setTableFooterView:view];
}
-(void)popOut
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController.navigationBar setHidden:YES];
    [self.navigationItem setHidesBackButton:YES animated:YES];
    
    [self addPullToRefreshHeader];
    // Accessibility Label For UI Automation.
    self.mainTable.accessibilityLabel = TWITTER_TABLE_VIEW;
    
    arrayTweet = [[NSMutableArray alloc] init];
    [self hideUnUsedTableViewCell];
    if([self.navigationController.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
        [self.navigationController.navigationBar setBackgroundImage:returnNavigationBarBackgroundImage() forBarMetrics:UIBarMetricsDefault];
    }
    else {
        [self.navigationController.navigationBar insertSubview:[[UIImageView alloc] initWithImage:returnNavigationBarBackgroundImage()] aboveSubview:self.navigationController.navigationBar];
    }
    UILabel* lblNavigationTitle=[[UILabel alloc] initWithFrame:CGRectMake(0,0, NAVIGATION_LABEL_WIDTH, NAVIGATION_LABEL_HEIGHT)];
    [lblNavigationTitle setFont:[UIFont LARGE_BOLD_FONT]];
    lblNavigationTitle.text=TWITTER_VIEW_TITLE;
    lblNavigationTitle.textColor= [UIColor NAVIGATION_TITLE_COLOR];
    [lblNavigationTitle setTextAlignment:NSTextAlignmentCenter];
    lblNavigationTitle.backgroundColor =[UIColor clearColor];
    lblNavigationTitle.adjustsFontSizeToFitWidth=YES;
    self.navigationItem.titleView=lblNavigationTitle;              
    
    dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterFullStyle];
    prefs = [NSUserDefaults standardUserDefaults];
}

- (void)setupStrings{
    textPull = @"Pull down to refresh...";
    textRelease =@"Release to refresh...";
    textLoading = @"Loading...";
}

- (void)addPullToRefreshHeader {
    refreshHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0 - REFRESH_HEADER_HEIGHT, 285, REFRESH_HEADER_HEIGHT)];
    refreshHeaderView.backgroundColor = [UIColor clearColor];
    
    refreshLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 285, REFRESH_HEADER_HEIGHT)];
    refreshLabel.backgroundColor = [UIColor clearColor];
    refreshLabel.font = [UIFont boldSystemFontOfSize:12.0];
    refreshLabel.textAlignment = NSTextAlignmentCenter;
    [refreshLabel setTextColor:[UIColor whiteColor]];
    
    refreshArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow.png"]];
    refreshArrow.frame = CGRectMake(floorf((REFRESH_HEADER_HEIGHT - 27) / 2),
                                    (floorf(REFRESH_HEADER_HEIGHT - 44) / 2),
                                    27, 44);
    
    refreshSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    refreshSpinner.frame = CGRectMake(floorf(floorf(REFRESH_HEADER_HEIGHT - 20) / 2), floorf((REFRESH_HEADER_HEIGHT - 20) / 2), 20, 20);
    refreshSpinner.hidesWhenStopped = YES;
    if ([UIActivityIndicatorView instancesRespondToSelector:@selector(setColor:)]) {
        [refreshSpinner setColor:[UIColor whiteColor]];
    }
    
    [refreshHeaderView addSubview:refreshLabel];
    [refreshHeaderView addSubview:refreshArrow];
    [refreshHeaderView addSubview:refreshSpinner];
    [mainTable addSubview:refreshHeaderView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (isLoading) return;
    isDragging = YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (isLoading) {
        // Update the content inset, good for section headers
        if (scrollView.contentOffset.y > 0)
            mainTable.contentInset = UIEdgeInsetsZero;
        else if (scrollView.contentOffset.y >= -REFRESH_HEADER_HEIGHT)
            mainTable.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
    } else if (isDragging && scrollView.contentOffset.y < 0) {
        // Update the arrow direction and label
        [UIView animateWithDuration:0.25 animations:^{
            if (scrollView.contentOffset.y < -REFRESH_HEADER_HEIGHT) {
                // User is scrolling above the header
                refreshLabel.text = self.textRelease;
                [refreshArrow layer].transform = CATransform3DMakeRotation(M_PI, 0, 0, 1);
            } else {
                // User is scrolling somewhere within the header
                refreshLabel.text = self.textPull;
                [refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
            }
        }];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (isLoading) return;
    isDragging = NO;
    if (scrollView.contentOffset.y <= -REFRESH_HEADER_HEIGHT) {
        // Released above the header
        [self startLoading];
    }
}

- (void)startLoading {
    isLoading = YES;
    
    // Show the header
    [UIView animateWithDuration:0.3 animations:^{
        mainTable.contentInset = UIEdgeInsetsMake(REFRESH_HEADER_HEIGHT, 0, 0, 0);
        refreshLabel.text = self.textLoading;
        refreshArrow.hidden = YES;
        [refreshSpinner startAnimating];
    }];
    
    // Refresh action!
    [self refresh];
}

- (void)stopLoading {
    isLoading = NO;
    
    // Hide the header
    [UIView animateWithDuration:0.3 animations:^{
        mainTable.contentInset = UIEdgeInsetsZero;
        [refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
    }
                     completion:^(BOOL finished) {
                         [self performSelector:@selector(stopLoadingComplete)];
                     }];
}

- (void)stopLoadingComplete {
    // Reset the header
    refreshLabel.text = self.textPull;
    refreshArrow.hidden = NO;
    [refreshSpinner stopAnimating];
}

- (void)refresh {
    // This is just a demo. Override this method with your custom reload action.
    // Don't forget to call stopLoading at the end.
    [self getLatestTweets];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    self.mainTable = nil;
    self.getTweetInProgress = nil;
    self.noAdvisory = nil;
}

- (void)dealloc{
    self.mainTable = nil;
    self.getTweetInProgress = nil;
    self.noAdvisory = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if([[[UIDevice currentDevice] systemVersion] intValue] >= 7){
        [self.mainTable setFrame:CGRectMake(self.mainTable.frame.origin.x,
                                            self.mainTable.frame.origin.y+UI_STATUS_BAR_HEIGHT,
                                            self.mainTable.frame.size.width,
                                            self.mainTable.frame.size.height)];
    }
    logEvent(FLURRY_ADVISORIES_APPEAR, nil, nil, nil, nil, nil, nil, nil, nil);
   [self startProcessForGettingTweets]; 
    mainTable.delegate = self;
    mainTable.dataSource = self;
    if([nc_AppDelegate sharedInstance].isNotificationsButtonClicked){
        [self getAdvisoryData];
        [self hideTabBar];
        [nc_AppDelegate sharedInstance].isTwitterView = YES;
    }
}

- (void) viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    if([[[UIDevice currentDevice] systemVersion] intValue] >= 7){
        [self.mainTable setFrame:CGRectMake(self.mainTable.frame.origin.x,
                                            self.mainTable.frame.origin.y-UI_STATUS_BAR_HEIGHT,
                                            self.mainTable.frame.size.width,
                                            self.mainTable.frame.size.height)];
    }
    [nc_AppDelegate sharedInstance].isTwitterView = NO;
}
- (NSUInteger) supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL) shouldAutorotate {
    return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [arrayTweet count]*2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    @try {
        NSString *cellIdentifier = TABLE_CELL;
        UILabel *labelTime;
        int twitterTableCellWidth = tableView.frame.size.width - TWITTER_TABLE_CELL_TEXT_BORDER;
        
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        int mostRecentCellWidth = cell.frame.size.width - ROUTE_DETAILS_TABLE_CELL_TEXT_BORDER;
        if (!cell || mostRecentCellWidth != twitterTableCellWidth) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
        
        if ([cell.contentView subviews]){
            for (UIView *subview in [cell.contentView subviews]) {
                [subview removeFromSuperview];
            }
        }
         cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if(indexPath.row % 2 == 0){
            id key = [arrayTweet objectAtIndex:indexPath.row/2];
            NSString *tweetDetail = [(NSDictionary*)key objectForKey:TWEET];
            NSArray *tempArray = [tweetDetail componentsSeparatedByString:@":"];
            
            NSString *tweetTime =  [(NSDictionary*)key objectForKey:TWEET_TIME];
            NSTimeInterval seconds = [tweetTime doubleValue]/1000;
            NSDate *epochNSDate = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
            NSDateFormatter *detailsTimeFormatter = [[NSDateFormatter alloc] init];
            [detailsTimeFormatter setTimeStyle:NSDateFormatterShortStyle];
            
            UILabel *lblTextLabel = [[UILabel alloc] init];
            [lblTextLabel setFrame:CGRectMake(70, 10, 290, 30)];
            [lblTextLabel setFont:[UIFont boldSystemFontOfSize:MEDIUM_FONT_SIZE]];
            [lblTextLabel setText:[tempArray objectAtIndex:0]];
            [lblTextLabel setTextColor:[UIColor whiteColor]];
            [lblTextLabel setBackgroundColor:[UIColor clearColor]];
            [cell.contentView addSubview:lblTextLabel];
            
            NSMutableString *strTweet = [[NSMutableString alloc] init];
            for(int i = 1; i < [tempArray count]; i++){
                NSString *tweetText = [[NSString alloc] initWithString:[tempArray objectAtIndex:i]];
                if ([tweetText rangeOfString:@"http"].location != NSNotFound) {
                    tweetText = [NSString stringWithFormat:@"%@:",tweetText];
                }
                [strTweet appendString:tweetText];
            }
            UITextView *uiTextView=[[UITextView alloc] init];
            
            CGRect stringRect = [strTweet
                                   boundingRectWithSize:CGSizeMake(twitterTableCellWidth, CGFLOAT_MAX)
                                   options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                   attributes:[NSDictionary dictionaryWithObject:[UIFont MEDIUM_LARGE_FONT] forKey:NSFontAttributeName]
                                   context:drawingContext];
            [uiTextView setFrame:CGRectMake(70, 28, twitterTableCellWidth, ceil(stringRect.size.height) + TWITTER_TABLE_CELL_HEIGHT_BUFFER)];
            uiTextView.font = [UIFont MEDIUM_LARGE_FONT];
            uiTextView.text = strTweet;
            uiTextView.textColor = [UIColor whiteColor];
            uiTextView.editable = NO;
            uiTextView.dataDetectorTypes = UIDataDetectorTypeLink;
            uiTextView.scrollEnabled = NO;
            uiTextView.backgroundColor = [UIColor clearColor];
            [cell.contentView addSubview:uiTextView];
            
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.detailTextLabel.numberOfLines= MAXLINE_TAG;
            cell.detailTextLabel.textColor = [UIColor colorWithRed:98.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0];
            
            labelTime = (UILabel *)[cell viewWithTag:MAXLINE_TAG];
            CGRect   lbl3Frame = CGRectMake(210,3, 73, 25);
            labelTime = [[UILabel alloc] initWithFrame:lbl3Frame];
            labelTime.tag = MAXLINE_TAG;
            labelTime.backgroundColor = [UIColor clearColor];
            [cell.contentView addSubview:labelTime];
            labelTime.text = [[detailsTimeFormatter stringFromDate:epochNSDate] lowercaseString];
            [labelTime setFont:[UIFont boldSystemFontOfSize:MEDIUM_FONT_SIZE]];
            [labelTime setTextColor:[UIColor whiteColor]];
            
            // DE-270 Fixed
            UIImage *image = getAgencyIcon([key objectForKey:TWEET_SOURCE]);
            if(image)
                cell.imageView.image =image;
            else
                cell.imageView.image = [UIImage imageNamed:CALTRAIN_IMG];
            cell.imageView.layer.cornerRadius = CORNER_RADIUS_MEDIUM;
            cell.imageView.layer.masksToBounds = YES;
            [cell setBackgroundColor:[UIColor colorWithRed:96.0/255.0 green:96.0/255.0 blue:96.0/255.0 alpha:1.0]];
        }
        else{
            UIImage *separatorImage = [UIImage imageNamed:@"separater@2x.png"];
            UIImageView *imgView = [[UIImageView alloc] initWithImage:separatorImage];
            [imgView setFrame:CGRectMake(0,0,separatorImage.size.width, separatorImage.size.height)];
            [cell.contentView addSubview:imgView];
            [cell setBackgroundColor:[UIColor clearColor]];
        }
        return cell;
    }
    @catch (NSException *exception) {
        logException(@"twitterViewController -> cellForRowAtIndexPath", @"", exception);
    }
}


- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row % 2 != 0){
        return 2;
    }
    else if([arrayTweet count] > indexPath.row/2){
        int twitterTableCellWidth = aTableView.frame.size.width - TWITTER_TABLE_CELL_TEXT_BORDER;
        id key = [arrayTweet objectAtIndex:indexPath.row/2];
        NSString *tweetDetail = [(NSDictionary*)key objectForKey:TWEET];
        CGRect labelRect = [tweetDetail
                             boundingRectWithSize:CGSizeMake(twitterTableCellWidth, CGFLOAT_MAX)
                             options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                             attributes:[NSDictionary dictionaryWithObject:[UIFont MEDIUM_LARGE_FONT] forKey:NSFontAttributeName]
                             context:drawingContext];
        return ceil(labelRect.size.height) + TWITTER_TABLE_CELL_HEIGHT_BUFFER;
    }
    return 50;
}

#pragma mark reloadNewTweets request Response
-(void)getLatestTweets 
{
    // DE-196 Fixed
    if([[nc_AppDelegate sharedInstance] isNetworkConnectionLive]){
        noAdvisory.text = @"There are no advisories at this time. Everything appears to be running normally.";
        [self startProcessForGettingTweets];
        NSString *latestTweetTime = @"0";
        RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
        client.cachePolicy = RKRequestCachePolicyNone;
        [RKClient setSharedClient:client];
        if([arrayTweet count] > 0){
            id key = [arrayTweet objectAtIndex:0];
            NSString *tweetTime =  [(NSDictionary*)key objectForKey:TWEET_TIME];
            
            if (tweetTime == NULL) {
                tweetTime = latestTweetTime;
            }
            NSString *strAgencyIDs = [[nc_AppDelegate sharedInstance] getAgencyIdsString];
            if(strAgencyIDs.length > 0){
                NSDictionary *dict = [NSDictionary dictionaryWithKeysAndObjects:
                                      LAST_TWEET_TIME,tweetTime,
                                      DEVICE_TOKEN, [[nc_AppDelegate sharedInstance] deviceTokenString],APPLICATION_TYPE,[[nc_AppDelegate sharedInstance] getAppTypeFromBundleId],AGENCY_IDS,strAgencyIDs,APPLICATION_VERSION,[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"],
                                      nil];
                NSString *req = [LATEST_TWEETS_REQ appendQueryParams:dict];
                [[RKClient sharedClient]  get:req delegate:self];
                [[nc_AppDelegate sharedInstance] updateBadge:0];
            }
            else{
                [arrayTweet removeAllObjects];
                [mainTable reloadData];
                //[[nc_AppDelegate sharedInstance] updateBadge:0];
            }
           
        }
    }
    else{
        if([arrayTweet count] != 0){
            logEvent(FLURRY_ALERT_NO_NETWORK, FLURRY_ALERT_LOCATION, @"twitterViewController -> getLatestTweets", nil, nil, nil, nil, nil, nil);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_TITLE message:NO_NETWORK_ALERT delegate:self cancelButtonTitle:nil otherButtonTitles:OK_BUTTON_TITLE, nil];
            [alert show];
        }
        else{
            [self stopLoading];
            noAdvisory.text = @"No advisories available.  Unable to connect to server.  Please try again when you have network connectivity";
        }
    }
}
      
- (void)request:(RKRequest*)request didLoadResponse:(RKResponse*)response {
    NSString *strResourcePath = request.resourcePath;
    RKJSONParserJSONKit* rkTwitDataParser = [RKJSONParserJSONKit new];
    @try {
        if ([request isGET]) {
            if ([strResourcePath isEqualToString:strAllAdvisories]) {
                isTwitterLiveData = false;
                NIMLOG_TWITTER1(@"Twitter response %@", [response bodyAsString]);
                id  res = [rkTwitDataParser objectFromString:[response bodyAsString] error:nil];
                if(!res)
                    [noAdvisory setHidden:NO];
                [self setTwitterLiveData:res];
                [[nc_AppDelegate sharedInstance].twitterCount setHidden:YES];
            } else {
                NIMLOG_TWITTER1(@"latest tweets: %@", [response bodyAsString]);
                id  res = [rkTwitDataParser objectFromString:[response bodyAsString] error:nil];
                NSNumber *respCode = [(NSDictionary*)res objectForKey:ERROR_CODE];
                int tc = [[(NSDictionary*)res objectForKey:TWIT_COUNT] intValue];
                if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
                    if(tc > 0){
                        NSMutableArray *arrayLatestTweet = [(NSDictionary*)res objectForKey:TWEET]; 
                        NSMutableArray *tempArray = [[NSMutableArray alloc] initWithArray:arrayTweet];
                        [arrayTweet removeAllObjects];
                        [arrayTweet addObjectsFromArray:arrayLatestTweet];
                        [arrayTweet addObjectsFromArray:tempArray];
                        [self stopLoading];
                        [mainTable reloadData]; 
                    }
                }
                else {
                    [mainTable reloadData];
                }
             [self stopProcessForGettingTweets];
            }
            
        }

    }
    @catch (NSException *exception) {
        logException(@"twitterViewController -> didLoadResponse", @"", exception);
    }

}

-(void)setTwitterLiveData:(id)tweetData
{
    twitterData = tweetData;
    NSNumber *respCode = [(NSDictionary*)twitterData objectForKey:ERROR_CODE];
    
    if ([respCode intValue] == RESPONSE_SUCCESSFULL) {
        // DE-173 Fixed
        [arrayTweet removeAllObjects];
        [arrayTweet addObjectsFromArray:[(NSDictionary*)twitterData objectForKey:TWEET]]; 
        [mainTable reloadData];
    } else if ([respCode intValue] == RESPONSE_DATA_NOT_EXIST) {
      [arrayTweet removeAllObjects]; 
        [mainTable reloadData];
    }
    [self stopProcessForGettingTweets];
}

// convert into twitter calaculate time
-(NSString *)stringForTimeIntervalSinceCreated:(NSDate *)dateTime serverTime:(NSDate *)serverDateTime{
    NSInteger tweetMin;
    NSInteger tweethour;
    NSInteger tweetday;
    NSInteger day;
    NSInteger interval = abs((NSInteger)[dateTime timeIntervalSinceDate:serverDateTime]);
    if(interval >= 86400)
    {
        tweetday  = interval/86400;
        day = interval%86400;
        if(day!=0)
        {
            if(day>=3600){
                //HourInterval=DayModules/3600;
                return [NSString stringWithFormat:@"%id", tweetday];
            }
            else {
                if(day>=60){
                    //MinInterval=DayModules/60;
                    return [NSString stringWithFormat:@"%id", tweetday];
                }
                else {
                    return [NSString stringWithFormat:@"%id", tweetday];
                }
            }
        }
        else 
        {
            return [NSString stringWithFormat:@"%id", tweetday];
        }
    }
    else{
        if(interval>=3600) {
            tweethour= interval/3600;
            return [NSString stringWithFormat:@"%ih", tweethour];
        } else if(interval>=60) {
            tweetMin = interval/60;
            return [NSString stringWithFormat:@"%im", tweetMin];
        }
        else{
            return [NSString stringWithFormat:@"%is", interval];
        }
    }
}

-(void)getAdvisoryData
{
    // DE-196 Fixed
    if([[nc_AppDelegate sharedInstance] isNetworkConnectionLive]){
        @try {
            noAdvisory.text = @"There are no advisories at this time. Everything appears to be running normally.";
            [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
            [[self.tabBarController.tabBar.items objectAtIndex:1] setBadgeValue:nil];
            [[nc_AppDelegate sharedInstance] updateBadge:0];
            RKClient *client = [RKClient clientWithBaseURL:TRIP_PROCESS_URL];
            client.cachePolicy = RKRequestCachePolicyNone;
            [RKClient setSharedClient:client];
            isTwitterLiveData = TRUE;
            NSString *strAgencyIDs = [[nc_AppDelegate sharedInstance] getAgencyIdsString];
            if(strAgencyIDs.length > 0){
                NSDictionary *params = [NSDictionary dictionaryWithKeysAndObjects:
                                        DEVICE_TOKEN, [[nc_AppDelegate sharedInstance] deviceTokenString],APPLICATION_TYPE,[[nc_AppDelegate sharedInstance] getAppTypeFromBundleId],AGENCY_IDS,strAgencyIDs,APPLICATION_VERSION,[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"],
                                        nil];
                NSString *allAdvisories = [ALL_TWEETS_REQ appendQueryParams:params];
                strAllAdvisories = allAdvisories;
                [[RKClient sharedClient]  get:allAdvisories delegate:self];
            }
            else{
                [arrayTweet removeAllObjects];
                [mainTable reloadData];
                //[[nc_AppDelegate sharedInstance] updateBadge:0];
            }
        }
        @catch (NSException *exception) {
            logException(@"twitterViewController -> getAdvisoryData", @"", exception);
        }
    }
    else{
        if([arrayTweet count] != 0){
            logEvent(FLURRY_ALERT_NO_NETWORK, FLURRY_ALERT_LOCATION, @"twitterViewController -> getAdvisoryData", nil, nil, nil, nil, nil, nil);
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:APP_TITLE message:NO_NETWORK_ALERT delegate:self cancelButtonTitle:nil otherButtonTitles:OK_BUTTON_TITLE, nil];
            [alert show];
        }
        else{
            noAdvisory.text = @"No advisories available.  Unable to connect to server.  Please try again when you have network connectivity";
        }
    }
}

#pragma mark UIUpdation
// after and before request these methods will be called 
-(void)startProcessForGettingTweets
{
    [noAdvisory setHidden:YES];
    [getTweetInProgress startAnimating]; 
    [self timerAction];
}
-(void)stopProcessForGettingTweets
{
    if ([arrayTweet count] == 0) {
        [noAdvisory setHidden:NO];
    } else {
        [noAdvisory setHidden:YES];
    }
    [getTweetInProgress stopAnimating];
    [getTweetInProgress setHidesWhenStopped:TRUE];
    [self stopLoading];
}
-(void)timerAction
{
    timerForStopProcees = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(stopProcessForGettingTweets) userInfo:nil repeats:NO];
}

- (void) backToTwitterView{
    [self.navigationController.navigationBar setHidden:YES];
    RXCustomTabBar *rxCustomTabbar = (RXCustomTabBar *)[nc_AppDelegate sharedInstance].tabBarController;
    [rxCustomTabbar showAllElements];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)openUrl:(NSURL *)url {
    [self.navigationController.navigationBar setHidden:NO];
    UIViewController *webViewController = [[UIViewController alloc] init];
    [webViewController.view addSubview:[NMWebView instance]];

    if([[[UIDevice currentDevice] systemVersion] intValue]>=7){
        webViewController.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20];
    [[NMWebView instance] loadRequest:request];
    [NMWebView instance].delegate = self;
    [self hideTabBar];
    RXCustomTabBar *rxCustomTabbar = (RXCustomTabBar *)[nc_AppDelegate sharedInstance].tabBarController;
    [rxCustomTabbar hideAllElements];
    
    UIButton * btnGoToNimbler = [[UIButton alloc] initWithFrame:CGRectMake(5,6,65,34)];
    [btnGoToNimbler addTarget:self action:@selector(backToTwitterView) forControlEvents:UIControlEventTouchUpInside];
    [btnGoToNimbler setBackgroundImage:[UIImage imageNamed:@"back.png"] forState:UIControlStateNormal];
    
    UINavigationController *controller = [[UINavigationController alloc] initWithRootViewController:webViewController];
    [controller.navigationBar addSubview:btnGoToNimbler];
    
    if([controller.navigationBar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
        [controller.navigationBar setBackgroundImage:returnNavigationBarBackgroundImage() forBarMetrics:UIBarMetricsDefault];
    }
    else {
        [controller.navigationBar insertSubview:[[UIImageView alloc] initWithImage:returnNavigationBarBackgroundImage()] aboveSubview:self.navigationController.navigationBar];
    }
    
    [self presentViewController:controller animated:YES completion:nil];
}


-(void)webViewDidStartLoad:(UIWebView *)webView{
    if(!activityIndicatorView){
        activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(145, 168, 37, 37)];
        activityIndicatorView.center = self.view.center;
        [activityIndicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
        [webView addSubview:activityIndicatorView];
    }
    [activityIndicatorView startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    [activityIndicatorView stopAnimating];
}

- (void) hideTabBar {
    //[[nc_AppDelegate sharedInstance].twitterCount setHidden:YES];
    
    for(UIView *view in self.tabBarController.view.subviews)
    {
        if([view isKindOfClass:[UITabBar class]])
        {
            [view setHidden:YES];    // JC 1/31/2015: set hidden extra gray UITabBar at bottom of screen
        }
    }
}

@end