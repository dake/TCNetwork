//
//  TCHTTPCacheRequest.m
//  TCKit
//
//  Created by dake on 15/3/16.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import "TCHTTPCacheRequest.h"


@interface TCHTTPCacheRequest ()

@end

@implementation TCHTTPCacheRequest

@synthesize isForceStart = _isForceStart;
@synthesize cachePolicy = _cachePolicy;


+ (instancetype)requestWithMethod:(TCHTTPMethod)method cachePolicy:(TCHTTPCachePolicy *)policy
{
    return [[self alloc] initWithMethod:method cachePolicy:policy];
}

- (instancetype)initWithMethod:(TCHTTPMethod)method cachePolicy:(TCHTTPCachePolicy *)policy
{
    self = [super initWithMethod:method];
    if (self) {
        _cachePolicy = policy ?: [[TCHTTPCachePolicy alloc] init];
        _cachePolicy.request = self;
    }
    return self;
}


- (void)setState:(TCRequestState)state
{
    [super setState:state];
    if (kTCRequestFinished == state) {
        [self requestResponseReset];
    }
}

- (id)responseObject
{
    if (nil != self.cachePolicy.cachedResponse) {
        return self.cachePolicy.cachedResponse;
    }
    return [super responseObject];
}

- (void)requestResponseReset
{
    self.cachePolicy.cachedResponse = nil;
}

- (void)requestResponded:(BOOL)isValid clean:(BOOL)clean
{
    // !!!: must be called before self.validateResponseObject called, below
    [self requestResponseReset];
    
    if (isValid && self.cachePolicy.shouldWriteToCache && nil != self.requestAgent) {
        [self.requestAgent storeCachedResponse:self.responseObject forCachePolicy:self.cachePolicy finish:^{
            // no weak self here, in case of request dealloc before write cache callback
            [super requestResponded:isValid clean:clean];
        }];
    } else {
        [super requestResponded:isValid clean:clean];
    }
}


#pragma mark -

- (void)cachedResponseByForce:(BOOL)force result:(void(^)(id response, TCCachedRespState state))result
{
    NSParameterAssert(result);
    
    if (nil == result) {
        return;
    }
    
    TCCachedRespState cacheState = self.cachePolicy.cacheState;
    
    if (cacheState == kTCCachedRespValid || (force && cacheState != kTCCachedRespNone)) {
        __weak typeof(self) wSelf = self;
        [self.requestAgent cachedResponseForRequest:self result:^(id response) {
            if (nil != response && nil != wSelf.responseValidator &&
                [wSelf.responseValidator respondsToSelector:@selector(validateHTTPResponse:fromCache:)]) {
                [wSelf.responseValidator validateHTTPResponse:response fromCache:YES];
            }
            
            result(response, cacheState);
        }];
        
        return;
    }
    
    result(nil, cacheState);
}

- (void)cacheRequestCallbackWithoutFiring:(BOOL)notFire
{
    BOOL isValid = YES;
    if (nil != self.responseValidator && [self.responseValidator respondsToSelector:@selector(validateHTTPResponse:fromCache:)]) {
        isValid = [self.responseValidator validateHTTPResponse:self.responseObject fromCache:YES];
    }
    
    if (notFire || isValid) {
        [super requestResponded:isValid clean:notFire];
    }
}

- (BOOL)callSuperStart
{
    return [super start:NULL];
}


- (BOOL)start:(NSError **)error
{
    if (self.isForceStart) {
        return [self forceStart:error];
    }
    
    if (self.cachePolicy.shouldIgnoreCache || nil != self.timerPolicy) {
        return [super start:error];
    }
    
    TCCachedRespState state = self.cachePolicy.cacheState;
    if (kTCCachedRespValid == state || (self.cachePolicy.shouldExpiredCacheValid && kTCCachedRespNone != state)) {
        // !!!: add to pool to prevent self dealloc before cache respond
        [self.requestAgent addRequestToPool:self];
        __weak typeof(self) wSelf = self;
        [self.requestAgent cachedResponseForRequest:self result:^(id response) {
            
            if (nil == response) {
                [wSelf callSuperStart];
                return;
            }
            
            __strong typeof(wSelf) sSelf = wSelf;
            if (kTCCachedRespValid == state) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [sSelf cacheRequestCallbackWithoutFiring:YES];
                });
            } else if (wSelf.cachePolicy.shouldExpiredCacheValid) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [sSelf cacheRequestCallbackWithoutFiring:![sSelf callSuperStart]];
                });
            }
        }];
        
        return kTCCachedRespValid == state ? YES : [super canStart:error];
    }
    
    return [super start:error];
}

- (BOOL)forceStart:(NSError **)error
{
    self.isForceStart = YES;
    
    if (!self.cachePolicy.shouldIgnoreCache && nil == self.timerPolicy) {
        TCCachedRespState state = self.cachePolicy.cacheState;
        if (kTCCachedRespValid == state || (kTCCachedRespExpired == state && self.cachePolicy.shouldExpiredCacheValid)) {
            // !!!: add to pool to prevent self dealloc before cache respond
            [self.requestAgent addRequestToPool:self];
            
            __weak typeof(self) wSelf = self;
            [self.requestAgent cachedResponseForRequest:self result:^(id response) {
                __strong typeof(wSelf) sSelf = wSelf;
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (nil != response) {
                        [sSelf cacheRequestCallbackWithoutFiring:![sSelf canStart:NULL]];
                    }
                    [sSelf callSuperStart];
                });
            }];
            
            return [self canStart:error];
        }
    }
    
    return [super start:error];
}

@end
