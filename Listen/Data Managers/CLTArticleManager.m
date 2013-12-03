//
//  CLTArticleManager.m
//  Listen
//
//  Created by Christopher Truman on 11/14/13.
//  Copyright (c) 2013 truman. All rights reserved.
//

#import "CLTArticleManager.h"
#import <PocketAPI/PocketAPI.h>
#import <JSONKit/JSONKit.h>
#import <Block-KVO/NSObject+MTKObserving.h>
#import "NSString+HTML.h"
#import "CLTReadabilityResponseSerializer.h"
#import "CLTDiffbotResponseSerializer.h"

@interface CLTArticleManager()

@end

@implementation CLTArticleManager

static CLTArticleManager * sharedInstance;

+(BOOL)hasBeenPersisted{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"CLTArticleManager"];
    return [[NSFileManager defaultManager] fileExistsAtPath:dataPath];
}

+ (id)shared {
    if (!sharedInstance) {
        if ([CLTArticleManager hasBeenPersisted]) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"CLTArticleManager"];
            NSData * data = [NSData dataWithContentsOfFile:dataPath];
            sharedInstance = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }else{
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                sharedInstance = [[CLTArticleManager alloc] init];
                sharedInstance.localArticles = [NSMutableArray array];
                sharedInstance.localUnreadArticles = [NSMutableArray array];
                sharedInstance.localReadArticles = [NSMutableArray array];
            });
        }
    }else if(sharedInstance){
        return sharedInstance;
    }
    return sharedInstance;
}

- (void) encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_localArticles forKey:@"localArticles"];
    [encoder encodeObject:_localReadArticles forKey:@"localReadArticles"];
    [encoder encodeObject:_localUnreadArticles forKey:@"localUnreadArticles"];
    [encoder encodeObject:_since forKey:@"since"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self.localArticles = [decoder decodeObjectForKey:@"localArticles"];
    self.localUnreadArticles = [decoder decodeObjectForKey:@"localReadArticles"];
    self.localReadArticles = [decoder decodeObjectForKey:@"localUnreadArticles"];
    self.since = [decoder decodeObjectForKey:@"since"];
    return self;
}

-(void)persist{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"CLTArticleManager"];
    [data writeToFile:dataPath atomically:YES];
}

- (CLTArticle *)articleForURLString:(NSString *)URLString{
    NSArray * resultsArray = [[self localArticles] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"URL == %@", URLString]];
    return [resultsArray firstObject];
}

- (NSArray *)localArticlesSortedByDate{
    return [[self localArticles] sortedArrayUsingComparator:^(CLTArticle * article1, CLTArticle * article2){
        return [article2.date compare:article1.date];
    }];
}

-(void)parseArticles:(NSArray *) articles WithSuccess:(void(^)()) success andFailure:(void(^)()) failure {
    NSMutableArray * batchArray = [NSMutableArray array];
    for (CLTArticle * article in articles) {
        NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                        NULL,
                                                                                                        (CFStringRef)article.URL,
                                                                                                        NULL,
                                                                                                        (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                        kCFStringEncodingUTF8 ));
        NSString * encodedURLString = [NSString stringWithFormat:@"/v2/article?token=%@&url=%@", @"3519ab8183e8c4b04be634054ac0effe", encodedString];

        [batchArray addObject:@{@"method": @"GET", @"relative_url" : encodedURLString, @"fields": @"*"}];
    }
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [CLTDiffbotResponseSerializer serializer];

    [manager POST:@"http://www.diffbot.com/api/batch" parameters:@{@"token": @"3519ab8183e8c4b04be634054ac0effe", @"batch": [batchArray JSONString]} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        self.localArticles = [responseObject mutableCopy];
        success();
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        failure();
    }];
}

-(void)RD_parseArticles:(NSArray *) articles WithSuccess:(void(^)()) success andFailure:(void(^)()) failure {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [CLTReadabilityResponseSerializer serializer];
    NSMutableArray * operationArray = [NSMutableArray array];
    for (CLTArticle * article in articles) {
        if (!article.URL) {
            return;
        }
        NSMutableURLRequest *request = [manager.requestSerializer requestWithMethod:@"GET" URLString:[[NSURL URLWithString:@"https://www.readability.com/api/content/v1/parser" relativeToURL:manager.baseURL] absoluteString] parameters:@{@"token": @"a14cf32527d3837c4385d8c39f080bc1927b58ee", @"url": article.URL}];

        NSOperation * op = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
<<<<<<< HEAD
            
=======
             dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
                NSString * content = responseObject[@"content"];
                content = [[content kv_decodeHTMLCharacterEntities] kv_stripXMLTags];
                article.content = content;
                [article updateArticleFromDictionary:responseObject];
                [self.localArticles addObject:article];
             });
>>>>>>> 0693812a08b6a4f648b0e74142a83d49945050ad
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            failure();
        }];
        [operationArray addObject:op];
    }
    NSArray * operations  = [AFURLConnectionOperation batchOfRequestOperations:operationArray progressBlock:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations){
        
    }completionBlock:^(NSArray * completions){
        success();
        [self persist];
    }];
    [manager.operationQueue addOperations:operations waitUntilFinished:NO];
}

- (void)fetchUnreadArticlesSinceLastFetchWithSuccess:(CLTArticleManagerSuccess) success andFailure:(CLTArticleManagerFailure) failure{
    NSString *apiMethod = @"get";
    PocketAPIHTTPMethod httpMethod = PocketAPIHTTPMethodPOST;
    NSMutableDictionary *arguments = [NSMutableDictionary dictionaryWithDictionary:@{@"consumer_key": [NSString stringWithFormat:@"%lu", (unsigned long)[PocketAPI sharedAPI].appID], @"detailType" : @"complete", @"contentType": @"article", @"sort":@"newest"}];
    if (self.since && self.localArticles.count > 0) {
        [arguments setObject:self.since forKey:@"since"];
    }

    [[PocketAPI sharedAPI] callAPIMethod:apiMethod
                          withHTTPMethod:httpMethod
                               arguments:arguments
                                 handler:^(PocketAPI *api, NSString *apiMethod, NSDictionary *response, NSError *error){
                                     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
                                         self.since = response[@"since"];
                                         if (![response[@"list"] isKindOfClass:[NSArray class]]) {
                                             NSMutableArray * articles = [NSMutableArray array];
                                             for (NSDictionary * pocketDictionary in [response[@"list"] allValues]) {
                                                 CLTArticle * article = [CLTArticle createArticleFromDictionary:pocketDictionary];
                                                 [articles addObject:article];
                                             }
                                             self.localArticles = articles;
                                             
                                             [self RD_parseArticles:articles WithSuccess:^(){
                                                 success();
                                             } andFailure:^(){
                                                 failure(nil,nil);
                                             }];
                                         }else{
                                             success();
                                         }
                                     });
                                 }];
}

- (void)fetchReadArticlesSinceLastFetchWithSuccess:(CLTArticleManagerSuccess) success andFailure:(CLTArticleManagerFailure) failure{

}

- (void)markArticleRead:(CLTArticle *)article withSuccess:(CLTArticleManagerSuccess) success andFailure:(CLTArticleManagerFailure) failure{

}

- (void)markArticlesRead:(NSArray *)articles withSuccess:(CLTArticleManagerSuccess) success andFailure:(CLTArticleManagerFailure) failure{

}

- (void)deleteArticle:(CLTArticle *)article withSuccess:(CLTArticleManagerSuccess) success andFailure:(CLTArticleManagerFailure) failure{

}

- (void)deleteArticles:(NSArray *)articles withSuccess:(CLTArticleManagerSuccess) success andFailure:(CLTArticleManagerFailure) failure{

}

- (void)refetchAndParseArticle:(CLTArticle *)article withSuccess:(CLTArticleManagerSuccess) success andFailure:(CLTArticleManagerFailure) failure{
    
}

- (void)refetchAndParseArticles:(NSArray *)articles withSuccess:(CLTArticleManagerSuccess) success andFailure:(CLTArticleManagerFailure) failure{

}

@end
