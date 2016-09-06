//
//  TCHTTPRequest.h
//  TCKit
//
//  Created by dake on 15/3/15.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCHTTPRequestProtocol.h"
#import "TCHTTPReqAgentDelegate.h"
#import "TCHTTPCachePolicy.h"
#import "TCHTTPStreamPolicy.h"


NS_CLASS_AVAILABLE_IOS(7_0) @interface TCHTTPRequest : NSObject <TCHTTPRequest, TCHTTPReqAgentDelegate>

//
// callback
//
@property (nonatomic, weak) id<TCHTTPRequestDelegate> delegate;
@property (nonatomic, copy) void (^resultBlock)(id<TCHTTPRequest> request, BOOL success);
@property (nonatomic, weak) id observer;
@property (nonatomic, strong) id<TCHTTPRespValidator> responseValidator;


@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong) NSDictionary *userInfo;
@property (atomic, assign) TCRequestState state;
@property (atomic, assign, readonly) BOOL isCancelled;

//
// build request
//
@property (nonatomic, copy) NSString *apiUrl; // "getUserInfo/"
@property (nonatomic, copy) NSString *baseUrl; // "http://eet/oo/"

// Auto convert to query string, if requestMethod is GET
@property (nonatomic, strong) NSDictionary<NSString *, id> *parameters;

// TODO: extract to options
@property (nonatomic, assign) NSTimeInterval timeoutInterval; // default: 30s
@property (nonatomic, assign) TCHTTPMethod method;
@property (nonatomic, assign) BOOL overrideIfImpact; // default: YES, NO: abandon current request, if a same one existed
@property (nonatomic, assign) BOOL ignoreParamFilter;


- (instancetype)initWithMethod:(TCHTTPMethod)method;

/**
 @brief	start a http request with checking available cache,
 if cache is available, no request will be fired.
 
 @param error [OUT] param invalid, etc...
 
 */
- (BOOL)start:(NSError **)error;

- (BOOL)startWithResult:(void (^)(id<TCHTTPRequest> request, BOOL success))resultBlock error:(NSError **)error;

// delegate, resulteBlock always called, even if request was cancelled.
- (void)cancel;


- (BOOL)isRequestingNetwork;

/**
 @brief	request response object
 
 @return [NSDictionary]: json dictionary, [NSString]: download target path
 */
- (id)responseObject;


#pragma mark - timer

@property (nonatomic, strong) TCHTTPTimerPolicy *timerPolicy;


#pragma mark - Upload / download

@property (nonatomic, strong) TCHTTPStreamPolicy *streamPolicy;


#pragma mark - Custom

// set nonull to ignore requestUrl, argument, requestMethod, serializerType
@property (nonatomic, strong) NSURLRequest *customUrlRequest;


#pragma mark - TCHTTPReqAgentDelegate

@property (nonatomic, strong) NSURLSessionTask *requestTask;
@property (nonatomic, weak) id<TCHTTPRequestAgent> requestAgent;
@property (nonatomic, strong) id rawResponseObject;

- (void)requestResponded:(BOOL)isValid clean:(BOOL)clean;


@end

