//
//  TCHTTPRequest.h
//  TCKit
//
//  Created by dake on 15/3/15.
//  Copyright (c) 2015年 Dake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCHTTPResponseValidator.h"
#import "TCHTTPRequestCenterProtocol.h"


@protocol AFMultipartFormData;
typedef void (^AFConstructingBlock)(id<AFMultipartFormData> formData);

@class TCHTTPRequest;
typedef void (^TCRequestResultBlockType)(__kindof TCHTTPRequest *request, BOOL success);


#pragma mark -

NS_CLASS_AVAILABLE_IOS(7_0) @interface TCHTTPRequest : NSObject <TCHTTPRequestProtocol>

//
// callback
//
@property (nonatomic, weak) id<TCHTTPRequestDelegate> delegate;
@property (nonatomic, copy) TCRequestResultBlockType resultBlock;

@property (nonatomic, strong) id<TCHTTPResponseValidator> responseValidator;
@property (nonatomic, weak) id<TCHTTPRequestCenterProtocol> requestAgent;

@property (nonatomic, strong, readonly) NSURLSessionTask *requestTask;
@property (nonatomic, strong) id rawResponseObject;

@property (nonatomic, copy) NSString *requestIdentifier;
@property (nonatomic, strong) NSDictionary *userInfo;
@property (atomic, assign) TCHTTPRequestState state;
@property (nonatomic, assign, readonly) BOOL isCancelled;

//
// construct request
//
@property (nonatomic, copy) NSString *apiUrl; // "getUserInfo/"
@property (nonatomic, copy) NSString *baseUrl; // "http://eet/oo/"

// Auto convert to query string, if requestMethod is GET
@property (nonatomic, strong) NSDictionary *parameters;

@property (nonatomic, assign) NSTimeInterval timeoutInterval; // default: 60s
@property (nonatomic, assign) TCHTTPRequestMethod requestMethod;


- (instancetype)initWithMethod:(TCHTTPRequestMethod)method;

- (void)setObserver:(__unsafe_unretained id)observer;

/**
 @brief	start a http request with checking available cache,
 if cache is available, no request will be fired.
 
 @param error [OUT] param invalid, etc...
 
 @return <#return value description#>
 */
- (BOOL)start:(NSError **)error;

- (BOOL)startWithResult:(TCRequestResultBlockType)resultBlock error:(NSError **)error;

// delegate, resulteBlock always called, even if request was cancelled.
- (void)cancel;


- (BOOL)isExecuting;

/**
 @brief	request response object
 
 @return [NSDictionary]: json dictionary, [NSString]: download target path
 */
- (id)responseObject;



#pragma mark - Upload

@property (nonatomic, copy) AFConstructingBlock constructingBodyBlock;
@property (nonatomic, strong, readonly) NSProgress *uploadProgress;

#pragma mark - Download

@property (nonatomic, assign) BOOL shouldResumeDownload; // default: NO
@property (nonatomic, copy) NSString *downloadIdentifier; // such as hash string, but can not be file system path! if nil, apiUrl's md5 used.
@property (nonatomic, copy) NSString *downloadResumeCacheDirectory; // if nil, tmp directory used.
@property (nonatomic, copy) NSString *downloadDestinationPath;
@property (nonatomic, strong, readonly) NSProgress *downloadProgress;


#pragma mark - Custom

// set nonull to ignore requestUrl, argument, requestMethod, serializerType
@property (nonatomic, strong) NSURLRequest *customUrlRequest;


@end

