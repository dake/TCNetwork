//
//  TCHTTPRequestHelper.m
//  TCKit
//
//  Created by dake on 15/3/15.
//  Copyright (c) 2015年 Dake. All rights reserved.
//

#import "TCHTTPRequestHelper.h"
#import <CommonCrypto/CommonDigest.h>


@implementation TCHTTPRequestHelper

+ (NSString *)urlString:(NSString *)originUrlString appendParameters:(NSDictionary *)parameters
{
    NSString *url = originUrlString;
    NSString *paraUrlString = parameters.convertToHttpQuery;
    
    if (nil != paraUrlString && paraUrlString.length > 0) {
        if ([originUrlString rangeOfString:@"?"].location != NSNotFound) {
            url = [originUrlString stringByAppendingString:paraUrlString];
        } else {
            url = [originUrlString stringByAppendingFormat:@"?%@", [paraUrlString substringFromIndex:1]];
        }
    }
    
    return url;
}


#pragma mark - MD5

+ (NSString *)MD5_32:(NSString *)str
{
    if (str.length < 1) {
        return nil;
    }
    
    const char *value = str.UTF8String;
    
    unsigned char outputBuffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(value, (CC_LONG)strlen(value), outputBuffer);
    
    NSMutableString *outputString = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger count = 0; count < CC_MD5_DIGEST_LENGTH; ++count) {
        [outputString appendFormat:@"%02x",outputBuffer[count]];
    }
    
    return outputString;
}

+ (NSString *)MD5_16:(NSString *)str
{
    NSString *value = [self MD5_32:str];
    return nil != value ? [value substringWithRange:NSMakeRange(8, 16)] : value;
}


@end


@implementation NSDictionary (TCHTTPRequestHelper)

- (NSString *)convertToHttpQuery
{
    NSMutableString *queryString = nil;
    if (self.count > 0) {
        queryString = [NSMutableString string];
        for (NSString *key in self.allKeys) {
            NSString *value = self[key];
            if (nil != value) {
                value = [NSString stringWithFormat:@"%@", value];
                value = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)value, CFSTR("."), CFSTR(":/?#[]@!$&'()*+,;="), kCFStringEncodingUTF8);
                [queryString appendFormat:queryString.length > 0 ? @"&%@=%@" : @"%@=%@", key, value];
            }
        }
    }
    return queryString;
}

@end
