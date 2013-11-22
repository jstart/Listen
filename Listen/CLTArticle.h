//
//  CLTArticle.h
//  Listen
//
//  Created by Christopher Truman on 11/14/13.
//  Copyright (c) 2013 truman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CLTArticle : NSObject

@property (nonatomic, strong) NSString * title;
@property (nonatomic, strong) NSString * excerpt;
@property (nonatomic, strong) NSNumber * wordCount;
@property (nonatomic, strong) NSString * author;
@property (nonatomic, strong) NSString * content;
@property (nonatomic, strong) NSString * imageURL;
@property (nonatomic, strong) NSString * faviconURL;
@property (nonatomic, strong) NSString * URL;
@property (nonatomic, strong) NSNumber * isRead;
@property (nonatomic, strong) NSNumber * articleID;
@property (nonatomic, strong) NSDate * date;
@property (nonatomic, strong) NSDate * lastUpdated;

+ (CLTArticle *) createArticleFromDictionary:(NSDictionary *)dictionary;
- (void) updateArticleFromDictionary:(NSDictionary *)dictionary;

@end
