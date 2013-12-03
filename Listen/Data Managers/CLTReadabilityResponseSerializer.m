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
    
    CLTArticle * article = [[CLTArticleManager shared] articleForURLString:json[@"url"]];
    content = [[content kv_decodeHTMLCharacterEntities] kv_stripXMLTags];
    article.content = content;
    [article updateArticleFromDictionary:json];

    return article;
}


@end
