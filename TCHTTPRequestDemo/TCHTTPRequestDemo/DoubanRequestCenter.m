//
//  DoubanRequestCenter.m
//  TCHTTPRequestDemo
//
//  Created by cdk on 15/4/9.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import "DoubanRequestCenter.h"

static NSString *const kHost = @"https://api.douban.com/v2/";

@implementation DoubanRequestCenter


- (instancetype)initWithBaseURL:(NSURL *)url sessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    self = [super initWithBaseURL:[NSURL URLWithString:kHost] sessionConfiguration:configuration];
    if (self) {
        self.timeoutInterval = 90.0f;
        // You can set urlFilter delegate here to self, or other.
        // self.urlFilter = self;
    }
    return self;
}

- (id<TCHTTPRequest>)fetchBookInfoForID:(NSString *)bookID beforeRun:(void(^)(id<TCHTTPRequest> request))beforeRun
{
    if (nil == bookID || bookID.length < 1) {
        return nil;
    }
    
    TCHTTPCachePolicy *policy = [[TCHTTPCachePolicy alloc] init];
    policy.cacheTimeoutInterval = 10 * 60;
    policy.shouldExpiredCacheValid = NO;
    
    NSString *apiUrl = [@"book/" stringByAppendingString:bookID];
    id<TCHTTPRequest> request = [self requestWithMethod:kTCHTTPMethodGet cachePolicy:policy apiUrl:apiUrl host:nil];
    if (nil != beforeRun) {
        beforeRun(request);
    }
    request.parameters = @{@"fields": @"id,title,url"};
 
    return [request start:NULL] ? request : nil;
}

- (id<TCHTTPRequest>)searchBookListForKeyword:(NSString *)keyword beforeRun:(void(^)(id<TCHTTPRequest> request))beforeRun
{
    if (nil == keyword || keyword.length < 1) {
        return nil;
    }
    
    id<TCHTTPRequest> request = [self requestWithMethod:kTCHTTPMethodGet apiUrl:@"book/search" host:nil];
    if (nil != beforeRun) {
        beforeRun(request);
    }
    request.parameters = @{@"q": keyword,
                           @"fields": @"id,title,url"};
    return [request start:NULL] ? request : nil;
}

@end
