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

#import <SVWebViewController/SVWebViewController.h>
#import "CLTArticleManager.h"

@interface CLTPocketListViewController () <AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate>

//Sound
@property (strong, nonatomic) AVAudioSession *session;

@property (strong, nonatomic) AVSpeechSynthesizer *synth;

@property (strong, nonatomic) AVSpeechSynthesisVoice *voice;

@property (assign, nonatomic) NSInteger currentArticle;

@property (strong, nonatomic) NSArray * articleArray;
@property (strong, nonatomic) NSDictionary * pocketDictionary;

@property (assign, nonatomic) BOOL atBeginning;
@property (assign, nonatomic) BOOL atEnd;
@property (assign, nonatomic) BOOL shouldProceed;

@end

@implementation CLTPocketListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setup];

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
            self.articleArray = [[CLTArticleManager shared] localArticles];
            self.currentArticle = 0;
            dispatch_async(dispatch_get_main_queue(), ^(){
                [[self tableView] reloadData];
            });
        });
     }
}

-(void)refresh{
    [[CLTArticleManager shared] fetchUnreadArticlesSinceLastFetchWithSuccess:^(){
        self.articleArray = [[CLTArticleManager shared] localArticlesSortedByDate];
        [[self tableView] reloadData];
    } andFailure:^(AFHTTPRequestOperation * operation, NSError * error){

    }];
}

-(void)speakArticleAtIndex:(NSInteger) index {
    CLTArticle * article = self.articleArray[index];

    NSString * articleContent = [NSString stringWithFormat:@"%@, %@", article.title, article.content];
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:articleContent];
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate - (AVSpeechUtteranceDefaultSpeechRate*0.4);
    utterance.postUtteranceDelay = 0.2;
    utterance.preUtteranceDelay = 0.2;
    [self.synth speakUtterance:utterance];
    [self updateNowPlayingWithArticle:article];
}

-(void)updateNowPlayingWithArticle:(CLTArticle *) article{
    NSArray *keys = [NSArray arrayWithObjects:MPMediaItemPropertyArtist, MPMediaItemPropertyTitle, nil];

    NSString * title = article.title;
    NSString * author = article.author;
    if (article.imageURL) {
        __block NSString * mediaURL = article.imageURL;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(){
            AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
            [manager setResponseSerializer:[AFImageResponseSerializer serializer]];
            [manager GET:mediaURL parameters:nil  success:^(AFHTTPRequestOperation *operation, id responseObject) {
                MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithImage:responseObject];
                NSMutableDictionary * mediaInfo = [[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo] mutableCopy];
                [mediaInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
                [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mediaInfo];

            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"%@", error);
            }];

        });
    }

    NSArray *values = [NSArray arrayWithObjects:author ? author : @"No author", title ? title : @"No title", nil];
    NSDictionary *mediaInfo = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mediaInfo];
}

-(void)setup{
    self.shouldProceed = YES;

    // set up our audio session
    self.session = [AVAudioSession sharedInstance];

    [self.session setCategory:AVAudioSessionCategoryPlayback error:nil];

    // set up our TTS synth
    self.synth = [[AVSpeechSynthesizer alloc] init];
    self.synth.delegate = self;

    AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] init];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
//    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {

    if (receivedEvent.type == UIEventTypeRemoteControl) {

        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlPause:
                [self pause];
                break;
            case UIEventSubtypeRemoteControlPlay:
                [self.synth continueSpeaking];
                break;
            case UIEventSubtypeRemoteControlTogglePlayPause:
                [self playPause];
                break;

            case UIEventSubtypeRemoteControlPreviousTrack:
                [self previous];
                break;

            case UIEventSubtypeRemoteControlNextTrack:
                [self next];
                break;

            default:
                break;
        }
    }
}

-(void)playPause{
    if (self.synth.isSpeaking && ![self.synth isPaused]) {
        [self pause];
    }else if(self.synth.isSpeaking){
        [self.synth continueSpeaking];
    }else{
        [self speechSynthesizer:self.synth didFinishSpeechUtterance:nil];
    }
}

-(void)pause{
    if ([self.synth isSpeaking]) {
        if ([self.synth pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate]) {
            NSLog(@"did pause ");
        } else {
            NSLog(@"did not pause ");
            [self speakArticleAtIndex:self.currentArticle];
            double delayInSeconds = 0.01;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self.synth pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
            });
        }
    }
}

-(void)previous{
    self.currentArticle--;
    if (!self.articleArray || self.currentArticle <= 0) {
        self.atBeginning = YES;
        return;
    }
    self.shouldProceed = NO;
    [self stop];
}

-(void)next{
    self.currentArticle++;
    if (self.currentArticle >= self.articleArray.count ) {
        self.atEnd = YES;
    }
    [self stop];
}

-(void)stop{
    if (self.synth.speaking) {
        if ([self.synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate]) {
            NSLog(@"did stop ");
        } else {
            NSLog(@"did not stop ");
            [self speakArticleAtIndex:self.currentArticle];
            double delayInSeconds = 0.01;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self.synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
            });
        }
    }
}

-(void)pocketLoginStarted:(NSNotification *)notification{
    // present login loading UI here
}

-(void)pocketLoginFinished:(NSNotification *)notification{
    // hide login loading UI here
}

-(BOOL)canBecomeFirstResponder{
    return YES;
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
    self.currentArticle = indexPath.row;
    self.shouldProceed = NO;
    [self stop];
    [self speakArticleAtIndex:self.currentArticle];
    
    CLTArticle * article = [self.articleArray objectAtIndex:indexPath.row];
    NSString * urlString = [NSString stringWithFormat:@"http://www.readability.com/m?url=%@", article.URL];
    SVWebViewController * webViewController = [[SVWebViewController alloc] initWithAddress:urlString];
    [self.navigationController pushViewController:webViewController animated:YES];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance{

}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance{
    NSLog(@"did finish %@", [utterance.speechString substringToIndex:20]);
    if (self.currentArticle < 0 || self.currentArticle >= self.articleArray.count) {
        return;
    }
    if (self.shouldProceed) {
        self.currentArticle++;
    }
    if (self.currentArticle >= self.articleArray.count ) {
        self.atEnd = YES;
        return;
    }
    if (self.articleArray && !self.atEnd && !self.atBeginning) {
        [self speakArticleAtIndex:self.currentArticle];
    }
    self.shouldProceed = YES;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance{
    NSLog(@"did pause %@", [utterance.speechString substringToIndex:20]);

}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didContinueSpeechUtterance:(AVSpeechUtterance *)utterance{
    NSLog(@"did continue %@", [utterance.speechString substringToIndex:20]);

}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance{
    NSLog(@"did cancel %@", [utterance.speechString substringToIndex:20]);
    if (self.currentArticle < 0 || self.currentArticle >= self.articleArray.count) {
        return;
    }
    if (self.shouldProceed) {
        self.currentArticle++;
    }
    if (self.currentArticle >= self.articleArray.count ) {
        self.atEnd = YES;
        return;
    }
    if (self.articleArray && !self.atEnd && !self.atBeginning) {
        [self speakArticleAtIndex:self.currentArticle];
    }
    self.shouldProceed = YES;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance{
//    NSLog(@"did speak %@ ", [utterance.speechString substringWithRange:characterRange]);

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
