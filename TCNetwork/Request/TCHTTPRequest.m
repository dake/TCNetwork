//
//  TCHTTPRequest.m
//  TCKit
//
//  Created by dake on 15/3/15.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import "TCHTTPRequest.h"
#import "TCHTTPRequestHelper.h"
#import "TCHTTPTimerPolicy+TCHTTPRequest.h"

@interface TCHTTPRequest () <TCHTTPTimerDelegate>

@property (atomic, assign, readwrite) BOOL isCancelled;

@end


@implementation TCHTTPRequest

@synthesize isForceStart; // compatible with cache api
@synthesize cachePolicy; // compatible with cache api


- (void)dealloc
{
    // weak self in dealloc may cause crash
    // refer: http://www.jianshu.com/p/841f60876180/comments/2333249
    [self cancel];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _overrideIfImpact = YES;
        _timeoutInterval = 30.0f;
    }
    return self;
}

- (instancetype)initWithMethod:(TCHTTPMethod)method
{
    self = [self init];
    if (self) {
        _method = method;
    }
    return self;
}


- (void)setTimerPolicy:(TCHTTPTimerPolicy *)timerPolicy
{
    if (_timerPolicy != timerPolicy) {
        _timerPolicy.delegate = nil;
        _timerPolicy = timerPolicy;
        timerPolicy.delegate = self;
    }
}

- (void)setStreamPolicy:(TCHTTPStreamPolicy *)streamPolicy
{
    if (_streamPolicy != streamPolicy) {
        _streamPolicy.request = nil;
        _streamPolicy = streamPolicy;
        streamPolicy.request = self;
    }
}

- (BOOL)isRequestingNetwork
{
    return kTCRequestNetwork == _state;
}

- (id)responseObject
{
    return nil != self.requestTask ? self.rawResponseObject : nil;
}

- (id)observer
{
    if (nil == _observer) {
        _observer = self.delegate ?: (id)self;
    }
    
    return _observer;
}

- (NSString *)identifier
{
    if (nil == _identifier) {
        _identifier = [TCHTTPRequestHelper MD5_16:[NSString stringWithFormat:@"%p_%@_%zd", self.observer, self.apiUrl, self.method]];
    }
    
    return _identifier;
}

- (id<TCHTTPRespValidator>)responseValidator
{
    if (nil == _responseValidator) {
        _responseValidator = [self.requestAgent responseValidatorForRequest:self];
    }
    
    return _responseValidator;
}


- (BOOL)canStart:(NSError **)error
{
    NSParameterAssert(self.requestAgent);
    return [self.requestAgent canAddRequest:self error:error];
}


- (BOOL)start:(NSError **)error
{
    NSParameterAssert(self.requestAgent);
    
    if (self.method == kTCHTTPMethodDownload && nil != self.timerPolicy) {
        @throw [NSException exceptionWithName:NSStringFromClass(self.class) reason:@"download task can not be polling" userInfo:nil];
    }
    
    if (nil != self.timerPolicy && self.timerPolicy.needStartTimer) {

        BOOL ret = [self.timerPolicy forward];
        if (ret) {
            // !!!: add to pool to prevent self dealloc before polling fired
            [self.requestAgent addRequestToPool:self];
        }
        return ret;
    }
    
    return [self.requestAgent addRequest:self error:error];
}

- (BOOL)startWithResult:(void (^)(id<TCHTTPRequest> request, BOOL success))resultBlock error:(NSError **)error
{
    self.resultBlock = resultBlock;
    return [self start:error];
}

- (void)cancel
{
    if (!self.isCancelled && nil != self.timerPolicy && self.timerPolicy.isValid) {
        
        BOOL isTicking = self.timerPolicy.isTicking;
        [self.timerPolicy invalidate];
        
        if (nil == self.requestTask || NSURLSessionTaskStateCompleted == self.requestTask.state) {
            self.isCancelled = YES;
            if (isTicking) {
                id<TCHTTPRespValidator> validator = self.responseValidator;
                if (nil != validator) {
                    [validator reset];
                    validator.error = [NSError errorWithDomain:NSURLErrorDomain
                                                          code:NSURLErrorCancelled
                                                      userInfo:@{NSLocalizedFailureReasonErrorKey: @"timer request cancelled",
                                                                 NSLocalizedDescriptionKey: @"timer request cancelled"}];
                }
                [self requestResponded:NO clean:YES];
            }
            return;
        }
    }
    
    if (self.isCancelled ||
        nil == self.requestTask ||
        NSURLSessionTaskStateCanceling == self.requestTask.state ||
        NSURLSessionTaskStateCompleted == self.requestTask.state) {
        self.isCancelled = YES;
        return;
    }
    
    self.isCancelled = YES;
    
    if (kTCHTTPMethodDownload == self.method && self.streamPolicy.shouldResumeDownload &&
        [self.requestTask isKindOfClass:NSURLSessionDownloadTask.class] &&
        [self.requestTask respondsToSelector:@selector(cancelByProducingResumeData:)]) {
        [(NSURLSessionDownloadTask *)self.requestTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            // not in main thread
        }];
    } else {
        [self.requestTask cancel];
    }
}


#pragma mark - TCHTTPReqAgentDelegate

- (void)requestResponded:(BOOL)isValid clean:(BOOL)clean
{
#ifndef TC_IOS_PUBLISH
    if (!isValid) {
        NSLog(@"%@\n \nERROR: %@", self, self.responseValidator.error);
    }
#endif
    
    // !!!: no weak self here
    dispatch_block_t block = ^{
        
        BOOL needForward = NO;
        if (nil != self.timerPolicy) { // must called before request callback called
            needForward = [self.timerPolicy checkForwardForRequest:isValid];
        }
        
        if (nil != self.delegate && [self.delegate respondsToSelector:@selector(processRequest:success:)]) {
            [self.delegate processRequest:self success:isValid];
        }
        
        if (nil != self.resultBlock) {
            self.resultBlock(self, isValid);
        }
        
        if (clean && !needForward) {
            self.resultBlock = nil;
            [self.requestAgent removeRequestFromPool:self];
            
        } else if (needForward) {
            self.state = kTCRequestUnFire;
            self.requestTask = nil;
            self.rawResponseObject = nil;
            [self.timerPolicy forward];
        }
    };
    
    if (NSThread.isMainThread) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}


#pragma mark - Cache

- (BOOL)forceStart:(NSError **)error
{
    return [self start:error];
}


#pragma mark - TCHTTPTimerDelegate

- (BOOL)timerRequestForPolicy:(TCHTTPTimerPolicy *)policy
{
    return [self start:NULL];
}


#pragma mark - Helper

- (NSString *)description
{
    NSURLRequest *request = self.requestTask.originalRequest;
    return [NSString stringWithFormat:@"🌍🌍🌍 %@: %@\n param: %@\n from cache: %@\n response: %@",
            NSStringFromClass(self.class),
            request.URL,
            [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding],
            self.cachePolicy.isDataFromCache ? @"YES" : @"NO",
            self.responseObject];
}


@end
