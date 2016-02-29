//
//  TCHTTPCachePolicy.h
//  TCKit
//
//  Created by dake on 16/2/29.
//  Copyright © 2016年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCHTTPRequestCenterProtocol.h"


extern NSInteger const kTCHTTPRequestCacheNeverExpired;

@interface TCHTTPCachePolicy : NSObject

@property (nonatomic, weak) id<TCHTTPRequestProtocol> request;
@property (nonatomic, strong) id cachedResponse;


@property (nonatomic, assign) BOOL shouldIgnoreCache; // default: NO
@property (nonatomic, assign) BOOL shouldCacheResponse; // default: YES
@property (nonatomic, assign) BOOL shouldCacheEmptyResponse; // default: YES, empty means: empty string, array, dictionary
@property (nonatomic, assign) NSTimeInterval cacheTimeoutInterval; // default: 0, expired anytime, < 0: never expired

// should return expired cache or not
@property (nonatomic, assign) BOOL shouldExpiredCacheValid; // default: NO

- (BOOL)isCacheValid;
- (BOOL)isDataFromCache;
- (TCHTTPCachedResponseState)cacheState;


// default: parameters = nil, sensitiveData = nil
- (void)setCachePathFilterWithRequestParameters:(NSDictionary *)parameters
                                  sensitiveData:(id)sensitiveData;


- (NSString *)cacheFilePath;
- (void)writeToCache:(id)response finish:(dispatch_block_t)block;
- (void)cachedResponseWithoutValidate:(void(^)(id response))result;

@end
