//
//  TCHTTPRequestCenter.h
//  TCKit
//
//  Created by dake on 15/3/16.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCHTTPRequestAgent.h"
#import "TCHTTPRequestUrlFilter.h"
#import "TCHTTPCachePolicy.h"
#import "TCHTTPStreamPolicy.h"


@class AFSecurityPolicy;
NS_CLASS_AVAILABLE_IOS(7_0) @interface TCHTTPRequestCenter : NSObject <TCHTTPRequestAgent>

@property (nonatomic, strong) NSURL *baseURL;

@property (nonatomic, assign, readonly) BOOL networkReachable;
// default: 0, use Max(TCHTTPRequestCenter.timeoutInterval, TCHTTPRequest.timeoutInterval)
@property (nonatomic, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, strong) NSSet *acceptableContentTypes;

@property (nonatomic, strong, readonly) NSURLSessionConfiguration *sessionConfiguration;
@property (nonatomic, weak) id<TCHTTPRequestUrlFilter> urlFilter;


+ (instancetype)defaultCenter;
- (instancetype)initWithBaseURL:(NSURL *)url sessionConfiguration:(NSURLSessionConfiguration *)configuration;
- (AFSecurityPolicy *)securityPolicy;

- (BOOL)addRequest:(id<TCHTTPRequest>)request error:(NSError **)error;

- (void)removeRequestObserver:(__unsafe_unretained id)observer forIdentifier:(id<NSCopying>)identifier;
- (void)removeRequestObserver:(__unsafe_unretained id)observer;

- (NSString *)cachePathForResponse;
- (NSString *)cacheDomainForResponse;
- (void)removeAllCachedResponses;

- (void)registerResponseValidatorClass:(Class)validatorClass;


#pragma mark - Cache 

- (void)storeCachedResponse:(id)response forCachePolicy:(TCHTTPCachePolicy *)cachePolicy finish:(dispatch_block_t)block;
- (void)cachedResponseForRequest:(id<TCHTTPRequest>)request result:(void(^)(id response))result;


#pragma mark - Custom value in HTTP Head

@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *customHeaderValue;

/**
 Sets the "Authorization" HTTP header set in request objects made by the HTTP client to a basic authentication value with Base64-encoded username and password. 
 This overwrites any existing value for this header.
 */
@property (nonatomic, copy) NSString *authorizationUsername;
@property (nonatomic, copy) NSString *authorizationPassword;

@end


@interface TCHTTPRequestCenter (TCHTTPRequest)

//
// request method below, will not auto start
//
- (id<TCHTTPRequest>)requestWithMethod:(TCHTTPMethod)method apiUrl:(NSString *)apiUrl host:(NSString *)host;
- (id<TCHTTPRequest>)requestWithMethod:(TCHTTPMethod)method cachePolicy:(TCHTTPCachePolicy *)policy apiUrl:(NSString *)apiUrl host:(NSString *)host;
- (id<TCHTTPRequest>)requestForDownload:(NSString *)url streamPolicy:(TCHTTPStreamPolicy *)streamPolicy cachePolicy:(TCHTTPCachePolicy *)cachePolicy;
- (id<TCHTTPRequest>)requestForUploadTo:(NSString *)url streamPolicy:(TCHTTPStreamPolicy *)streamPolicy;
- (id<TCHTTPRequest>)batchRequestWithRequests:(NSArray<id<TCHTTPRequest>> *)requests;

@end
