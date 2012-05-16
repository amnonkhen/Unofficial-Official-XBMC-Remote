//
//  ViewControllerIPad.m
//  XBMC Remote
//
//  Created by Giovanni Messina on 29/4/12.
//  Copyright (c) 2012 joethefox inc. All rights reserved.
//

#import "ViewControllerIPad.h"
#import "StackScrollViewController.h"
#import "MenuViewController.h"
#import "NowPlaying.h"
#import "mainMenu.h"
#import "GlobalData.h"
#import "AppDelegate.h"
#import "HostManagementViewController.h"

@interface ViewControllerIPad (){
    NSMutableArray *mainMenu;
}
@end

@interface UIViewExt : UIView {} 
@end


@implementation UIViewExt
- (UIView *) hitTest: (CGPoint) pt withEvent: (UIEvent *) event {   
	
	UIView* viewToReturn=nil;
	CGPoint pointToReturn;
	
	UIView* uiRightView = (UIView*)[[self subviews] objectAtIndex:1];
	
	if ([[uiRightView subviews] objectAtIndex:0]) {
		
		UIView* uiStackScrollView = [[uiRightView subviews] objectAtIndex:0];	
		
		if ([[uiStackScrollView subviews] objectAtIndex:1]) {	 
			
			UIView* uiSlideView = [[uiStackScrollView subviews] objectAtIndex:1];	
			
			for (UIView* subView in [uiSlideView subviews]) {
				CGPoint point  = [subView convertPoint:pt fromView:self];
				if ([subView pointInside:point withEvent:event]) {
					viewToReturn = subView;
					pointToReturn = point;
				}
				
			}
		}
		
	}
	
	if(viewToReturn != nil) {
		return [viewToReturn hitTest:pointToReturn withEvent:event];		
	}
	
	return [super hitTest:pt withEvent:event];	
	
}
@end



@implementation ViewControllerIPad

@synthesize mainMenu;
@synthesize menuViewController, stackScrollViewController;
@synthesize nowPlayingController;
@synthesize serverPickerPopover = _serverPickerPopover;
@synthesize hostPickerViewController = _hostPickerViewController;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - InfoView

-(void)infoView{
    
}

#pragma mark - ServerManagement

-(void)selectServerAtIndexPath:(NSIndexPath *)indexPath{
    
    storeServerSelection = indexPath;
    AppDelegate *mainDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDictionary *item = [mainDelegate.arrayServerList objectAtIndex:indexPath.row];
    obj.serverDescription = [item objectForKey:@"serverDescription"];
    obj.serverUser = [item objectForKey:@"serverUser"];
    obj.serverPass = [item objectForKey:@"serverPass"];
    obj.serverIP = [item objectForKey:@"serverIP"];
    obj.serverPort = [item objectForKey:@"serverPort"];
    //[self changeServerStatus:NO infoText:@"No connection"];
}

-(void)checkServer{
    jsonRPC=nil;
    obj=[GlobalData getInstance];  
    if ([obj.serverIP length]==0){
        if (firstRun){
            firstRun=NO;
            
//            if (EXPERIMENTAL_HOST_MANAGEMENT){
//                [self toggleViewToolBar:hostManagementViewController.view AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:FALSE forceOpen:TRUE];
//            }
//            else{
//                [self toggleViewToolBar:settingsView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:FALSE forceOpen:TRUE];
//            }
        }
        return;
    }
    NSString *userPassword=[obj.serverPass isEqualToString:@""] ? @"" : [NSString stringWithFormat:@":%@", obj.serverPass];
    NSString *serverJSON=[NSString stringWithFormat:@"http://%@%@@%@:%@/jsonrpc", obj.serverUser, userPassword, obj.serverIP, obj.serverPort];
    jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:[NSURL URLWithString:serverJSON]];
    
    [jsonRPC 
     callMethod:@"Application.GetProperties" 
     withParameters:checkServerParams
     onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError* error) {
         if (error==nil && methodError==nil){
             if (![AppDelegate instance].serverOnLine){
                 if( [NSJSONSerialization isValidJSONObject:methodResult]){
                     NSDictionary *serverInfo=[methodResult objectForKey:@"version"];
                     NSString *infoTitle=[NSString stringWithFormat:@" XBMC %@.%@-%@", [serverInfo objectForKey:@"major"], [serverInfo objectForKey:@"minor"], [serverInfo objectForKey:@"tag"]];//, [serverInfo objectForKey:@"revision"]
                     [self changeServerStatus:YES infoText:infoTitle];
                     
//                     if (EXPERIMENTAL_HOST_MANAGEMENT){
//                         [self toggleViewToolBar:hostManagementViewController.view AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:TRUE forceOpen:FALSE];
//                         
//                     }
//                     else {
//                         [self toggleViewToolBar:settingsView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:TRUE forceOpen:FALSE];
//                         
//                     }
                     
                     
                 }
                 else{
                     if ([AppDelegate instance].serverOnLine){
                         //                         NSLog(@"mi spengo");
                         [self changeServerStatus:NO infoText:@"No connection"];
                     }
                     if (firstRun){
                         firstRun=NO;
//                         if (EXPERIMENTAL_HOST_MANAGEMENT){
//                             [self toggleViewToolBar:hostManagementViewController.view AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:FALSE forceOpen:TRUE];
//                         }
//                         else{
//                             [self toggleViewToolBar:settingsView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:FALSE forceOpen:TRUE];
//                         }
                     }
                 }
             }
         }
         else {
             //             NSLog(@"ERROR %@ %@",error, methodError);
             if ([AppDelegate instance].serverOnLine){
                 //                 NSLog(@"mi spengo");
                 [self changeServerStatus:NO infoText:@"No connection"];
             }
             if (firstRun){
                 firstRun=NO;
//                 if (EXPERIMENTAL_HOST_MANAGEMENT){
//                     [self toggleViewToolBar:hostManagementViewController.view AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:FALSE forceOpen:TRUE];
//                 }
//                 else {
//                     [self toggleViewToolBar:settingsView AnimDuration:0.3 Alpha:1.0 YPos:0 forceHide:FALSE forceOpen:TRUE];
//                 }
             }
         }
     }];
    jsonRPC=nil;
}

-(void)changeServerStatus:(BOOL)status infoText:(NSString *)infoText{
    if (status==YES){
        [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateNormal];
        [xbmcLogo setImage:nil forState:UIControlStateHighlighted];
        [xbmcLogo setImage:nil forState:UIControlStateSelected];
        [xbmcInfo setTitle:infoText forState:UIControlStateNormal];
        [AppDelegate instance].serverOnLine=YES;
        int n = [menuViewController.tableView numberOfRowsInSection:0];
        for (int i=0;i<n;i++){
            UITableViewCell *cell = [menuViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            if (cell!=nil){
                cell.selectionStyle=UITableViewCellSelectionStyleBlue;
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.3];
                [(UIImageView*) [cell viewWithTag:1] setAlpha:1.0];
                [(UIImageView*) [cell viewWithTag:2] setAlpha:1.0];
                [(UIImageView*) [cell viewWithTag:3] setAlpha:1.0];
                [UIView commitAnimations];
            }
        }
    }
    else{
        [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_up.png"] forState:UIControlStateNormal];
        [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateHighlighted];
        [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateSelected];
        [xbmcInfo setTitle:infoText forState:UIControlStateNormal];
        [AppDelegate instance].serverOnLine=NO;
        int n = [menuViewController.tableView numberOfRowsInSection:0];
        for (int i=0;i<n;i++){
            UITableViewCell *cell = [menuViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            if (cell!=nil){
                cell.selectionStyle=UITableViewCellSelectionStyleGray;
                [UIView beginAnimations:nil context:nil];
                [UIView setAnimationDuration:0.3];
                
                [(UIImageView*) [cell viewWithTag:1] setAlpha:0.3];
                [(UIImageView*) [cell viewWithTag:2] setAlpha:0.3];
                [(UIImageView*) [cell viewWithTag:3] setAlpha:0.3];
                [UIView commitAnimations];
            }
        }
    }
}


# pragma mark - toolbar management

-(void)toggleViewToolBar:(UIView*)view AnimDuration:(float)seconds Alpha:(float)alphavalue YPos:(int)Y forceHide:(BOOL)hide {
	[UIView beginAnimations:nil context:nil];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationDuration:seconds];
    int actualPosY=view.frame.origin.y;
    CGRect frame;
	frame = [view frame];
    NSLog(@"%d actual %d frame %f", Y, actualPosY, self.view.frame.size.height);
    if (actualPosY<667 || hide){
        Y=self.view.frame.size.height;
    }
    view.alpha = alphavalue;
	frame.origin.y = Y;
    view.frame = frame;
    [UIView commitAnimations];
}

- (void)toggleVolume{
    [self toggleViewToolBar:volumeSliderView AnimDuration:0.3 Alpha:1.0 YPos:volumeSliderView.frame.origin.y - volumeSliderView.frame.size.height - 42 forceHide:FALSE];
}

- (void)toggleSetup {
    if (_hostPickerViewController == nil) {
        self.hostPickerViewController = [[HostManagementViewController alloc] initWithNibName:@"HostManagementViewController" bundle:nil masterController:nil];
        // _hostPickerViewController.delegate = self;
        self.serverPickerPopover = [[UIPopoverController alloc] 
                                    initWithContentViewController:_hostPickerViewController];               
    }
    [self.serverPickerPopover presentPopoverFromRect:xbmcInfo.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

#pragma mark - Lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];
    obj=[GlobalData getInstance];  
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    int lastServer;
    if ([userDefaults objectForKey:@"lastServer"]!=nil){
        lastServer=[[userDefaults objectForKey:@"lastServer"] intValue];
        if (lastServer>-1){
            NSIndexPath *lastServerIndexPath=[NSIndexPath indexPathForRow:lastServer inSection:0];
            [self selectServerAtIndexPath:lastServerIndexPath];
        }
    }
    int tableHeight = [(NSMutableArray *)mainMenu count] * 64 + 16;
    int tableWidth = 300;
    int headerHeight=0;
   
    rootView = [[UIViewExt alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
	rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight;
	[rootView setBackgroundColor:[UIColor clearColor]];
	
	leftMenuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableWidth, self.view.frame.size.height)];
	leftMenuView.autoresizingMask = UIViewAutoresizingFlexibleHeight;	
    
//    CGRect maniMenuTitleFrame = CGRectMake(0.0f, 2.0f, tableWidth, headerHeight);
//    UILabel *mainMenuTitle=[[UILabel alloc] initWithFrame:maniMenuTitleFrame];
//    [mainMenuTitle setFont:[UIFont fontWithName:@"Optima-Regular" size:12]];
//    [mainMenuTitle setTextAlignment:UITextAlignmentCenter];
//    [mainMenuTitle setBackgroundColor:[UIColor clearColor]];
//    [mainMenuTitle setText:@"Main Menu"];
//    [mainMenuTitle setTextColor:[UIColor lightGrayColor]];
//    [mainMenuTitle setShadowColor:[UIColor blackColor]];
//    [mainMenuTitle setShadowOffset:CGSizeMake(1, 1)];
//    [leftMenuView addSubview:mainMenuTitle];
    
	menuViewController = [[MenuViewController alloc] initWithFrame:CGRectMake(0, headerHeight, leftMenuView.frame.size.width, leftMenuView.frame.size.height) mainMenu:mainMenu];
	[menuViewController.view setBackgroundColor:[UIColor clearColor]];
	[menuViewController viewWillAppear:FALSE];
	[menuViewController viewDidAppear:FALSE];
	[leftMenuView addSubview:menuViewController.view];
    int separator = 0;

//    separator = 18;
//    CGRect leatherBackground = CGRectMake(0.0f, tableHeight + headerHeight - 6, tableWidth, separator + 4);
//    UIImageView *leather = [[UIImageView alloc] initWithFrame:leatherBackground];
//    [leather setImage:[UIImage imageNamed:@"denim_seam.png"]];
//    leather.opaque = YES;
//    leather.alpha = 0.5;
//    [leftMenuView addSubview:leather];
    
    separator = 5;
    CGRect seamBackground = CGRectMake(0.0f, tableHeight + headerHeight - 2, tableWidth, separator);
    UIImageView *seam = [[UIImageView alloc] initWithFrame:seamBackground];
    [seam setImage:[UIImage imageNamed:@"denim_single_seam.png"]];
    seam.opaque = YES;
//    seam.alpha = 0.7;
    [leftMenuView addSubview:seam];
////    
//    UILabel *playlistTitle=[[UILabel alloc] initWithFrame:leatherBackground];
//    [playlistTitle setFont:[UIFont fontWithName:@"Optima-Regular" size:12]];
//    [playlistTitle setTextAlignment:UITextAlignmentCenter];
//    [playlistTitle setBackgroundColor:[UIColor clearColor]];
//    [playlistTitle setText:@"Playlist"];
//    [playlistTitle setTextColor:[UIColor lightGrayColor]];
//    [playlistTitle setShadowColor:[UIColor blackColor]];
//    [playlistTitle setShadowOffset:CGSizeMake(1, 1)];
//    [leftMenuView addSubview:playlistTitle];
    
    
    nowPlayingController = [[NowPlaying alloc] initWithNibName:@"NowPlaying" bundle:nil];
    CGRect frame=nowPlayingController.view.frame;
    YPOS=-(tableHeight + separator + headerHeight);
    frame.origin.y=tableHeight + separator + headerHeight;
    frame.size.width=tableWidth;
    frame.size.height=self.view.frame.size.height - tableHeight - separator - headerHeight;
    nowPlayingController.view.autoresizingMask=UIViewAutoresizingFlexibleHeight;
    nowPlayingController.view.frame=frame;
    
    [nowPlayingController setToolbarWidth:768 height:610 YPOS:YPOS playBarWidth:426 portrait:TRUE];
    
    [leftMenuView addSubview:nowPlayingController.view];

	rightSlideView = [[UIView alloc] initWithFrame:CGRectMake(leftMenuView.frame.size.width, 0, rootView.frame.size.width - leftMenuView.frame.size.width, rootView.frame.size.height-44)];
	rightSlideView.autoresizingMask = UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight;
    
	stackScrollViewController = [[StackScrollViewController alloc] init];	
	[stackScrollViewController.view setFrame:CGRectMake(0, 0, rightSlideView.frame.size.width, rightSlideView.frame.size.height)];
	[stackScrollViewController.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth + UIViewAutoresizingFlexibleHeight];
	[stackScrollViewController viewWillAppear:FALSE];
	[stackScrollViewController viewDidAppear:FALSE];
	[rightSlideView addSubview:stackScrollViewController.view];
	
	[rootView addSubview:leftMenuView];
	[rootView addSubview:rightSlideView];
    
//    self.view.backgroundColor = [UIColor blackColor];
//    self.view.backgroundColor = [[UIColor scrollViewTexturedBackgroundColor] colorWithAlphaComponent:0.5];
	[self.view setBackgroundColor:[UIColor colorWithPatternImage: [UIImage imageNamed:@"backgroundImage_repeat.png"]]];
    [self.view addSubview:rootView];
    
    xbmcLogo = [[UIButton alloc] initWithFrame:CGRectMake(686, 962, 74, 41)];
    [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_up.png"] forState:UIControlStateNormal];
    [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateHighlighted];
    [xbmcLogo setImage:[UIImage imageNamed:@"bottom_logo_down_blu.png"] forState:UIControlStateSelected];
    [xbmcLogo addTarget:self action:@selector(infoView) forControlEvents:UIControlEventTouchUpInside];
    xbmcLogo.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:xbmcLogo];
    
    UIButton  *volumeButton = [[UIButton alloc] initWithFrame:CGRectMake(341, 964, 36, 37)];
    [volumeButton setImage:[UIImage imageNamed:@"volume@2x.png"] forState:UIControlStateNormal];
    [volumeButton setImage:[UIImage imageNamed:@"volume@2x.png"] forState:UIControlStateHighlighted];
    [volumeButton setImage:[UIImage imageNamed:@"volume@2x.png"] forState:UIControlStateSelected];
    volumeButton.alpha = 0.1;
    volumeButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    volumeButton.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:volumeButton];
    
    volumeSliderView = [[VolumeSliderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 62.0f, 296.0f)];
    volumeSliderView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    frame=volumeSliderView.frame;
    frame.origin.x=408;
    frame.origin.y=self.view.frame.size.height - 170;
    volumeSliderView.frame=frame;
    CGAffineTransform trans = CGAffineTransformMakeRotation(M_PI * 0.5);
    volumeSliderView.transform = trans;    
    [self.view addSubview:volumeSliderView]; 
    
    xbmcInfo = [[UIButton alloc] initWithFrame:CGRectMake(438, 961, 225, 43)];
    [xbmcInfo setTitle:@"No connection" forState:UIControlStateNormal];    
    xbmcInfo.titleLabel.font = [UIFont fontWithName:@"Courier" size:11];
    xbmcInfo.titleLabel.minimumFontSize=6.0f;
    xbmcInfo.titleLabel.shadowColor = [UIColor blackColor];
    xbmcInfo.titleLabel.shadowOffset    = CGSizeMake (1.0, 1.0);
    [xbmcInfo setBackgroundImage:[UIImage imageNamed:@"bottom_text_up.9.png"] forState:UIControlStateNormal];
    xbmcInfo.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [xbmcInfo addTarget:self action:@selector(toggleSetup) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:xbmcInfo];
    
    checkServerParams=[NSDictionary dictionaryWithObjectsAndKeys: [[NSArray alloc] initWithObjects:@"version", nil], @"properties", nil];
    timer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(checkServer) userInfo:nil repeats:YES];
}

- (void)viewDidUnload{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[menuViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[stackScrollViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

-(void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
	[menuViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[stackScrollViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait || toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        
        [nowPlayingController setToolbarWidth:768 height:610 YPOS:YPOS playBarWidth:426 portrait:TRUE];

	}
	else if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || toInterfaceOrientation == UIInterfaceOrientationLandscapeRight){
        
        [nowPlayingController setToolbarWidth:1024 height:768 YPOS:YPOS playBarWidth:680 portrait:FALSE];

	}
}	

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
	return YES;
}

@end
