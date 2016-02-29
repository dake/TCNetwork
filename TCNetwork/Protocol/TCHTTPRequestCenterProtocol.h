//
//  TCHTTPRequestCenterProtocol.h
//  TCKit
//
//  Created by dake on 15/3/15.
//  Copyright (c) 2015年 dake. All rights reserved.
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
    
    
    
    kTCHTTPRequestMethodCustom = -1,
};


@protocol AFMultipartFormData;
typedef void (^AFConstructingBlock)(id<AFMultipartFormData> formData);


@protocol TCHTTPRequestDelegate;
@protocol TCHTTPResponseValidator;
@protocol TCHTTPRequestCenterProtocol;


@protocol TCHTTPRequestProtocol <NSObject>

@required

#pragma mark - callback

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

- (BOOL)canStart:(NSError **)error;
// delegate, resulteBlock always called, even if request was cancelled.
- (void)cancel;



#pragma mark - construct request

@property (nonatomic, copy) NSString *apiUrl; // "getUserInfo/"
@property (nonatomic, copy) NSString *baseUrl; // "http://eet/oo/"

@property (nonatomic, assign) TCHTTPRequestMethod requestMethod;
@property (nonatomic, assign) BOOL isRetainByRequestPool;

- (id<NSCoding>)responseObject;

// for override
- (void)requestResponded:(BOOL)isValid finish:(dispatch_block_t)finish clean:(BOOL)clean;


#pragma mark - Cache

@property (nonatomic, assign) BOOL shouldIgnoreCache; // always: YES
@property (nonatomic, assign) BOOL isForceStart;


/**
 @brief	fire a request regardless of cache available
 if cache is available, callback then fire a request.
 
 @param error [OUT] <#error description#>
 
 @return <#return value description#>
 */
- (BOOL)forceStart:(NSError **)error;

- (void)cachedResponseByForce:(BOOL)force result:(void(^)(id response, TCHTTPCachedResponseState state))result; // always nil


#pragma mark - Batch

@property (nonatomic, copy, readonly) NSArray<id<TCHTTPRequestProtocol>> *requestArray;


#pragma mark - Upload

@property (nonatomic, copy) AFConstructingBlock constructingBodyBlock;
@property (nonatomic, strong, readonly) NSProgress *uploadProgress;


#pragma mark - Download

@property (nonatomic, assign) BOOL shouldResumeDownload; // default: NO
@property (nonatomic, copy) NSString *downloadIdentifier; // such as hash string, but can not be file system path! if nil, apiUrl's md5 used.
@property (nonatomic, copy) NSString *downloadResumeCacheDirectory; // if nil, tmp directory used.
@property (nonatomic, copy) NSString *downloadDestinationPath;
@property (nonatomic, strong, readonly) NSProgress *downloadProgress;

@end



@class TCHTTPRequest;
@protocol TCHTTPRequestCenterProtocol <NSObject>

@required
- (void)addObserver:(__unsafe_unretained id)observer forRequest:(id<TCHTTPRequestProtocol>)request;
- (void)removeRequestObserver:(__unsafe_unretained id)observer forIdentifier:(id<NSCopying>)identifier;
- (void)removeRequestObserver:(__unsafe_unretained id)observer;

- (BOOL)canAddRequest:(__kindof TCHTTPRequest *)request error:(NSError **)error;
- (BOOL)addRequest:(__kindof TCHTTPRequest *)request error:(NSError **)error;
- (NSString *)buildRequestUrlForRequest:(id<TCHTTPRequestProtocol>)request;


@optional
- (NSArray *)requestsForObserver:(__unsafe_unretained id)observer;
- (id<TCHTTPRequestProtocol>)requestForObserver:(__unsafe_unretained id)observer forIdentifier:(id)identifier;

- (NSString *)cachePathForResponse;
- (NSString *)cacheDomainForResponse;
- (void)removeAllCachedResponse;

- (id<TCHTTPResponseValidator>)responseValidatorForRequest:(id<TCHTTPRequestProtocol>)request;


@end


@protocol TCHTTPRequestDelegate <NSObject>

@optional
+ (void)processRequest:(TCHTTPRequest *)request success:(BOOL)success;
- (void)processRequest:(TCHTTPRequest *)request success:(BOOL)success;


@end


