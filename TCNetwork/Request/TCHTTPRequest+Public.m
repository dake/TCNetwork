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

+ (instancetype)requestWithMethod:(TCHTTPMethod)method
{
    return [[self alloc] initWithMethod:method];
}

+ (instancetype)cacheRequestWithMethod:(TCHTTPMethod)method cachePolicy:(TCHTTPCachePolicy *)policy
{
    return [TCHTTPCacheRequest requestWithMethod:method cachePolicy:policy];
}

+ (instancetype)batchRequestWithRequests:(NSArray<id<TCHTTPRequest>> *)requests
{
    return [TCHTTPBatchRequest requestWithRequests:requests];
}

@end
