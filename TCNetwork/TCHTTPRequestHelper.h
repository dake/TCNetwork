//
//  TCHTTPRequestHelper.h
//  TCKit
//
//  Created by dake on 15/3/15.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCHTTPRequestHelper : NSObject

+ (NSString *)urlString:(NSString *)originUrlString appendParameters:(NSDictionary *)parameters;

+ (NSString *)MD5_32:(NSString *)str;
+ (NSString *)MD5_16:(NSString *)str;

@end


@interface NSDictionary (TCHTTPRequestHelper)

- (NSString *)convertToHttpQuery;

@end
