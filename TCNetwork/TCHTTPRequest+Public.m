//
//  TCHTTPRequest+Public.m
//  TCKit
//
//  Created by cdk on 15/3/30.
//  Copyright (c) 2015年 Dake. All rights reserved.
//

#import "TCHTTPRequest+Public.h"
#import "TCHTTPCacheRequest.h"
#import "TCHTTPBatchRequest.h"

@implementation TCHTTPRequest (Public)


+ (instancetype)requestWithMethod:(TCHTTPRequestMethod)method
{
    return [[self alloc] initWithMethod:method];
}

+ (instancetype)cacheRequestWithMethod:(TCHTTPRequestMethod)method
{
    return [[TCHTTPCacheRequest alloc] initWithMethod:method];
}

+ (instancetype)batchRequestWithRequests:(NSArray<__kindof TCHTTPRequest *> *)requests
{
    return [TCHTTPBatchRequest requestWithRequests:requests];
}

@end
