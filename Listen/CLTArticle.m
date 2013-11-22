//
//  CLTArticle.m
//  Listen
//
//  Created by Christopher Truman on 11/14/13.
//  Copyright (c) 2013 truman. All rights reserved.
//

#import "CLTArticle.h"
#import "NSDictionary+Safe.h"

@implementation CLTArticle

- (void) encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_title forKey:@"title"];
    [encoder encodeObject:_excerpt forKey:@"excerpt"];
    [encoder encodeObject:_wordCount forKey:@"wordCount"];
    [encoder encodeObject:_author forKey:@"author"];
    [encoder encodeObject:_content forKey:@"content"];
    [encoder encodeObject:_imageURL forKey:@"imageURL"];
    [encoder encodeObject:_faviconURL forKey:@"faviconURL"];
    [encoder encodeObject:_URL forKey:@"URL"];
    [encoder encodeObject:_isRead forKey:@"isRead"];
    [encoder encodeObject:_articleID forKey:@"articleID"];
    [encoder encodeObject:_date forKey:@"date"];
    [encoder encodeObject:_lastUpdated forKey:@"lastUpdated"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self.title = [decoder decodeObjectForKey:@"title"];
    self.excerpt = [decoder decodeObjectForKey:@"excerpt"];
    self.wordCount = [decoder decodeObjectForKey:@"wordCount"];
    self.author = [decoder decodeObjectForKey:@"author"];
    self.content = [decoder decodeObjectForKey:@"content"];
    self.imageURL = [decoder decodeObjectForKey:@"imageURL"];
    self.faviconURL = [decoder decodeObjectForKey:@"faviconURL"];
    self.URL = [decoder decodeObjectForKey:@"URL"];
    self.isRead = [decoder decodeObjectForKey:@"isRead"];
    self.articleID = [decoder decodeObjectForKey:@"articleID"];
    self.date = [decoder decodeObjectForKey:@"date"];
    self.lastUpdated = [decoder decodeObjectForKey:@"lastUpdated"];
    return self;
}

+(CLTArticle *) createArticleFromDictionary:(NSDictionary *)dictionary{
    CLTArticle * article = [[CLTArticle alloc] init];
    [article parseDictionary:dictionary];
    return article;
}

-(void) updateArticleFromDictionary:(NSDictionary *)dictionary{
    [self parseDictionary:dictionary];
}

- (void)parseDictionary:(NSDictionary *)dictionary{
    self.articleID = [dictionary safeNumberForKey:@"item_id"] ? [dictionary safeNumberForKey:@"item_id"] : self.articleID;
    self.content = [dictionary safeStringForKey:@"text"] ? [dictionary safeStringForKey:@"text"] : self.content ;
    self.title = [dictionary safeStringForKey:@"resolved_title"] ? [dictionary safeStringForKey:@"resolved_title"] : self.title;
    self.excerpt = [dictionary safeStringForKey:@"excerpt"] ? [dictionary safeStringForKey:@"excerpt"] : self.excerpt;
    self.wordCount = [dictionary safeNumberForKey:@"word_count"] ? [dictionary safeNumberForKey:@"word_count"] : self.wordCount;
    self.isRead = [dictionary safeNumberForKey:@"status"] ? [dictionary safeNumberForKey:@"status"] : self.isRead;
    self.URL = [dictionary safeStringForKey:@"resolved_url"] ? [dictionary safeStringForKey:@"resolved_url"] : self.URL;

    NSInteger interval = [[dictionary safeNumberForKey:@"time_added"] integerValue];
    self.date = [self dateForUnixTimestamp:interval] ? [self dateForUnixTimestamp:interval] : self.date;

    if ([[dictionary safeObjectForKey:@"authors"] count] > 0){
        self.author = [[dictionary[@"authors"] allValues] firstObject][@"name"];
    }

    if ([[dictionary safeObjectForKey:@"has_image"] integerValue] == 1) {
        self.imageURL = dictionary[@"image"][@"src"];
    }
    self.faviconURL = [dictionary safeStringForKey:@"icon"] ? [dictionary safeStringForKey:@"icon"] : self.faviconURL ;

    self.lastUpdated = [NSDate date];
}

-(NSDate *) dateForUnixTimestamp:(NSInteger)timestamp{
    if (!timestamp) {
        return nil;
    }
    NSTimeInterval _interval=timestamp;
    return [NSDate dateWithTimeIntervalSince1970:_interval];
}

-(NSString *)description{
    return [NSString stringWithFormat:@"CLTArticle: %@-%@-%@", self.title, self.author, self.URL];
}

@end
