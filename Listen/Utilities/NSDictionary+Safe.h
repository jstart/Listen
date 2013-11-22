//
//  NSDictionary+Safe.h
//  Listen
//
//  Created by Christopher Truman on 11/15/13.
//  Copyright (c) 2013 truman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (Safe)

-(id)safeObjectForKey:(id)key;
-(NSString *)safeStringForKey:(id)key;
-(NSNumber *)safeNumberForKey:(id)key;
-(NSDate *)safeDateForKey:(id)key;

@end
