//
//  TCHTTPRequestCenterProtocol.h
//  TCKit
//
//  Created by dake on 15/3/15.
//  Copyright (c) 2015年 Dake. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, TCHTTPRequestState) {
    kTCHTTPRequestStateUnFire = 0,
    kTCHTTPRequestStateExecuting,
    kTCHTTPRequestStateFinished,
};

typedef NS_ENUM(NSInteger, TCHTTPCachedResponseState) {
    kTCHTTPCachedResponseStateNone = 0,
    kTCHTTPCachedResponseStateValid,
    kTCHTTPCachedResponseStateExpired,
};


typedef NS_ENUM(NSInteger, TCHTTPRequestMethod) {
    kTCHTTPRequestMethodGet = 0,
    kTCHTTPRequestMethodPost,
    kTCHTTPRequestMethodHead,
    kTCHTTPRequestMethodPut,
    kTCHTTPRequestMethodDelete,
    kTCHTTPRequestMethodPatch,
    kTCHTTPRequestMethodDownload,
};


extern NSInteger const kTCHTTPRequestCacheNeverExpired;


@protocol TCHTTPRequestDelegate;
@protocol TCHTTPResponseValidator;
@protocol TCHTTPRequestCenterProtocol;


@protocol TCHTTPRequestProtocol <NSObject>

@required

#pragma mark - callback

@property (nonatomic, weak) id<TCHTTPRequestDelegate> delegate;
@property (nonatomic, copy) void (^resultBlock)(id<TCHTTPRequestProtocol> request, BOOL success);

@property (nonatomic, strong) id<TCHTTPResponseValidator> responseValidator;
@property (nonatomic, weak) id<TCHTTPRequestCenterProtocol> requestAgent;

@property (nonatomic, copy) NSString *requestIdentifier;
@property (atomic, assign) TCHTTPRequestState state;

- (void *)observer;
- (void)setObserver:(__unsafe_unretained id)observer;


/**
 @brief	start a http request with checking available cache,
 if cache is available, no request will be fired.
 
 @param error [OUT] param invalid, etc...
 
 @return <#return value description#>
 */
- (BOOL)start:(NSError **)error;
- (BOOL)startWithResult:(void (^)(id<TCHTTPRequestProtocol> request, BOOL success))resultBlock error:(NSError **)error;

// delegate, resulteBlock always called, even if request was cancelled.
- (void)cancel;



#pragma mark - construct request

@property (nonatomic, copy) NSString *apiUrl; // "getUserInfo/"
@property (nonatomic, copy) NSString *baseUrl; // "http://eet/oo/"
@property (nonatomic, copy) NSString *cdnUrl; // "http://sdfd/oo"

@property (nonatomic, assign) BOOL shouldUseCDN;
@property (nonatomic, assign) TCHTTPRequestMethod requestMethod;
@property (nonatomic, assign) BOOL isRetainByRequestPool;

- (id<NSCoding>)responseObject;
// for override
- (void)requestRespondSuccess;
- (void)requestRespondFailed;
- (void)requestRespondReset;


#pragma mark - Cache

@property (nonatomic, assign) BOOL shouldIgnoreCache; // always: YES
@property (nonatomic, assign) BOOL shouldCacheResponse; // always: NO
@property (nonatomic, assign) NSTimeInterval cacheTimeoutInterval; // always: 0, expired anytime
@property (nonatomic, assign) BOOL isForceStart;
// should return expired cache or not
@property (nonatomic, assign) BOOL shouldExpiredCacheValid; // default: NO


/**
 @brief	fire a request regardless of cache available
 if cache is available, callback then fire a request.
 
 @param error [OUT] <#error description#>
 
 @return <#return value description#>
 */
- (BOOL)forceStart:(NSError **)error;

- (BOOL)isDataFromCache;
- (BOOL)isCacheValid;
- (TCHTTPCachedResponseState)cacheState;
- (id)cachedResponseByForce:(BOOL)force state:(TCHTTPCachedResponseState *)state; // always nil


// default: parameters = self.parameters, sensitiveData = nil
- (void)setCachePathFilterWithRequestParameters:(NSDictionary *)parameters
                                  sensitiveData:(NSObject<NSCopying> *)sensitiveData;


#pragma mark - Batch

@property (nonatomic, copy, readonly) NSArray *requestArray;

@end



@class TCHTTPRequest;
@protocol TCHTTPRequestCenterProtocol <NSObject>

@required
- (void)addObserver:(__unsafe_unretained id)observer forRequest:(id<TCHTTPRequestProtocol>)request;
- (void)removeRequestObserver:(__unsafe_unretained id)observer forIdentifier:(id<NSCopying>)identifier;
- (void)removeRequestObserver:(__unsafe_unretained id)observer;

- (BOOL)addRequest:(TCHTTPRequest *)request error:(NSError **)error;
- (NSString *)buildRequestUrlForRequest:(id<TCHTTPRequestProtocol>)request;


@optional
- (NSArray *)requestsForObserver:(__unsafe_unretained id)observer;
- (id<TCHTTPRequestProtocol>)requestForObserver:(__unsafe_unretained id)observer forIdentifier:(id)identifier;

- (NSString *)cachePathForResponse;
- (void)removeAllCachedResponse;

- (id<TCHTTPResponseValidator>)responseValidatorForRequest:(id<TCHTTPRequestProtocol>)request;


@end


@protocol TCHTTPRequestDelegate <NSObject>

@optional
+ (void)processRequest:(TCHTTPRequest *)request success:(BOOL)success;
- (void)processRequest:(TCHTTPRequest *)request success:(BOOL)success;


@end


