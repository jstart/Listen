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

@interface CLTAudioManager : NSObject

+ (id)shared;

- (void)setPlaylist:(NSMutableArray *)playlist;

- (void)setArticleAtIndex:(int)index;

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent;

- (void)receivedEvent:(CLTAudioManagerEventType)receivedEvent;

@end
