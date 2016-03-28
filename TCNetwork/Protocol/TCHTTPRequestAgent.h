//
//  TCHTTPRequestAgent.h
//  TCKit
//
//  Created by dake on 15/3/15.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCHTTPRequestProtocol.h"


@protocol TCHTTPRequestAgent <NSObject>

@required
- (void)addRequestToPool:(id<TCHTTPRequest>)request;
- (void)removeRequestFromPool:(id<TCHTTPRequest>)request;

- (BOOL)canAddRequest:(id<TCHTTPRequest>)request error:(NSError **)error;
- (BOOL)addRequest:(id<TCHTTPRequest>)request error:(NSError **)error;
- (NSString *)buildRequestUrlForRequest:(id<TCHTTPRequest>)request;

// cache 
- (NSString *)cachePathForResponse;

- (void)storeCachedResponse:(id)response forCachePolicy:(TCHTTPCachePolicy *)cachePolicy finish:(dispatch_block_t)block;
- (void)cachedResponseForRequest:(id<TCHTTPRequest>)request result:(void(^)(id response))result;

- (id<TCHTTPRespValidator>)responseValidatorForRequest:(id<TCHTTPRequest>)request;

@optional
- (NSArray<id<TCHTTPRequest>> *)requestsForObserver:(id)observer;
- (id<TCHTTPRequest>)requestForObserver:(id)observer forIdentifier:(id)identifier;

@end



