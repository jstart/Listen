//
//  CLTAudioManager.h
//  Listen
//
//  Created by Christopher Truman on 11/14/13.
//  Copyright (c) 2013 truman. All rights reserved.
//

@interface CLTAudioManager : NSObject

+ (id)shared;

- (void)setPlaylist:(NSMutableArray *)playlist;

- (void)setCurrentArticle:(int)index;

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent;

@end
