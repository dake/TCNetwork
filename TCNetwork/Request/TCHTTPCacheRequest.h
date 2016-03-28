//
//  TCHTTPCacheRequest.h
//  TCKit
//
//  Created by dake on 15/3/16.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import "TCHTTPRequest.h"

NS_ASSUME_NONNULL_BEGIN

NS_CLASS_AVAILABLE_IOS(7_0) @interface TCHTTPCacheRequest : TCHTTPRequest

@property (nonatomic, assign) BOOL isForceStart;
@property (nonatomic, strong, readonly) TCHTTPCachePolicy *cachePolicy;

+ (instancetype)requestWithMethod:(TCHTTPMethod)method cachePolicy:(TCHTTPCachePolicy *)policy;
- (instancetype)initWithMethod:(TCHTTPMethod)method cachePolicy:(TCHTTPCachePolicy *)policy;

/**
 @brief	fire a request regardless of cache available
 if cache is available, callback then fire a request.
 */
- (BOOL)forceStart:(NSError **)error;
- (void)cachedResponseByForce:(BOOL)force result:(void(^)(id response, TCCachedRespState state))result;

@end

NS_ASSUME_NONNULL_END
