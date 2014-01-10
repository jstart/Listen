//
//  CLTReadabilityResponseSerializer.m
//  Listen
//
//  Created by Christopher Truman on 11/28/13.
//  Copyright (c) 2013 truman. All rights reserved.
//

#import "CLTReadabilityResponseSerializer.h"
#import "CLTArticleManager.h"
#import "CLTArticle.h"
#import "NSString+HTML.h"

@implementation CLTReadabilityResponseSerializer

-(id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error
{
    NSDictionary * json = [super responseObjectForResponse:response data:data error:error];
    NSString * content = json[@"content"];
    
    NSString * url = [[json[@"url"] stringByReplacingOccurrencesOfString:@"http://" withString:@""] stringByReplacingOccurrencesOfString:@"www." withString:@""];

    CLTArticle * article = [[CLTArticleManager shared] articleForURLString:url];
    content = [[content kv_decodeHTMLCharacterEntities] kv_stripXMLTags];
    article.content = content;
    [article updateArticleFromDictionary:json];

    if (article == nil) {
        NSLog(@"%@", json[@"url"]);
    }
    return article;
}

- (BOOL)validateResponse:(NSHTTPURLResponse *)response
                    data:(NSData *)data
                   error:(NSError *__autoreleasing *)error{
    [super validateResponse:response data:data error:error];
    if (error) {
        return NO;
    }
    return YES;
}


@end
