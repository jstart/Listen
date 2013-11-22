//
//  NSDictionary+Safe.m
//  Listen
//
//  Created by Christopher Truman on 11/15/13.
//  Copyright (c) 2013 truman. All rights reserved.
//

#import "NSDictionary+Safe.h"

@implementation NSDictionary (Safe)

- (id)safeObjectForKey:(id)key {
    id value = [self valueForKey:key];
    if (value == [NSNull null] || value == nil) {
        return nil;
    }
    return value;
}

-(NSString *)safeStringForKey:(id)key{
    NSString * value = [self safeObjectForKey:key];
    if (![value isKindOfClass:[NSString class]]) {
        return nil;
    }
    return value;
}

-(NSNumber *)safeNumberForKey:(id)key{
    NSNumber * value = [self safeObjectForKey:key];

    if (@([value integerValue])) {
        return @([value integerValue]);
    }
    else if (![value isKindOfClass:[NSNumber class]]) {
        return nil;
    }
    return value;
}

-(NSDate *)safeDateForKey:(id)key{
    NSDate * value = [self safeObjectForKey:key];
    if (![value isKindOfClass:[NSDate class]]) {
        return nil;
    }
    return value;
}

@end
