//
//  CLTFirstViewController.m
//  Listen
//
//  Created by Christopher Truman on 10/28/13.
//  Copyright (c) 2013 truman. All rights reserved.
//
@import MediaPlayer;
#import "CLTFirstViewController.h"
#import <PocketAPI/PocketAPI.h>
#import <AFNetworking/AFHTTPRequestOperationManager.h>
#import <JSONKit/JSONKit.h>
#import <AVFoundation/AVFoundation.h>

@interface CLTFirstViewController () <AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate>

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

@implementation CLTFirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setup];

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
    else if ([[NSUserDefaults standardUserDefaults] dataForKey:@"Articles"] || self.articleArray) {
        if (self.articleArray == nil) {
            self.articleArray = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"Articles"]];
        }
        self.currentArticle = 0;
        [self speakArticleAtIndex:self.currentArticle];
    }
    else{
        [self refresh];
    }


}

-(void)refresh{
    NSString *apiMethod = @"get";
    PocketAPIHTTPMethod httpMethod = PocketAPIHTTPMethodPOST;
    NSMutableDictionary *arguments = [NSMutableDictionary dictionaryWithDictionary:@{@"consumer_key": [NSString stringWithFormat:@"%lu", (unsigned long)[PocketAPI sharedAPI].appID], @"detailType" : @"complete", @"contentType": @"article"}];
    if ([[NSUserDefaults standardUserDefaults] dataForKey:@"PocketResponse"]) {
        self.pocketDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"PocketResponse"]];
//        [arguments setObject:dictionary[@"since"] forKey:@"since"];
    }

    [[PocketAPI sharedAPI] callAPIMethod:apiMethod
                          withHTTPMethod:httpMethod
                               arguments:arguments
                                 handler: ^(PocketAPI *api, NSString *apiMethod, NSDictionary *response, NSError *error){
                                     // handle the response here
                                     if (![response[@"list"] isKindOfClass:[NSArray class]]) {
                                         NSArray * articleArray = [response[@"list"] allValues];
                                         NSData *data = [NSKeyedArchiver archivedDataWithRootObject:response];
                                         [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"PocketResponse"];
                                         [[NSUserDefaults standardUserDefaults] synchronize];
                                         NSMutableArray * batchArray = [NSMutableArray array];
                                         for (NSDictionary * articleDictionary in articleArray) {
                                             NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                                                             NULL,
                                                                                                                                             (CFStringRef)articleDictionary[@"resolved_url"],
                                                                                                                                             NULL,
                                                                                                                                             (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                                                             kCFStringEncodingUTF8 ));
                                             NSString * encodedURLString = [NSString stringWithFormat:@"/api/article?token=%@&url=%@", @"3519ab8183e8c4b04be634054ac0effe", encodedString];

                                             [batchArray addObject:@{@"method": @"GET", @"relative_url" : encodedURLString}];
                                         }
                                         AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

                                         [manager POST:@"http://www.diffbot.com/api/batch" parameters:@{@"token": @"3519ab8183e8c4b04be634054ac0effe", @"batch": [batchArray JSONString]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                             self.articleArray = responseObject;
                                             NSData *data = [NSKeyedArchiver archivedDataWithRootObject:responseObject];
                                             [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"Articles"];
                                             [[NSUserDefaults standardUserDefaults] synchronize];

                                             self.currentArticle = 0;
                                             [self speakArticleAtIndex:self.currentArticle];
                                         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                             NSLog(@"Error: %@", error);
                                         }];
                                     }
                                 }];
}

-(void)speakArticleAtIndex:(int) index {
    NSString * articleContent = [self.articleArray[index][@"body"] objectFromJSONString][@"text"];
    if ([articleContent isEqualToString:@""]) {
        self.currentArticle++;
        articleContent = [self.articleArray[index+1][@"body"] objectFromJSONString][@"text"];
    }
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:articleContent];
    utterance.rate = AVSpeechUtteranceDefaultSpeechRate - (AVSpeechUtteranceDefaultSpeechRate*0.4);
    utterance.postUtteranceDelay = 0.2;
    utterance.preUtteranceDelay = 0.2;
    [self.synth speakUtterance:utterance];

    NSArray *keys = [NSArray arrayWithObjects:MPMediaItemPropertyArtist, MPMediaItemPropertyTitle, nil];
    NSDictionary * pocketInfoItem = [self.pocketDictionary[@"list"] allValues][index];
    NSString * title = pocketInfoItem[@"resolved_title"];
    NSString * author = nil;
    if ([pocketInfoItem[@"authors"] count] > 0){
        author = [[pocketInfoItem[@"authors"] allValues] firstObject][@"name"];
    }
    __block NSString * mediaURL = nil;
    if (pocketInfoItem[@"has_image"]) {
        mediaURL = pocketInfoItem[@"image"][@"src"];
    }
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

    NSArray *values = [NSArray arrayWithObjects:author, title ? title : @"No title", nil];
    NSDictionary *mediaInfo = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mediaInfo];
}

-(void)setup{
    self.shouldProceed = YES;
    if ([[NSUserDefaults standardUserDefaults] dataForKey:@"PocketResponse"] || self.pocketDictionary) {
        self.pocketDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"PocketResponse"]];
    }
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(pocketLoginStarted:)
                                             name:(NSString *)PocketAPILoginStartedNotification
                                           object:nil];

[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(pocketLoginFinished:)
                                             name:(NSString *)PocketAPILoginFinishedNotification
                                           object:nil];

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
        }
    }
}

-(void)previous{
    self.currentArticle--;
    self.shouldProceed = NO;
    [self stop];

    if (!self.articleArray || self.currentArticle <= 0) {
        self.atBeginning = YES;
        return;
    }
}

-(void)next{
    self.currentArticle++;
    [self stop];

    if (self.currentArticle >= self.articleArray.count ) {
        self.atEnd = YES;
        return;
    }
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
    cell.textLabel.text = [self.articleArray[indexPath.row][@"body"] objectFromJSONString][@"title"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self speakArticleAtIndex:indexPath.row];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance{

}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance{
    NSLog(@"did finish %@", utterance.speechString);
    if (self.currentArticle < 0 || self.currentArticle >= self.articleArray.count) {
        return;
    }
    if (self.shouldProceed) {
        self.currentArticle++;
    }
    if (self.articleArray && !self.atEnd && !self.atBeginning) {
        [self speakArticleAtIndex:self.currentArticle];
    }
    self.shouldProceed = YES;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance{
    NSLog(@"did pause %@", utterance.speechString);

}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didContinueSpeechUtterance:(AVSpeechUtterance *)utterance{
    NSLog(@"did continue %@", utterance.speechString);

}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance{
    NSLog(@"did cancel %@", utterance.speechString);
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
