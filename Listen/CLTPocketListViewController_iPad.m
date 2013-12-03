//
//  CLTPocketListViewController_iPad.m
//  Listen
//
//  Created by Christopher Truman on 10/28/13.
//  Copyright (c) 2013 truman. All rights reserved.
//
@import MediaPlayer;
@import AVFoundation;
#import "CLTPocketListViewController_iPad.h"
#import <PocketAPI/PocketAPI.h>
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <JSONKit/JSONKit.h>
#import <Block-KVO/NSObject+MTKObserving.h>

#import "CLTWebViewController.h"
#import "CLTArticleManager.h"
#import "CLTAudioManager.h"

@interface CLTPocketListViewController_iPad () <CLTAudioManagerDelegate>

@property (strong, nonatomic) NSArray * articleArray;

@end

@implementation CLTPocketListViewController_iPad

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
        dispatch_async(dispatch_get_global_queue(0, 0), ^(){
            self.articleArray = [[CLTArticleManager shared] localArticlesSortedByDate];
            [[CLTAudioManager shared] setPlaylist:[self.articleArray mutableCopy]];
            dispatch_async(dispatch_get_main_queue(), ^(){
                [[self tableView] reloadData];
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
    [[CLTArticleManager shared] fetchUnreadArticlesSinceLastFetchWithSuccess:^(){
        self.articleArray = [[CLTArticleManager shared] localArticlesSortedByDate];
        [[CLTAudioManager shared] setPlaylist:[self.articleArray mutableCopy]];
        dispatch_async(dispatch_get_main_queue(), ^(){
            [[self tableView] reloadData];
        });
    } andFailure:^(AFHTTPRequestOperation * operation, NSError * error){

    }];
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
            [self updatePlayButton];
            break;
        case CLTAudioManagerEventPause:
            [self updatePauseButton];
            break;
            
        default:
            break;
    }
}

-(void)play:(UIBarButtonItem *)sender{
    [[CLTAudioManager shared] receivedEvent:CLTAudioManagerEventPlay];
    [self updatePlayButton];
}

-(void)updatePlayButton{
    UIBarButtonItem * previousItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(previous)];
    UIBarButtonItem * playItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(pause:)];
    UIBarButtonItem * nextItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(next)];
    self.navigationItem.leftBarButtonItems = @[previousItem, playItem, nextItem];
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
    UINavigationController * detailNavigationViewController = self.splitViewController.childViewControllers[1];
    
    CLTWebViewController * webViewController = (CLTWebViewController*)detailNavigationViewController.topViewController;
    [webViewController setTitle:article.title];
    [webViewController loadURL:[NSURL URLWithString:urlString]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
