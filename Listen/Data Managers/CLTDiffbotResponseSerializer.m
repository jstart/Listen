//
//  CLTDiffbotResponseSerializer.m
//  Listen
//
//  Created by Christopher Truman on 11/28/13.
//  Copyright (c) 2013 truman. All rights reserved.
//

#import "CLTDiffbotResponseSerializer.h"
#import "CLTArticleManager.h"
#import "CLTArticle.h"
#import "NSString+HTML.h"
#import <JSONKit/JSONKit.h>

@implementation CLTDiffbotResponseSerializer

-(id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    NSArray * json = [super responseObjectForResponse:response data:data error:error];
    NSMutableArray * articles = [NSMutableArray array];
    for (int i = 0; i < [json count]; i++) {
        NSDictionary * diffbotDictionary = [json[i][@"body"] objectFromJSONString];
        
        CLTArticle * article = [[CLTArticleManager shared] articleForURLString:diffbotDictionary[@"url"]];
        [article updateArticleFromDictionary:diffbotDictionary];
        if (article)
            [articles addObject:article];
    }

    return articles;
}


@end
