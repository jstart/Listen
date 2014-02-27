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
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <JSONKit/JSONKit.h>
#import <Block-KVO/NSObject+MTKObserving.h>
#import <UIColor-Utilities/UIColor+Expanded.h>

#import "CLTWebViewController.h"
#import "CLTArticleTableViewCell.h"
#import "CLTArticleManager.h"
#import "CLTAudioManager.h"

@interface CLTPocketListViewController () <CLTAudioManagerDelegate, CLTArticleManagerDelegate>

@property (strong, nonatomic) NSMutableArray * articleArray;

@end

@implementation CLTPocketListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerNib:[UINib nibWithNibName:@"CLTArticleTableViewCell" bundle:nil] forCellReuseIdentifier:@"CLTArticleTableViewCell"];

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
            self.articleArray = [[[CLTArticleManager shared] localArticlesSortedByDate] mutableCopy];
            [[CLTAudioManager shared] setPlaylist:[self.articleArray mutableCopy]];
            dispatch_async(dispatch_get_main_queue(), ^(){
                [[self tableView] reloadData];
                [self showLoading:NO];
            });
        });
    }else{
        self.articleArray = [NSMutableArray array];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    [[CLTAudioManager shared] setDelegate:self];
    [[CLTArticleManager shared] setDelegate:self];
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
        self.articleArray = [[[CLTArticleManager shared] localArticlesSortedByDate] mutableCopy];
        [[CLTAudioManager shared] setPlaylist:[self.articleArray mutableCopy]];
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self showLoading:NO];
            [[self tableView] reloadData];
        });
    } andFailure:^(AFHTTPRequestOperation * operation, NSError * error){

    }];
}

-(void)showLoading:(BOOL)loading{
    
    UIBarButtonItem *rightBarButtonItem = nil;
    
    if (loading) {
        UIActivityIndicatorView * activityView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 25, 25)];
        [activityView sizeToFit];
        [activityView setAutoresizingMask:(UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin)];
        [activityView setColor:[UIColor colorWithHexString:@"1bb0f9"]];
        [activityView startAnimating];
        rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityView];
    }else{
        rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
        
    }
    [self.navigationItem setRightBarButtonItem:rightBarButtonItem];
}   

#pragma mark -
#pragma CLTArticleManagerDelegate
-(void)didFetchArticle:(CLTArticle *)article{
    dispatch_async(dispatch_get_global_queue(0, 0), ^(){
        [self.articleArray addObject:article];
        self.articleArray = [[self.articleArray sortedArrayUsingComparator:^(CLTArticle * article1, CLTArticle * article2){
            return [article2.date compare:article1.date];
        }] mutableCopy];
        [[CLTAudioManager shared] setPlaylist:self.articleArray];
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self.tableView reloadData];
        });
    });
}

-(void)didParseArticle:(CLTArticle *)article{
    if ([self.articleArray containsObject:article]) {
        NSLog(@"Contains %@", article.title);
    }
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
    static NSString * cellIdentifier = @"CLTArticleTableViewCell";
    CLTArticleTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[CLTArticleTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    CLTArticle * article = self.articleArray[indexPath.row];
    cell.titleLabel.text = article.title;
    cell.detailLabel.text = article.excerpt;
    [cell.imageArticleView setImageWithURL:[NSURL URLWithString:article.imageURL]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{

    [[CLTAudioManager shared] setArticleAtIndex:(int)indexPath.row];
    
    CLTArticle * article = [self.articleArray objectAtIndex:indexPath.row];
    NSString * urlString = [NSString stringWithFormat:@"http://www.readability.com/m?url=%@", article.URL];
    CLTWebViewController * webViewController = [[CLTWebViewController alloc] initWithAddress:urlString];
    [self.navigationController pushViewController:webViewController animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath{
    return @"Mark Read";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    CLTArticle * article = self.articleArray[indexPath.row];
    [[CLTArticleManager shared] markArticleRead:article withSuccess:^(){
        
    }andFailure:^(AFHTTPRequestOperation * operation, NSError * error){
        [self.articleArray insertObject:article atIndex:indexPath.row];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
    }];
    [self.articleArray removeObjectAtIndex:indexPath.row];
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath{
    return NO;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 88.0f;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
