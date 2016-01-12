//
//  TCHTTPRequest.m
//  TCKit
//
//  Created by dake on 15/3/15.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import "TCHTTPRequest.h"
#import "TCHTTPRequestHelper.h"


NSInteger const kTCHTTPRequestCacheNeverExpired = -1;


@interface TCHTTPRequest ()

@property (atomic, assign, readwrite) BOOL isCancelled;
@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readwrite) NSProgress *uploadProgress;
@property (nonatomic, strong, readwrite) NSProgress *downloadProgress;

@end


@implementation TCHTTPRequest
{
    @private
    void *_observer;
}

@dynamic shouldIgnoreCache;
@dynamic shouldCacheResponse;
@dynamic cacheTimeoutInterval;
@dynamic shouldExpiredCacheValid;
@dynamic shouldCacheEmptyResponse;

@synthesize isForceStart = _isForceStart;
@synthesize isRetainByRequestPool = _isRetainByRequestPool;


- (instancetype)init
{
    self = [super init];
    if (self) {
        _timeoutInterval = 60.0f;
        _requestMethod = kTCHTTPRequestMethodCustom;
    }
    return self;
}

- (instancetype)initWithMethod:(TCHTTPRequestMethod)method
{
    self = [self init];
    if (self) {
        _requestMethod = method;
    }
    return self;
}

- (BOOL)isExecuting
{
    return kTCHTTPRequestStateExecuting == _state;
}

- (id<NSCoding>)responseObject
{
    return nil != _requestTask ? ((id<NSCoding>)self.rawResponseObject) : nil;
}

- (void)setObserver:(__unsafe_unretained id)observer
{
    _observer = (__bridge void *)(observer);
}

- (void *)observer
{
    if (NULL == _observer) {
        self.observer = self.delegate ?: (id)self;
    }
    
    return _observer;
}

- (NSString *)requestIdentifier
{
    if (nil == _requestIdentifier) {
        _requestIdentifier = [TCHTTPRequestHelper MD5_16:[NSString stringWithFormat:@"%p_%@_%zd", self.observer, self.apiUrl, self.requestMethod]];
    }
    
    return _requestIdentifier;
}

- (NSString *)downloadIdentifier
{
    if (nil == _downloadIdentifier) {
        _downloadIdentifier = [TCHTTPRequestHelper MD5_16:self.apiUrl];
    }
    
    return _downloadIdentifier;
}

- (NSString *)downloadResumeCacheDirectory
{
    if (nil == _downloadResumeCacheDirectory) {
        
        NSString *dir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"TCHTTPRequestResumeCache"];
        if (![[NSFileManager defaultManager] createDirectoryAtPath:dir
                                       withIntermediateDirectories:YES
                                                        attributes:nil
                                                             error:NULL]) {
            NSAssert(false, @"create directory failed.");
            dir = nil;
        }
        
        _downloadResumeCacheDirectory = dir;
    }
    
    return _downloadResumeCacheDirectory;
}

- (id<TCHTTPResponseValidator>)responseValidator
{
    if (nil == _responseValidator
        && nil != self.requestAgent
        && [self.requestAgent respondsToSelector:@selector(responseValidatorForRequest:)]) {
        _responseValidator = [self.requestAgent responseValidatorForRequest:self];
    }
    
    return _responseValidator;
}


- (BOOL)canStart:(NSError **)error
{
    NSParameterAssert(self.requestAgent);
    
    if (nil != self.requestAgent && [self.requestAgent respondsToSelector:@selector(canAddRequest:error:)]) {
        return [self.requestAgent canAddRequest:self error:error];
    }
    
    return NO;
}


- (BOOL)start:(NSError **)error
{
    NSParameterAssert(self.requestAgent);
    
    if (nil != self.requestAgent && [self.requestAgent respondsToSelector:@selector(addRequest:error:)]) {
        return [self.requestAgent addRequest:self error:error];
    }
    
    return NO;
}

- (BOOL)startWithResult:(TCRequestResultBlockType)resultBlock error:(NSError **)error
{
    self.resultBlock = resultBlock;
    return [self start:error];
}

- (BOOL)forceStart:(NSError **)error
{
    self.isForceStart = YES;
    return [self start:error];
}

- (void)cancel
{
    if (!self.isCancelled &&
        _requestTask.state != NSURLSessionTaskStateCanceling &&
        _requestTask.state != NSURLSessionTaskStateCompleted) {
        self.isCancelled = YES;
        
        if (self.requestMethod == kTCHTTPRequestMethodDownload && self.shouldResumeDownload &&
            [_requestTask isKindOfClass:NSURLSessionDownloadTask.class] && [_requestTask respondsToSelector:@selector(cancelByProducingResumeData:)]) {
            [(NSURLSessionDownloadTask *)_requestTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                // not in main thread
            }];
        } else {
            [_requestTask cancel];
        }
    }
}


#pragma mark - Batch

- (NSArray *)requestArray
{
    return nil;
}


#pragma mark - Cache

- (BOOL)isCacheValid
{
    return self.cacheState == kTCHTTPCachedResponseStateValid;
}

- (TCHTTPCachedResponseState)cacheState
{
    return kTCHTTPCachedResponseStateNone;
}

- (BOOL)shouldIgnoreCache
{
    return YES;
}

- (void)setShouldIgnoreCache:(BOOL)shouldIgnoreCache
{
    
}

- (BOOL)shouldCacheResponse
{
    return NO;
}

- (NSTimeInterval)cacheTimeoutInterval
{
    return 0.0f;
}

- (BOOL)isDataFromCache
{
    return NO;
}

- (void)cachedResponseByForce:(BOOL)force result:(void(^)(id response, TCHTTPCachedResponseState state))result
{
    
}

- (void)requestResponded:(BOOL)isValid finish:(dispatch_block_t)finish clean:(BOOL)clean
{
#ifndef TC_IOS_PUBLISH
    if (!isValid) {
        NSLog(@"%@\n \nERROR: %@", self, self.responseValidator.error);
    }
#endif
    
    __weak typeof(self) wSelf = self;
    dispatch_block_t block = ^{
        if (nil != wSelf.delegate && [wSelf.delegate respondsToSelector:@selector(processRequest:success:)]) {
            [wSelf.delegate processRequest:wSelf success:isValid];
        }

        if (nil != wSelf.resultBlock) {
            wSelf.resultBlock(wSelf, isValid);
        }
        
        if (clean) {
            wSelf.resultBlock = nil;
        }
        
        if (nil != finish) {
            finish();
        }
    };
    
    if (NSThread.isMainThread) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

- (void)requestResponseReset
{
    
}

- (void)setCachePathFilterWithRequestParameters:(NSDictionary *)parameters
                                  sensitiveData:(NSObject<NSCopying> *)sensitiveData;
{
    @throw [NSException exceptionWithName:NSStringFromClass(self.class) reason:@"for subclass to impl" userInfo:nil];
}

#pragma mark - Helper

- (NSString *)description
{
    NSURLRequest *request = self.requestTask.originalRequest;
    return [NSString stringWithFormat:@"🌍🌍🌍 %@: %@\n param: %@\n response: %@", NSStringFromClass(self.class), request.URL, [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding], self.responseObject];
}


@end
