//
//  TCHTTPRequest+Public.m
//  TCKit
//
//  Created by dake on 15/3/30.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import "TCHTTPRequest+Public.h"
#import "TCHTTPCacheRequest.h"
#import "TCHTTPBatchRequest.h"

@implementation TCHTTPRequest (Public)

+ (instancetype)requestWithMethod:(TCHTTPRequestMethod)method
{
    return [[self alloc] initWithMethod:method];
}

+ (instancetype)cacheRequestWithMethod:(TCHTTPRequestMethod)method cachePolicy:(TCHTTPCachePolicy *)policy
{
    return [TCHTTPCacheRequest requestWithMethod:method cachePolicy:policy];
}

+ (instancetype)batchRequestWithRequests:(NSArray<__kindof TCHTTPRequest *> *)requests
{
    return [TCHTTPBatchRequest requestWithRequests:requests];
}

@end
