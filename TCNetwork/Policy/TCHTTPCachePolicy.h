//
//  TCHTTPCachePolicy.h
//  TCKit
//
//  Created by dake on 16/2/29.
//  Copyright © 2016年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCHTTPRequestProtocol.h"
#import "TCHTTPReqAgentDelegate.h"


extern NSInteger const kTCHTTPRequestCacheNeverExpired;

@interface TCHTTPCachePolicy : NSObject

@property (nonatomic, weak) id<TCHTTPRequest, TCHTTPReqAgentDelegate> request;
@property (nonatomic, strong) id cachedResponse;


@property (nonatomic, assign) BOOL shouldIgnoreCache; // default: NO
@property (nonatomic, assign) BOOL shouldCacheResponse; // default: YES
@property (nonatomic, assign) BOOL shouldCacheEmptyResponse; // default: YES, empty means: empty string, array, dictionary
@property (nonatomic, assign) NSTimeInterval cacheTimeoutInterval; // default: 0, expired anytime, < 0: never expired

// should return expired cache or not
@property (nonatomic, assign) BOOL shouldExpiredCacheValid; // default: NO

- (BOOL)isCacheValid;
- (BOOL)isDataFromCache;
- (NSDate *)cacheDate;
- (TCCachedRespState)cacheState;


// default: parameters = nil, sensitiveData = nil
- (void)setCachePathFilterWithRequestParameters:(NSDictionary *)parameters
                                  sensitiveData:(id)sensitiveData;


- (NSString *)cacheFileName;
- (NSString *)cacheFilePath;
- (BOOL)shouldWriteToCache;

@end
