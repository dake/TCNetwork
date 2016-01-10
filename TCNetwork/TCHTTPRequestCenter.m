//
//  TCHTTPRequestCenter.m
//  TCKit
//
//  Created by dake on 15/3/16.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import "TCHTTPRequestCenter.h"
#import "AFHTTPSessionManager.h"
#import "AFNetworkReachabilityManager.h"

#import "TCHTTPRequestHelper.h"
#import "TCHTTPRequest+Public.h"
#import "TCHTTPRequest+Private.h"
#import "TCBaseResponseValidator.h"
#import "NSURLSessionTask+TCResumeDownload.h"


@implementation TCHTTPRequestCenter
{
@private
    AFHTTPSessionManager *_requestManager;
    NSMutableDictionary *_requestPool;
    NSString *_cachePathForResponse;
    Class _responseValidorClass;
    
    NSURLSessionConfiguration *_sessionConfiguration;
}

+ (instancetype)defaultCenter
{
    static id s_defaultCenter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_defaultCenter = [[self alloc] initWithBaseURL:nil];
    });
    
    return s_defaultCenter;
}

- (Class)responseValidorClass
{
    return _responseValidorClass ?: TCBaseResponseValidator.class;
}

- (void)registerResponseValidatorClass:(Class)validatorClass
{
    _responseValidorClass = validatorClass;
}

- (BOOL)networkReachable
{
    return [AFNetworkReachabilityManager sharedManager].reachable;
}

- (NSInteger)maxConcurrentCount
{
    return self.requestManager.session.configuration.HTTPMaximumConnectionsPerHost;
}

- (void)setMaxConcurrentCount:(NSInteger)maxConcurrentCount
{
    @synchronized(self.requestManager.session) {
        self.requestManager.session.configuration.HTTPMaximumConnectionsPerHost = maxConcurrentCount;
    }
}

- (NSString *)cachePathForResponse
{
    if (nil == _cachePathForResponse) {
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
        _cachePathForResponse = [path stringByAppendingPathComponent:@"TCHTTPRequestCache"];
        NSString *domain = self.cacheDomainForResponse;
        if (domain.length > 0) {
            _cachePathForResponse = [_cachePathForResponse stringByAppendingPathComponent:domain];
        }
    }
    
    return _cachePathForResponse;
}

- (NSString *)cacheDomainForResponse
{
    return [self isMemberOfClass:TCHTTPRequestCenter.class] ? nil : NSStringFromClass(self.class);
}

- (AFSecurityPolicy *)securityPolicy
{
    return _requestManager.securityPolicy;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        _requestPool = NSMutableDictionary.dictionary;
    }
    return self;
}

- (AFHTTPSessionManager *)requestManager
{
    @synchronized(self) {
        if (nil == _requestManager) {
            _requestManager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:_sessionConfiguration];
            _requestManager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
            [_requestManager.reachabilityManager startMonitoring];
            AFSecurityPolicy *policy = self.securityPolicy;
            if (nil != policy) {
                _requestManager.securityPolicy = policy;
            }
        }
    }
    
    return _requestManager;
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
    return [self initWithBaseURL:url sessionConfiguration:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)url sessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    self = [self init];
    if (self) {
        _baseURL = url;
        _sessionConfiguration = configuration;
    }
    return self;
}


- (BOOL)canAddRequest:(__kindof TCHTTPRequest *)request error:(NSError **)error
{
    NSParameterAssert(request.observer);
    
    if (nil == request.observer) {
        if (NULL != error) {
            *error = [NSError errorWithDomain:NSStringFromClass(request.class)
                                         code:-1
                                     userInfo:@{NSLocalizedFailureReasonErrorKey: @"Callback Error",
                                                NSLocalizedDescriptionKey: @"delegate or resultBlock of request must be set"}];
        }
        return NO;
    }
    
    NSDictionary *headerFieldValueDic = self.customHeaderValue;
    for (NSString *httpHeaderField in headerFieldValueDic.allKeys) {
        NSString *value = headerFieldValueDic[httpHeaderField];
        if (![httpHeaderField isKindOfClass:NSString.class] || ![value isKindOfClass:NSString.class]) {
            if (NULL != error) {
                *error = [NSError errorWithDomain:NSStringFromClass(request.class)
                                             code:-1
                                         userInfo:@{NSLocalizedFailureReasonErrorKey: @"HTTP HEAD Error",
                                                    NSLocalizedDescriptionKey: @"class of key/value in headerFieldValueDictionary should be NSString."}];
            }
            
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)addRequest:(__kindof TCHTTPRequest *)request error:(NSError **)error
{
    if (![self canAddRequest:request error:error]) {
        return NO;
    }
    
    AFHTTPSessionManager *requestMgr = self.requestManager;
    @synchronized(requestMgr) {
        
        if (nil != self.acceptableContentTypes) {
            NSMutableSet *set = requestMgr.responseSerializer.acceptableContentTypes.mutableCopy;
            [set unionSet:self.acceptableContentTypes];
            requestMgr.responseSerializer.acceptableContentTypes = set;
        }
        
        requestMgr.requestSerializer.timeoutInterval = MAX(self.timeoutInterval, request.timeoutInterval);
        
        // if api need server username and password
        if (self.authorizationUsername.length > 0) {
            [requestMgr.requestSerializer setAuthorizationHeaderFieldWithUsername:self.authorizationUsername password:self.authorizationPassword];
        } else {
            [requestMgr.requestSerializer clearAuthorizationHeader];
        }
        
        // if api need add custom value to HTTPHeaderField
        NSDictionary *headerFieldValueDic = self.customHeaderValue;
        for (NSString *httpHeaderField in headerFieldValueDic.allKeys) {
            NSString *value = headerFieldValueDic[httpHeaderField];
            [requestMgr.requestSerializer setValue:value forHTTPHeaderField:httpHeaderField];
        }
        
        [self generateTaskFor:request];
    }
    
    return YES;
}

- (void)fireDownloadTaskFor:(TCHTTPRequest *)request downloadUrl:(NSString *)downloadUrl successBlock:(void (^)())successBlock failureBlock:(void (^)())failureBlock
{
    __block NSURLSessionTask *task = nil;
    
    NSURL * (^destination)(NSURL *targetPath, NSURLResponse *response) = ^(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:request.downloadDestinationPath];
    };
    
    void (^completionHandler)(NSURLResponse *response, NSURL *filePath, NSError *error) = ^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        if (nil != error || nil == filePath) {
            if (request.shouldResumeDownload && nil != error) {
                if ([error.domain isEqualToString:NSPOSIXErrorDomain] && 2 == error.code) {
                    [request clearCachedResumeData];
                }
            }
            
            failureBlock(task, error);
            
        } else {
            [request clearCachedResumeData];
            successBlock(task, filePath);
        }
    };
    
    AFHTTPSessionManager *requestMgr = self.requestManager;
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:downloadUrl]
                                                cachePolicy:requestMgr.requestSerializer.cachePolicy
                                            timeoutInterval:requestMgr.requestSerializer.timeoutInterval];
    
    if (request.shouldResumeDownload) {
        [request loadResumeData:^(NSData *data) {
            AFHTTPSessionManager *requestMgr = self.requestManager;
            @synchronized(requestMgr) {
                if (nil != data) {
                    task = [requestMgr downloadTaskWithResumeData:data progress:^(NSProgress * _Nonnull downloadProgress) {
                        request.downloadProgress = downloadProgress;
                    } destination:destination completionHandler:completionHandler];
                }
                
                if (nil == task) {
                    task = [requestMgr downloadTaskWithRequest:urlRequest progress:^(NSProgress * _Nonnull downloadProgress) {
                        request.downloadProgress = downloadProgress;
                    } destination:destination completionHandler:completionHandler];
                }
            }
            
            [self addTask:task toRequest:request];
            [task tc_makePersistentResumeCapable];
            task.tc_resumeIdentifier = request.downloadIdentifier;
            task.tc_resumeCacheDirectory = request.downloadResumeCacheDirectory;
            [task resume];
        }];
        
        return;
        
    } else {
        task = [requestMgr downloadTaskWithRequest:urlRequest progress:^(NSProgress * _Nonnull downloadProgress) {
            request.downloadProgress = downloadProgress;
        } destination:destination completionHandler:completionHandler];
        [self addTask:task toRequest:request];
        task.tc_resumeIdentifier = request.downloadIdentifier;
        task.tc_resumeCacheDirectory = request.downloadResumeCacheDirectory;
        [task resume];
    }
}

- (void)generateTaskFor:(TCHTTPRequest *)request
{
    __weak typeof(self) wSelf = self;
    void (^successBlock)() = ^(NSURLSessionTask *task, id responseObject) {
        NSAssert(NSThread.isMainThread, @"not main thread");
        request.rawResponseObject = responseObject;
        [wSelf handleRequestResult:request success:YES error:nil];
    };
    void (^failureBlock)() = ^(NSURLSessionTask *task, NSError *error) {
        NSAssert(NSThread.isMainThread, @"not main thread");
        [wSelf handleRequestResult:request success:NO error:error];
    };
    
    
    NSURLSessionTask *task = nil;
    
    // if api build custom url request
    NSURLRequest *customUrlRequest = request.customUrlRequest;
    if (nil != customUrlRequest) {
        AFHTTPSessionManager *requestMgr = self.requestManager;
        @synchronized(requestMgr) {
            task = [requestMgr dataTaskWithRequest:customUrlRequest completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
                if (nil != error) {
                    failureBlock(task, error);
                } else {
                    successBlock(task, responseObject);
                }
            }];
        }
        [task resume];
        [self addTask:task toRequest:request];
        return;
    }
    
    NSString *url = [self buildRequestUrlForRequest:request];
    NSParameterAssert(url);
    
    NSDictionary *param = request.parameters;
    if ([self.urlFilter respondsToSelector:@selector(filteredParamForParam:)]) {
        param = [self.urlFilter filteredParamForParam:param];
    }
    
    
    AFHTTPSessionManager *requestMgr = self.requestManager;
    @synchronized(requestMgr) {
        
        switch (request.requestMethod) {
                
            case kTCHTTPRequestMethodDownload: {
                NSParameterAssert(request.downloadDestinationPath);
                NSString *downloadUrl = [TCHTTPRequestHelper urlString:url appendParameters:param];
                NSParameterAssert(downloadUrl);
                
                if (downloadUrl.length < 1 || request.downloadDestinationPath.length < 1) {
                    return;
                }
                
                [self fireDownloadTaskFor:request downloadUrl:downloadUrl successBlock:successBlock failureBlock:failureBlock];
                return;
            }
                
            case kTCHTTPRequestMethodGet: {
                task = [requestMgr GET:url parameters:param progress:^(NSProgress * _Nonnull downloadProgress) {
                    request.downloadProgress = downloadProgress;
                } success:successBlock failure:failureBlock];
                break;
            }
                
            case kTCHTTPRequestMethodPost: {
                
                if (nil != request.constructingBodyBlock) {
                    task = [requestMgr POST:url parameters:param constructingBodyWithBlock:request.constructingBodyBlock progress:^(NSProgress * _Nonnull uploadProgress) {
                        request.uploadProgress = uploadProgress;
                    } success:successBlock failure:failureBlock];
                    request.constructingBodyBlock = nil;
                } else {
                    task = [requestMgr POST:url parameters:param progress:^(NSProgress * _Nonnull uploadProgress) {
                        request.uploadProgress = uploadProgress;
                    } success:successBlock failure:failureBlock];
                }
                break;
            }
                
            case kTCHTTPRequestMethodHead: {
                task = [requestMgr HEAD:url parameters:param success:successBlock failure:failureBlock];
                break;
            }
                
            case kTCHTTPRequestMethodPut: {
                task = [requestMgr PUT:url parameters:param success:successBlock failure:failureBlock];
                break;
            }
                
            case kTCHTTPRequestMethodDelete: {
                task = [requestMgr DELETE:url parameters:param success:successBlock failure:failureBlock];
                break;
            }
                
            case kTCHTTPRequestMethodPatch: {
                task = [requestMgr PATCH:url parameters:param success:successBlock failure:failureBlock];
                break;
            }
                
            default:
                break;
        }
    }
    
    [self addTask:task toRequest:request];
}

- (void)addTask:(NSURLSessionTask *)task toRequest:(TCHTTPRequest *)request
{
    if (nil != task) {
        request.requestTask = task;
        request.state = kTCHTTPRequestStateExecuting;
        // add to pool
        [self addObserver:request.observer forRequest:request];
    } else {
        if (nil != request.responseValidator) {
            request.responseValidator.error = [NSError errorWithDomain:NSStringFromClass(request.class)
                                                                  code:-1
                                                              userInfo:@{NSLocalizedFailureReasonErrorKey: @"Fire Request error",
                                                                         NSLocalizedDescriptionKey: @"generate NSURLSessionTask instances failed."}];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [request requestResponded:NO finish:nil clean:YES];
        });
    }
}


#pragma mark - TCHTTPRequestCenterProtocol

- (void)addObserver:(__unsafe_unretained id)observer forRequest:(id<TCHTTPRequestProtocol>)request
{
    if (request.isRetainByRequestPool) {
        return;
    }
    
    NSNumber *key = @((NSUInteger)observer);
    
    @synchronized(_requestPool) {
        NSParameterAssert(request);
        
        
        NSMutableDictionary *dic = _requestPool[key];
        if (nil == dic) {
            dic = NSMutableDictionary.dictionary;
            _requestPool[key] = dic;
        }
        
        id<TCHTTPRequestProtocol> preRequest = dic[request.requestIdentifier];
        if (nil != preRequest && preRequest.isRetainByRequestPool) {
            preRequest.isRetainByRequestPool = NO;
            [preRequest cancel];
        }
        
        request.isRetainByRequestPool = YES;
        dic[request.requestIdentifier] = request;
    }
}

- (void)removeRequestObserver:(__unsafe_unretained id)observer forIdentifier:(id<NSCopying>)identifier
{
    NSNumber *key = @((NSUInteger)(__bridge void *)(observer));
    @synchronized(_requestPool) {
        
        NSMutableDictionary *dic = _requestPool[key];
        
        if (nil != identifier) {
            id<TCHTTPRequestProtocol> request = dic[identifier];
            if (nil != request && request.isRetainByRequestPool) {
                request.isRetainByRequestPool = NO;
                [request cancel];
                [dic removeObjectForKey:identifier];
                if (dic.count < 1) {
                    [_requestPool removeObjectForKey:key];
                }
            }
        } else {
            [dic.allValues setValue:@NO forKeyPath:@"isRetainByRequestPool"];
            [dic.allValues makeObjectsPerformSelector:@selector(cancel)];
            [_requestPool removeObjectForKey:key];
        }
    }
}

- (void)removeRequestObserver:(__unsafe_unretained id)observer
{
    [self removeRequestObserver:observer forIdentifier:nil];
}

- (void)removeAllCachedResponse
{
    NSString *path = self.cachePathForResponse;
    if (nil != path) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
    }
}


#pragma mark -

- (NSString *)buildRequestUrlForRequest:(id<TCHTTPRequestProtocol>)request
{
    NSString *queryUrl = request.apiUrl;
    
    if (nil != self.urlFilter) {
        if ([self.urlFilter respondsToSelector:@selector(filteredUrlForUrl:)]) {
            queryUrl = [self.urlFilter filteredUrlForUrl:queryUrl];
        }
    }
    
    if ([queryUrl.lowercaseString hasPrefix:@"http"]) {
        return queryUrl;
    }
    
    NSURL *baseUrl = nil;
    
    if (request.baseUrl.length > 0) {
        baseUrl = [NSURL URLWithString:request.baseUrl];
    } else {
        baseUrl = self.baseURL;
    }

    return [baseUrl URLByAppendingPathComponent:queryUrl].absoluteString;
}

- (id<TCHTTPResponseValidator>)responseValidatorForRequest:(id<TCHTTPRequestProtocol>)request
{
    return request.requestMethod != kTCHTTPRequestMethodDownload ? [[self.responseValidorClass alloc] init] : nil;
}


#pragma mark -

- (void)handleRequestResult:(id<TCHTTPRequestProtocol>)request success:(BOOL)success error:(NSError *)error
{
    dispatch_block_t block = ^{
        request.state = kTCHTTPRequestStateFinished;
        [request requestResponseReset];
        
        BOOL isValid = success;
        
        if (nil != request.responseValidator) {
            if (isValid) {
                if ([request.responseValidator respondsToSelector:@selector(validateHTTPResponse:fromCache:)]) {
                    isValid = [request.responseValidator validateHTTPResponse:request.responseObject fromCache:NO];
                }
            } else {
                
                if ([request.responseValidator respondsToSelector:@selector(reset)]) {
                    [request.responseValidator reset];
                }
                request.responseValidator.error = error;
            }
        }
        
        [request requestResponded:isValid finish:^{
            // remove from pool
            if (request.isRetainByRequestPool) {
                [self removeRequestObserver:request.observer forIdentifier:request.requestIdentifier];
            }
        } clean:YES];
    };
    
    if (NSThread.isMainThread) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

#pragma mark - Making HTTP Requests

- (TCHTTPRequest *)requestWithMethod:(TCHTTPRequestMethod)method apiUrl:(NSString *)apiUrl host:(NSString *)host cache:(BOOL)cache
{
    if (cache) {
        return [self cacheRequestWithMethod:method apiUrl:apiUrl host:host];
    } else {
        return [self requestWithMethod:method apiUrl:apiUrl host:host];
    }
}

- (TCHTTPRequest *)requestWithMethod:(TCHTTPRequestMethod)method apiUrl:(NSString *)apiUrl host:(NSString *)host
{
    TCHTTPRequest *request = [TCHTTPRequest requestWithMethod:method];
    request.requestAgent = self;
    request.apiUrl = apiUrl;
    request.baseUrl = host;
    
    return request;
}

- (TCHTTPRequest *)cacheRequestWithMethod:(TCHTTPRequestMethod)method apiUrl:(NSString *)apiUrl host:(NSString *)host
{
    TCHTTPRequest *request = [TCHTTPRequest cacheRequestWithMethod:method];
    request.requestAgent = self;
    request.apiUrl = apiUrl;
    request.baseUrl = host;
    
    return request;
}

- (TCHTTPRequest *)batchRequestWithRequests:(NSArray<__kindof TCHTTPRequest *> *)requests
{
    NSParameterAssert(requests);
    TCHTTPRequest *request = [TCHTTPRequest batchRequestWithRequests:requests];
    request.requestAgent = self;
    
    return request;
}

- (TCHTTPRequest *)requestForDownload:(NSString *)url to:(NSString *)dstPath cache:(BOOL)cache
{
    NSParameterAssert(url);
    NSParameterAssert(dstPath);
    
    if (nil == url || nil == dstPath) {
        return nil;
    }
    
    TCHTTPRequest *request = [self requestWithMethod:kTCHTTPRequestMethodDownload apiUrl:url host:nil cache:cache];
    request.downloadDestinationPath = dstPath;
    
    return request;
}


@end
