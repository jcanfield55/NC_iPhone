//
//  SettingDetailViewController.m
//  Nimbler Caltrain
//
//  Created by macmini on 21/11/12.
//  Copyright (c) 2012 Network Commuting. All rights reserved.
//

#import "SettingDetailViewController.h"
#import "UserPreferance.h"
#import "nc_AppDelegate.h"

@implementation SettingDetailViewController

@synthesize tblDetailSetting;
@synthesize nSettingRow;
@synthesize switchUrgentNotification;
@synthesize switchStandardNotification;
@synthesize lblMaximumBikeDistance;
@synthesize sliderMaximumBikeDistance;
@synthesize lblPreferenceFastVsSafe;
@synthesize sliderPreferenceFastVsSafe;
@synthesize lblPreferenceFastVsFlat;
@synthesize sliderPreferenceFastVsFlat;
@synthesize lblCurrentBikeDistance;
@synthesize lblMinBikeDistance;
@synthesize lblMaxBikeDistance;
@synthesize lblQuickWithHills;
@synthesize lblGoAroundHills;
@synthesize lblQuickWithAnyStreet;
@synthesize lblBikeFriendlyStreet;
@synthesize isSettingDetail;
@synthesize settingDetailDelegate;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        UserPreferance* userPrefs = [UserPreferance userPreferance];
        switchUrgentNotification = [[UISwitch alloc] init];
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [switchUrgentNotification setOnTintColor:[UIColor lightGrayColor]];
        }
        [switchUrgentNotification setOn:[userPrefs urgentNotificationSound]];

        switchStandardNotification = [[UISwitch alloc] init];
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [switchStandardNotification setOnTintColor:[UIColor lightGrayColor]];
        }
        [switchStandardNotification setOn:[userPrefs standardNotificationSound]];
        
        lblMaximumBikeDistance=[[UILabel alloc] initWithFrame:CGRectMake(DETAIL_SETTING_MAIN_LABEL_XPOS,DETAIL_SETTING_MAIN_LABEL_YPOS, DETAIL_SETTING_MAIN_LABEL_WIDTH, DETAIL_SETTING_MAIN_LABEL_HEIGHT)];
        [lblMaximumBikeDistance setTextColor:[UIColor NIMBLER_RED_FONT_COLOR]];
        lblMaximumBikeDistance.backgroundColor =[UIColor clearColor];
        lblMaximumBikeDistance.adjustsFontSizeToFitWidth=YES;
        lblMaximumBikeDistance.text=MAXIMUM_BIKE_DISTANCE;
        [lblMaximumBikeDistance setFont:[UIFont MEDIUM_LARGE_BOLD_FONT]];
        
        sliderMaximumBikeDistance = [[UISlider alloc] initWithFrame:CGRectMake(SLIDERS_XOPS,SLIDERS_YPOS,SLIDERS_WIDTH,SLIDERS_HEIGHT)];
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [sliderMaximumBikeDistance
             setMinimumTrackTintColor:[UIColor lightGrayColor]];
        }
        [sliderMaximumBikeDistance setMinimumValue:MAX_BIKE_DISTANCE_MIN_VALUE];
        [sliderMaximumBikeDistance setMaximumValue:MAX_BIKE_DISTANCE_MAX_VALUE];
        [sliderMaximumBikeDistance setValue:[userPrefs bikeDistance]];

        [sliderMaximumBikeDistance addTarget:self action:@selector(maxBikeDistanceValueChanged:) forControlEvents:UIControlEventTouchUpInside];
        
        
        lblPreferenceFastVsSafe=[[UILabel alloc] initWithFrame:CGRectMake(DETAIL_SETTING_MAIN_LABEL_XPOS,DETAIL_SETTING_MAIN_LABEL_YPOS, DETAIL_SETTING_MAIN_LABEL_WIDTH, DETAIL_SETTING_MAIN_LABEL_HEIGHT)];
        [lblPreferenceFastVsSafe setTextColor:[UIColor NIMBLER_RED_FONT_COLOR]];
        lblPreferenceFastVsSafe.backgroundColor =[UIColor clearColor];
        lblPreferenceFastVsSafe.adjustsFontSizeToFitWidth=YES;
        lblPreferenceFastVsSafe.text=PREFERENCE_FAST_VS_SAFE;
        [lblPreferenceFastVsSafe setFont:[UIFont MEDIUM_LARGE_BOLD_FONT]];
        
        sliderPreferenceFastVsSafe = [[UISlider alloc] initWithFrame:CGRectMake(SLIDERS_XOPS, SLIDERS_YPOS1, SLIDERS_WIDTH,SLIDERS_HEIGHT)];
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [sliderPreferenceFastVsSafe
             setMinimumTrackTintColor:[UIColor lightGrayColor]];
        }
        [sliderPreferenceFastVsSafe setMinimumValue:BIKE_PREFERENCE_MIN_VALUE];
        [sliderPreferenceFastVsSafe setMaximumValue:BIKE_PREFERENCE_MAX_VALUE];
        [sliderPreferenceFastVsSafe setValue:[userPrefs fastVsSafe]];
        
        lblPreferenceFastVsFlat=[[UILabel alloc] initWithFrame:CGRectMake(DETAIL_SETTING_MAIN_LABEL_XPOS,DETAIL_SETTING_MAIN_LABEL_YPOS, DETAIL_SETTING_MAIN_LABEL_WIDTH, DETAIL_SETTING_MAIN_LABEL_HEIGHT)];
        [lblPreferenceFastVsFlat setTextColor:[UIColor NIMBLER_RED_FONT_COLOR]];
        lblPreferenceFastVsFlat.backgroundColor =[UIColor clearColor];
        lblPreferenceFastVsFlat.adjustsFontSizeToFitWidth=YES;
        lblPreferenceFastVsFlat.text=PREFERENCE_FAST_VS_FLAT;
        [lblPreferenceFastVsFlat setFont:[UIFont MEDIUM_LARGE_BOLD_FONT]];
        
        sliderPreferenceFastVsFlat = [[UISlider alloc] initWithFrame:CGRectMake(SLIDERS_XOPS, SLIDERS_YPOS1, SLIDERS_WIDTH,SLIDERS_HEIGHT)];
        if([[[UIDevice currentDevice] systemVersion] intValue] >= 5){
            [sliderPreferenceFastVsFlat
             setMinimumTrackTintColor:[UIColor lightGrayColor]];
        }
        [sliderPreferenceFastVsFlat setMinimumValue:BIKE_PREFERENCE_MIN_VALUE];
        [sliderPreferenceFastVsFlat setMaximumValue:BIKE_PREFERENCE_MAX_VALUE];
        [sliderPreferenceFastVsFlat setValue:[userPrefs fastVsFlat]];

        lblCurrentBikeDistance = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, LABEL_MAXWALK_Distance_WIDTH, LABEL_MAXWALK_Distance_HEIGHT)] ;
        [lblCurrentBikeDistance setTextColor:[UIColor redColor]];
        [lblCurrentBikeDistance setBackgroundColor:[UIColor clearColor]];
        [lblCurrentBikeDistance setTextAlignment:UITextAlignmentCenter];
        [lblCurrentBikeDistance setFont:[UIFont MEDIUM_FONT]];
        
        lblMinBikeDistance=[[UILabel alloc] initWithFrame:CGRectMake(BIKE_DISTANCE_LABEL_XPOS,BIKE_DISTANCE_LABEL_YPOS, BIKE_DISTANCE_LABEL_WIDTH, BIKE_DISTANCE_LABEL_HEIGHT)];
        [lblMinBikeDistance setTextColor:[UIColor GRAY_FONT_COLOR]];
        lblMinBikeDistance.backgroundColor =[UIColor clearColor];
        lblMinBikeDistance.adjustsFontSizeToFitWidth=YES;
        lblMinBikeDistance.text=[NSString stringWithFormat:@"%d",MAX_BIKE_DISTANCE_MIN_VALUE];
        [lblMinBikeDistance setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        lblMaxBikeDistance=[[UILabel alloc] initWithFrame:CGRectMake(BIKE_DISTANCE_LABEL_XPOS1,BIKE_DISTANCE_LABEL_YPOS, BIKE_DISTANCE_LABEL_WIDTH, BIKE_DISTANCE_LABEL_HEIGHT)];
        [lblMaxBikeDistance setTextColor:[UIColor GRAY_FONT_COLOR]];
        lblMaxBikeDistance.backgroundColor =[UIColor clearColor];
        lblMaxBikeDistance.adjustsFontSizeToFitWidth=YES;
        lblMaxBikeDistance.text=[NSString stringWithFormat:@"%d",MAX_BIKE_DISTANCE_MAX_VALUE];;
        [lblMaxBikeDistance setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        lblQuickWithHills=[[UILabel alloc] initWithFrame:CGRectMake(BIKE_PREFERENCE_LABEL_XPOS,BIKE_PREFERENCE_LABEL_YPOS,BIKE_PREFERENCE_LABEL_WIDTH,BIKE_PREFERENCE_LABEL_HEIGHT)];
        [lblQuickWithHills setTextColor:[UIColor GRAY_FONT_COLOR]];
        lblQuickWithHills.backgroundColor =[UIColor clearColor];
        lblQuickWithHills.adjustsFontSizeToFitWidth=YES;
        lblQuickWithHills.text= QUICK_WITH_HILLS;
        [lblQuickWithHills setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        lblGoAroundHills=[[UILabel alloc] initWithFrame:CGRectMake(BIKE_PREFERENCE_LABEL_XPOS1,BIKE_PREFERENCE_LABEL_YPOS,BIKE_PREFERENCE_LABEL_WIDTH,BIKE_PREFERENCE_LABEL_HEIGHT)];
        [lblGoAroundHills setTextColor:[UIColor GRAY_FONT_COLOR]];
        lblGoAroundHills.backgroundColor =[UIColor clearColor];
        lblGoAroundHills.adjustsFontSizeToFitWidth=YES;
        lblGoAroundHills.text= GO_AROUNG_HILLS;
        [lblGoAroundHills setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        lblQuickWithAnyStreet=[[UILabel alloc] initWithFrame:CGRectMake(BIKE_PREFERENCE_LABEL_XPOS,BIKE_PREFERENCE_LABEL_YPOS,BIKE_PREFERENCE_LABEL_WIDTH,BIKE_PREFERENCE_LABEL_HEIGHT)];
        [lblQuickWithAnyStreet setTextColor:[UIColor GRAY_FONT_COLOR]];
        lblQuickWithAnyStreet.backgroundColor =[UIColor clearColor];
        lblQuickWithAnyStreet.adjustsFontSizeToFitWidth=YES;
        lblQuickWithAnyStreet.text= QUICK_WITH_ANY_STREET;
        [lblQuickWithAnyStreet setFont:[UIFont SMALL_OBLIQUE_FONT]];
        
        lblBikeFriendlyStreet=[[UILabel alloc] initWithFrame:CGRectMake(BIKE_PREFERENCE_LABEL_XPOS1,BIKE_PREFERENCE_LABEL_YPOS,BIKE_PREFERENCE_LABEL_WIDTH,BIKE_PREFERENCE_LABEL_HEIGHT)];
        [lblBikeFriendlyStreet setTextColor:[UIColor GRAY_FONT_COLOR]];
        lblBikeFriendlyStreet.backgroundColor =[UIColor clearColor];
        lblBikeFriendlyStreet.adjustsFontSizeToFitWidth=YES;
        lblBikeFriendlyStreet.text= BIKE_FRIENDLY_STREET;
        [lblBikeFriendlyStreet setFont:[UIFont SMALL_OBLIQUE_FONT]];
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    UILabel* lblNavigationTitle=[[UILabel alloc] initWithFrame:CGRectMake(0,0, NAVIGATION_LABEL_WIDTH, NAVIGATION_LABEL_HEIGHT)];
    [lblNavigationTitle setFont:[UIFont LARGE_BOLD_FONT]];
    lblNavigationTitle.textColor= [UIColor NAVIGATION_TITLE_COLOR];
    [lblNavigationTitle setTextAlignment:UITextAlignmentCenter];
    lblNavigationTitle.backgroundColor =[UIColor clearColor];
    lblNavigationTitle.adjustsFontSizeToFitWidth=YES;
    
    if(nSettingRow == 0){
        lblNavigationTitle.text = ADVISORY_CHOICES;
    }
    else if(nSettingRow == 3){
        lblNavigationTitle.text = NOTIFICATION_SOUND;
    }
    else if(nSettingRow == 4){
        lblNavigationTitle.text = NOTIFICATION_TIMING;
    }
    else if(nSettingRow == 5){
        lblNavigationTitle.text = TRANSIT_MODE;
    }
    else if(nSettingRow == 7){
        lblNavigationTitle.text = BIKE_PREFERENCES;
    }
    self.navigationItem.titleView=lblNavigationTitle;
    UIImage* btnImage = [UIImage imageNamed:@"img_Settings.png"];
    UIButton * btnGoToItinerary = [[UIButton alloc] initWithFrame:CGRectMake(0,0,65, 34)];
    [btnGoToItinerary addTarget:self action:@selector(popOutToSettings) forControlEvents:UIControlEventTouchUpInside];
    [btnGoToItinerary setBackgroundImage:btnImage forState:UIControlStateNormal];
    UIBarButtonItem *backToItinerary = [[UIBarButtonItem alloc] initWithCustomView:btnGoToItinerary];
    self.navigationItem.leftBarButtonItem = backToItinerary;
    
    self.tblDetailSetting.delegate = self;
    self.tblDetailSetting.dataSource = self;
    [self.tblDetailSetting setBackgroundView:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"img_background.png"]]];
}
- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [nc_AppDelegate sharedInstance].isSettingDetailView = YES;
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [nc_AppDelegate sharedInstance].isSettingDetailView = NO;
    isSettingDetail = NO;
    UserPreferance* userPrefs = [UserPreferance userPreferance];
    if(nSettingRow == 3){
        userPrefs.urgentNotificationSound = switchUrgentNotification.isOn;
        userPrefs.standardNotificationSound = switchStandardNotification.isOn;
    }
    if(nSettingRow == 7){
        userPrefs.bikeDistance = sliderMaximumBikeDistance.value;
        userPrefs.fastVsSafe = sliderPreferenceFastVsSafe.value;
        userPrefs.fastVsFlat = sliderPreferenceFastVsFlat.value;
    }
    [settingDetailDelegate updateSetting];
    // if(![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:CALTRAIN_BUNDLE_IDENTIFIER]){
       if(!userPrefs.sfMuniAdvisories && !userPrefs.bartAdvisories && !userPrefs.acTransitAdvisories && !userPrefs.caltrainAdvisories) {
             [[nc_AppDelegate sharedInstance] updateBadge:0];
        // }
     }
}
- (void)popOutToSettings{
    [self.navigationController popViewControllerAnimated:YES];
}
// Methods Added to Get The Position of Thumb
- (float)mapValueInIntervalInPercents: (float)value min: (float)minimum max: (float)maximum{
    return (100 / (maximum - minimum)) * value -
    (100 * minimum)/(maximum - minimum);
}

- (float)xPositionFromSliderValue:(UISlider *)aSlider{
    float percent = [self mapValueInIntervalInPercents: aSlider.value
                                                   min: aSlider.minimumValue
                                                   max: aSlider.maximumValue] / 100.0;
    
    return percent * aSlider.frame.size.width -
    percent * aSlider.currentThumbImage.size.width +
    aSlider.currentThumbImage.size.width / 2;
}

-(IBAction)maxBikeDistanceValueChanged:(UISlider *)sender
{
    [sliderMaximumBikeDistance setValue:sliderMaximumBikeDistance.value];
    [sliderMaximumBikeDistance setSelected:YES];
    float sliderXPOS = [self xPositionFromSliderValue:sliderMaximumBikeDistance];
    lblCurrentBikeDistance.center = CGPointMake(sliderXPOS, -10);
    lblCurrentBikeDistance.text = [NSString stringWithFormat:@"%0.0f", sliderMaximumBikeDistance.value];
}

//------------------------------------------------------------------------

#pragma mark
#pragma mark UITableView delegate and datasource methods

//-------------------------------------------------------------------------

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    int nRowCount;
    if(nSettingRow == 0){
        nRowCount = 4;
    }
    else if(nSettingRow == 3){
        nRowCount = 2;
    }
    else if(nSettingRow == 4){
        nRowCount = 5;
    }
    else if(nSettingRow == 5){
        nRowCount = 3;
    }
    else if(nSettingRow == 7){
        nRowCount = 3;
    }
    return nRowCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    int nRowHeight;
    if(nSettingRow == 7){
        nRowHeight = 80;
    }
    else{
        nRowHeight = 40;
    }
    return nRowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellIdentifier = [NSString stringWithFormat:@"%d",indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell = nil;
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell.textLabel setFont:[UIFont MEDIUM_LARGE_BOLD_FONT]];
    [cell.textLabel setTextColor:[UIColor NIMBLER_RED_FONT_COLOR]];
    UserPreferance* userPrefs = [UserPreferance userPreferance];
    if(nSettingRow == 0){
        if(indexPath.row == 0){
            cell.textLabel.text = SFMUNI_ADVISORIES;
            cell.accessoryType = (userPrefs.sfMuniAdvisories ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
        }
        else if(indexPath.row == 1){
            cell.textLabel.text = BART_ADVISORIES;
            cell.accessoryType = (userPrefs.bartAdvisories ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
        }
        else if(indexPath.row == 2){
            cell.textLabel.text = ACTRANSIT_ADVISORIES;
            cell.accessoryType = (userPrefs.acTransitAdvisories ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
        }
        else if(indexPath.row == 3){
            cell.textLabel.text = CALTRAIN_ADVISORIES;
            cell.accessoryType = (userPrefs.caltrainAdvisories ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
        }
    }
    else if(nSettingRow == 3){
        if(indexPath.row == 0){
            cell.textLabel.text = URGENT_NOTIFICATIONS;
            [cell setAccessoryView:switchUrgentNotification];
        }
        else if(indexPath.row == 1){
            cell.textLabel.text = STANDARD_NOTIFICATIONS;
            [cell setAccessoryView:switchStandardNotification];
        }
    }
    else if(nSettingRow == 4){
        if(indexPath.row == 0){
            cell.textLabel.text = WEEKDAY_MORNING;
            cell.accessoryType = (userPrefs.notificationMorning ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
        }
        else if(indexPath.row == 1){
            cell.textLabel.text = WEEKDAY_MIDDAY;
            cell.accessoryType = (userPrefs.notificationMidday ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
        }
        else if(indexPath.row == 2){
            cell.textLabel.text = WEEKDAY_EVENING_PEAK;
            cell.accessoryType = (userPrefs.notificationEvening ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
        }
        else if(indexPath.row == 3){
            cell.textLabel.text = WEEKDAY_NIGHT;
            cell.accessoryType = (userPrefs.notificationNight ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
        }
        else if(indexPath.row == 4){
            cell.textLabel.text = WEEKENDS;
            cell.accessoryType = (userPrefs.notificationWeekend ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone);
        }
    }
    else if(nSettingRow == 5){
        if(indexPath.row == 0){
            cell.textLabel.text = TRANSIT_ONLY;
            if(userPrefs.transitMode == TRANSIT_MODE_TRANSIT_ONLY){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        else if(indexPath.row == 1){
            cell.textLabel.text = BIKE_ONLY;
            if(userPrefs.transitMode == TRANSIT_MODE_BIKE_ONLY){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
        else if(indexPath.row == 2){
            cell.textLabel.text = BIKE_AND_TRANSIT;
            if(userPrefs.transitMode == TRANSIT_MODE_BIKE_AND_TRANSIT){
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            else{
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        }
    }
    
    else if(nSettingRow == 7){
        if(indexPath.row == 0){
            cell.textLabel.text = nil;
            [cell setAccessoryView:nil];
            UIView* cellView = [cell contentView];
            NSArray* subviews = [cellView subviews];
            if (subviews && [subviews count]>0 && [subviews indexOfObject:sliderMaximumBikeDistance] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:sliderMaximumBikeDistance];
                [sliderMaximumBikeDistance addSubview:lblCurrentBikeDistance];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblMaximumBikeDistance] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblMaximumBikeDistance];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblMinBikeDistance] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblMinBikeDistance];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblMaxBikeDistance] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblMaxBikeDistance];
            }
        }
        else if(indexPath.row == 1){
            cell.textLabel.text = nil;
            [cell setAccessoryView:nil];
            UIView* cellView = [cell contentView];
            NSArray* subviews = [cellView subviews];
            if (subviews && [subviews count]>0 && [subviews indexOfObject:sliderPreferenceFastVsSafe] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:sliderPreferenceFastVsSafe];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblPreferenceFastVsSafe] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblPreferenceFastVsSafe];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblQuickWithHills] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblQuickWithHills];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblGoAroundHills] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblGoAroundHills];
            }
        }
        else if(indexPath.row == 2){
            cell.textLabel.text = nil;
            [cell setAccessoryView:nil];
            UIView* cellView = [cell contentView];
            NSArray* subviews = [cellView subviews];
            if (subviews && [subviews count]>0 && [subviews indexOfObject:sliderPreferenceFastVsFlat] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:sliderPreferenceFastVsFlat];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblPreferenceFastVsFlat] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblPreferenceFastVsFlat];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblQuickWithAnyStreet] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblQuickWithAnyStreet];
            }
            if (subviews && [subviews count]>0 && [subviews indexOfObject:lblBikeFriendlyStreet] != NSNotFound) {
            }
            else{
                [cell.contentView addSubview:lblBikeFriendlyStreet];
            }
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UserPreferance* userPrefs = [UserPreferance userPreferance];
    if(nSettingRow == 0){
        if(indexPath.row == 0){
            if(userPrefs.sfMuniAdvisories){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
                userPrefs.sfMuniAdvisories = false;
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                userPrefs.sfMuniAdvisories = true;
            }
        }
        if(indexPath.row == 1){
            if(userPrefs.bartAdvisories){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
                userPrefs.bartAdvisories = false;
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                userPrefs.bartAdvisories = true;
            }
        }
        if(indexPath.row == 2){
            if(userPrefs.acTransitAdvisories){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
                userPrefs.acTransitAdvisories = false;
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                userPrefs.acTransitAdvisories = true;
            }
        }
        if(indexPath.row == 3){
            if(userPrefs.caltrainAdvisories){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
                userPrefs.caltrainAdvisories = false;
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                userPrefs.caltrainAdvisories = true;
            }
        }
        [self.tblDetailSetting reloadData];
    }
    if(nSettingRow == 4){
        if(indexPath.row == 0){
            if(userPrefs.notificationMorning){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
                userPrefs.notificationMorning = false;
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                userPrefs.notificationMorning = true;
            }
        }
        else if(indexPath.row == 1){
            if(userPrefs.notificationMidday){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
                userPrefs.notificationMidday = false;
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                userPrefs.notificationMidday = true;
            }
        }
        
        else if(indexPath.row == 2){
            if(userPrefs.notificationEvening){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
                userPrefs.notificationEvening = false; 
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                userPrefs.notificationEvening = true;
            }
        }
        else if(indexPath.row == 3){
            if(userPrefs.notificationNight){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
                userPrefs.notificationNight = false;
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                userPrefs.notificationNight = true; 
            }
        }
        else if(indexPath.row == 4){
            if(userPrefs.notificationWeekend){
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryNone;
                userPrefs.notificationWeekend = false; 
            }
            else{
                UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                userPrefs.notificationWeekend = true;
            }
        }
    }
    if(nSettingRow == 5){
        if(indexPath.row == 0){
            userPrefs.transitMode = TRANSIT_MODE_TRANSIT_ONLY;
        }
        else if(indexPath.row == 1){
            userPrefs.transitMode = TRANSIT_MODE_BIKE_ONLY;
        }
        else if(indexPath.row == 2){
            userPrefs.transitMode = TRANSIT_MODE_BIKE_AND_TRANSIT;
        }
         [self.tblDetailSetting reloadData];
    }
}

@end
