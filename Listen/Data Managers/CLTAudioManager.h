//
//  CLTAudioManager.h
//  Listen
//
//  Created by Christopher Truman on 11/14/13.
//  Copyright (c) 2013 truman. All rights reserved.
//

typedef enum {
    CLTAudioManagerEventPrevious,
    CLTAudioManagerEventPlay,
    CLTAudioManagerEventPause,
    CLTAudioManagerEventNext
    } CLTAudioManagerEventType;

@protocol CLTAudioManagerDelegate <NSObject>

@required

-(void)didRecieveAudioEvent:(CLTAudioManagerEventType)audioEvent;

-(void)didSelectArticleAtIndex:(int)currentArticle;

@end

@interface CLTAudioManager : NSObject

@property (nonatomic, strong) id <CLTAudioManagerDelegate> delegate;

+ (id)shared;

- (void)setPlaylist:(NSMutableArray *)playlist;

- (void)setArticleAtIndex:(int)index;

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent;

- (void)receivedEvent:(CLTAudioManagerEventType)receivedEvent;

@end
