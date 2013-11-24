//
//  CLTAudioManager.m
//  Listen
//
//  Created by Christopher Truman on 11/14/13.
//  Copyright (c) 2013 truman. All rights reserved.
//

#import "CLTAudioManager.h"
#import "CLTArticle.h"
#import <AFNetworking/AFNetworking.h>

@import AVFoundation;
@import MediaPlayer;

@interface CLTAudioManager() <AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate>

@property (strong, nonatomic) AVAudioSession *session;

@property (strong, nonatomic) AVAudioPlayer * audioPlayer;

@property (strong, nonatomic) AVSpeechSynthesizer *synth;

@property (strong, nonatomic) AVSpeechSynthesisVoice *voice;

@property (strong, nonatomic) NSMutableArray * playlist;

@property (assign, nonatomic) int currentArticle;

@property (assign, nonatomic) BOOL atBeginning;
@property (assign, nonatomic) BOOL atEnd;
@property (assign, nonatomic) BOOL shouldProceed;

@end

@implementation CLTAudioManager

static CLTAudioManager * sharedInstance;

+ (id)shared {
    if (!sharedInstance) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedInstance = [[CLTAudioManager alloc] init];
        });
    }
    return sharedInstance;
}

-(id)init{
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

-(void)setup{
    self.shouldProceed = YES;
    
    self.playlist = [NSMutableArray array];
    
    // set up our audio session
    self.session = [AVAudioSession sharedInstance];
    
    [self.session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    // set up our TTS synth
    self.synth = [[AVSpeechSynthesizer alloc] init];
    self.synth.delegate = self;
    
    self.audioPlayer = [[AVAudioPlayer alloc] init];
    
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    //    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
}

- (void)setPlaylist:(NSMutableArray *)playlist{
    self.currentArticle = 0;
    _playlist = playlist;
}

- (void)setArticleAtIndex:(int)index{
    self.currentArticle = index;
    if ([self.synth isSpeaking] || [self.synth isPaused]) {
        [self stop];
    }else{
        [self speakArticleAtIndex:index];
    }
}

-(void)speakArticleAtIndex:(NSInteger) index {
    if (index > self.playlist.count || index < 0) {
        NSString * articleContent = @"";
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:articleContent];
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate - (AVSpeechUtteranceDefaultSpeechRate*0.4);
        utterance.postUtteranceDelay = 0.2;
        utterance.preUtteranceDelay = 0.2;
        [self.synth speakUtterance:utterance];
    }else{
        CLTArticle * article = self.playlist[index];
        
        NSString * articleContent = [NSString stringWithFormat:@"%@, %@", article.title, article.content];
        AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:articleContent];
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate - (AVSpeechUtteranceDefaultSpeechRate*0.4);
        utterance.postUtteranceDelay = 0.2;
        utterance.preUtteranceDelay = 0.2;
        [self.synth speakUtterance:utterance];
        [self updateNowPlayingWithArticle:article];
    }
}

-(void)updateNowPlayingWithArticle:(CLTArticle *) article{
    NSArray *keys = [NSArray arrayWithObjects:MPMediaItemPropertyArtist, MPMediaItemPropertyTitle, nil];
    
    NSString * title = article.title;
    NSString * author = article.author;
    if (article.imageURL) {
        NSString * mediaURL = article.imageURL;
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
    }
    
    NSArray *values = [NSArray arrayWithObjects:author ? author : @"No author", title ? title : @"No title", nil];
    NSDictionary *mediaInfo = [NSDictionary dictionaryWithObjects:values forKeys:keys];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mediaInfo];
}

- (void)receivedEvent:(CLTAudioManagerEventType)receivedEvent{
    switch (receivedEvent) {
        case CLTAudioManagerEventPause:
            [self pause];
            break;
        case CLTAudioManagerEventPlay:
            [self play];
            break;
//        case UIEventSubtypeRemoteControlTogglePlayPause:
//            [self playPause];
//            break;
            
        case CLTAudioManagerEventPrevious:
            [self previous];
            break;
            
        case CLTAudioManagerEventNext:
            [self next];
            break;
            
        default:
            break;
    }
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

-(void)play{
    if ([self.synth isPaused]) {
        [self.synth continueSpeaking];
    }else{
        self.currentArticle = 0;
        [self speakArticleAtIndex:0];
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

-(void)stopAndProceed{
    if ([self.synth isSpeaking] || [self.synth isPaused]) {
        [self stop];
    }else{
        [self speakArticleAtIndex:self.currentArticle];
    }
}

-(void)previous{
    self.currentArticle--;
    if (!self.playlist || self.currentArticle < 0) {
        self.atBeginning = YES;
        [self stopAndProceed];
        return;
    }
    self.shouldProceed = NO;
    [self stopAndProceed];
}

-(void)next{
    self.currentArticle++;
    if (self.currentArticle >= self.playlist.count ) {
        self.atEnd = YES;
        [self stopAndProceed];
    }
    [self stopAndProceed];
}

-(void)stop{
    if (self.synth.speaking) {
        if ([self.synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate]) {
            NSLog(@"did stop");
        } else {
            NSLog(@"did not stop");
            [self speakArticleAtIndex:self.currentArticle];
            double delayInSeconds = 0.01;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self.synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
            });
        }
    }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance{
    if (utterance.speechString.length >= 20) {
        NSLog(@"did start %@", [utterance.speechString substringToIndex:20]);
    }else{
        NSLog(@"did start %@", utterance.speechString);
    }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance{
    if (utterance.speechString.length >= 20) {
        NSLog(@"did finish %@", [utterance.speechString substringToIndex:20]);
    }else{
        NSLog(@"did finish %@", utterance.speechString);
    }
    if (self.currentArticle < 0 || self.currentArticle >= self.playlist.count) {
        return;
    }
    if (self.currentArticle >= self.playlist.count) {
        self.atEnd = YES;
        return;
    }
    if (self.playlist && !self.atEnd && !self.atBeginning) {
        [self speakArticleAtIndex:self.currentArticle];
    }
    self.shouldProceed = YES;
    self.atBeginning = NO;
    self.atEnd = NO;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance{
    if (utterance.speechString.length >= 20) {
        NSLog(@"did pause %@", [utterance.speechString substringToIndex:20]);
    }else{
        NSLog(@"did pause %@", utterance.speechString);
    }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didContinueSpeechUtterance:(AVSpeechUtterance *)utterance{
    if (utterance.speechString.length >= 20) {
        NSLog(@"did continue %@", [utterance.speechString substringToIndex:20]);
    }else{
        NSLog(@"did continue %@", utterance.speechString);
    }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance{
    if (utterance.speechString.length >= 20) {
        NSLog(@"did cancel %@", [utterance.speechString substringToIndex:20]);
    }else{
        NSLog(@"did cancel %@", utterance.speechString);
    }
    
    if (self.currentArticle < 0 || self.currentArticle >= self.playlist.count) {
        return;
    }
    if (self.currentArticle >= self.playlist.count ) {
        self.atEnd = YES;
        return;
    }
    if (self.playlist && !self.atEnd && !self.atBeginning) {
        [self speakArticleAtIndex:self.currentArticle];
    }
    self.shouldProceed = YES;
    self.atBeginning = NO;
    self.atEnd = NO;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance{
    //    NSLog(@"did speak %@ ", [utterance.speechString substringWithRange:characterRange]);
    
}

@end
