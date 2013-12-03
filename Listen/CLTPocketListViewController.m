//
//  CLTPocketListViewController.m
//  Listen
//
//  Created by Christopher Truman on 10/28/13.
//  Copyright (c) 2013 truman. All rights reserved.
//
@import MediaPlayer;
@import AVFoundation;
#import "CLTPocketListViewController.h"
#import <PocketAPI/PocketAPI.h>
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <JSONKit/JSONKit.h>
#import <Block-KVO/NSObject+MTKObserving.h>

#import "CLTWebViewController.h"
#import "CLTArticleManager.h"
#import "CLTAudioManager.h"

@interface CLTPocketListViewController () <CLTAudioManagerDelegate>

@property (strong, nonatomic) NSArray * articleArray;

@end

@implementation CLTPocketListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pocketLoginStarted:)
                                                 name:(NSString *)PocketAPILoginStartedNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(pocketLoginFinished:)
                                                 name:(NSString *)PocketAPILoginFinishedNotification
                                               object:nil];

    UIBarButtonItem * refreshItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
    self.navigationItem.rightBarButtonItem = refreshItem;
    
    UIBarButtonItem * previousItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(previous)];
    UIBarButtonItem * playItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(play:)];
    UIBarButtonItem * nextItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(next)];
    self.navigationItem.leftBarButtonItems = @[previousItem, playItem, nextItem];
    
	// Do any additional setup after loading the view, typically from a nib.
    if (![PocketAPI sharedAPI].loggedIn) {
        [[PocketAPI sharedAPI] loginWithHandler: ^(PocketAPI *API, NSError *error){
            if (error != nil)
            {
                // There was an error when authorizing the user.
                // The most common error is that the user denied access to your application.
                // The error object will contain a human readable error message that you
                // should display to the user. Ex: Show an UIAlertView with the message
                // from error.localizedDescription
            }
            else
            {
                // The user logged in successfully, your app can now make requests.
                // [API username] will return the logged-in user’s username
                // and API.loggedIn will == YES
                [self refresh];
            }
        }];
    }
    else if ([CLTArticleManager hasBeenPersisted]) {
        [self showLoading:YES];
        dispatch_async(dispatch_get_global_queue(0, 0), ^(){
            self.articleArray = [[CLTArticleManager shared] localArticlesSortedByDate];
            [[CLTAudioManager shared] setPlaylist:[self.articleArray mutableCopy]];
            dispatch_async(dispatch_get_main_queue(), ^(){
                [[self tableView] reloadData];
                [self showLoading:NO];
            });
        });
     }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    [[CLTAudioManager shared] setDelegate:self];
}

-(BOOL)canBecomeFirstResponder{
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    [[CLTAudioManager shared] remoteControlReceivedWithEvent:receivedEvent];
}

-(void)refresh{
    [self showLoading:YES];
    [[CLTArticleManager shared] fetchUnreadArticlesSinceLastFetchWithSuccess:^(){
        self.articleArray = [[CLTArticleManager shared] localArticlesSortedByDate];
        [[CLTAudioManager shared] setPlaylist:[self.articleArray mutableCopy]];
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self showLoading:NO];
            [[self tableView] reloadData];
            [self showLoading:NO];
        });
    } andFailure:^(AFHTTPRequestOperation * operation, NSError * error){

    }];
}

-(void)showLoading:(BOOL)loading{
    
    UIBarButtonItem *rightBarButtonItem = nil;
    
    if (loading) {
        UIActivityIndicatorView * activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
        [activityView setColor:[UIColor redColor]];
        [activityView startAnimating];
        rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    }else{
        rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
        
    }
    [self.navigationItem setRightBarButtonItem:rightBarButtonItem];
}

#pragma mark -
#pragma CLTAudioManagerDelegate
-(void)didSelectArticleAtIndex:(int)currentArticle{
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:currentArticle inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    CLTArticle * article = [self.articleArray objectAtIndex:currentArticle];
    NSString * urlString = [NSString stringWithFormat:@"http://www.readability.com/m?url=%@", article.URL];
    UINavigationController * detailNavigationViewController = self.splitViewController.childViewControllers[1];
    
    CLTWebViewController * webViewController = (CLTWebViewController*)detailNavigationViewController.topViewController;
    [webViewController setTitle:article.title];
    [webViewController loadURL:[NSURL URLWithString:urlString]];
}

-(void)didRecieveAudioEvent:(CLTAudioManagerEventType)audioEvent{
    switch (audioEvent) {
        case CLTAudioManagerEventPlay:
            [self swapToPlayButton:NO];
            break;
        case CLTAudioManagerEventPause:
            [self swapToPlayButton:YES];
            break;
            
        default:
            break;
    }
}

-(void)swapToPlayButton:(BOOL)playButtonOrPause{
    UIBarButtonItem * previousItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(previous)];
    UIBarButtonItem * playItem = nil;
    
    if (playButtonOrPause) {
        playItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(play:)];
    }else{
        playItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(pause:)];
    }
    UIBarButtonItem * nextItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(next)];
    self.navigationItem.leftBarButtonItems = @[previousItem, playItem, nextItem];
}

-(void)play:(UIBarButtonItem *)sender{
    [[CLTAudioManager shared] receivedEvent:CLTAudioManagerEventPlay];
    [self swapToPlayButton:NO];
}

-(void)pause:(UIBarButtonItem *)sender{
    [[CLTAudioManager shared] receivedEvent:CLTAudioManagerEventPause];
    [self updatePauseButton];
}

-(void)updatePauseButton{
    UIBarButtonItem * previousItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(previous)];
    UIBarButtonItem * playItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(play:)];
    UIBarButtonItem * nextItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(next)];
    self.navigationItem.leftBarButtonItems = @[previousItem, playItem, nextItem];
}

-(void)next{
    [[CLTAudioManager shared] receivedEvent:CLTAudioManagerEventNext];
}

-(void)previous{
    [[CLTAudioManager shared] receivedEvent:CLTAudioManagerEventPrevious];
}

-(void)pocketLoginStarted:(NSNotification *)notification{
    // present login loading UI here
}

-(void)pocketLoginFinished:(NSNotification *)notification{
    // hide login loading UI here
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.articleArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString * cellIdentifier = @"CellIdentifier";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    CLTArticle * article = self.articleArray[indexPath.row];
    cell.textLabel.text = article.title;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    [[CLTAudioManager shared] setArticleAtIndex:(int)indexPath.row];
    
    CLTArticle * article = [self.articleArray objectAtIndex:indexPath.row];
    NSString * urlString = [NSString stringWithFormat:@"http://www.readability.com/m?url=%@", article.URL];
    CLTWebViewController * webViewController = [[CLTWebViewController alloc] initWithAddress:urlString];
    [self.navigationController pushViewController:webViewController animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
