//
//  CLTArticleManager.h
//  Listen
//
//  Created by Christopher Truman on 11/14/13.
//  Copyright (c) 2013 truman. All rights reserved.
//
#import "CLTArticle.h"
#import <AFNetworking/AFNetworking.h>

typedef void (^CLTArticleManagerSuccess)(void);
typedef void (^CLTArticleManagerFailure)(AFHTTPRequestOperation *operation, NSError *error);

@interface CLTArticleManager : NSObject

@property (nonatomic, strong) NSMutableArray * localArticles;
@property (nonatomic, strong) NSMutableArray * localUnreadArticles;
@property (nonatomic, strong) NSMutableArray * localReadArticles;
@property (nonatomic, strong) NSNumber * since;

+ (BOOL)hasBeenPersisted;

+ (id)shared;

- (void)persist;

- (NSArray *)localArticlesSortedByDate;

- (void)fetchUnreadArticlesSinceLastFetchWithSuccess:(CLTArticleManagerSuccess) success andFailure:(CLTArticleManagerFailure) failure;

- (void)fetchReadArticlesSinceLastFetchWithSuccess:(CLTArticleManagerSuccess) success andFailure:(CLTArticleManagerFailure) failure;

- (void)markArticleRead:(CLTArticle *)article withSuccess:(CLTArticleManagerSuccess) success andFailure:(CLTArticleManagerFailure) failure;

- (void)markArticlesRead:(NSArray *)articles withSuccess:(CLTArticleManagerSuccess) success andFailure:(CLTArticleManagerFailure) failure;

- (void)deleteArticle:(CLTArticle *)article withSuccess:(CLTArticleManagerSuccess) success andFailure:(CLTArticleManagerFailure) failure;

- (void)deleteArticles:(NSArray *)articles withSuccess:(CLTArticleManagerSuccess) success andFailure:(CLTArticleManagerFailure) failure;

- (void)refetchAndParseArticle:(CLTArticle *)article withSuccess:(CLTArticleManagerSuccess) success andFailure:(CLTArticleManagerFailure) failure;

- (void)refetchAndParseArticles:(NSArray *)articles withSuccess:(CLTArticleManagerSuccess) success andFailure:(CLTArticleManagerFailure) failure;

@end
