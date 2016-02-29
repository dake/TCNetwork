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

@dynamic isForceStart;

@synthesize cachePolicy = _cachePolicy;
@synthesize shouldIgnoreCache = _shouldIgnoreCache;


+ (instancetype)requestWithMethod:(TCHTTPRequestMethod)method cachePolicy:(TCHTTPCachePolicy *)policy
{
    return [[self alloc] initWithMethod:method cachePolicy:policy];
}

- (instancetype)initWithMethod:(TCHTTPRequestMethod)method cachePolicy:(TCHTTPCachePolicy *)policy
{
    self = [super initWithMethod:method];
    if (self) {
        _cachePolicy = policy ?: [[TCHTTPCachePolicy alloc] init];
        _cachePolicy.request = self;
    }
    return self;
}


- (void)setState:(TCHTTPRequestState)state
{
    [super setState:state];
    if (kTCHTTPRequestStateFinished == state) {
        [self requestResponseReset];
    }
}

- (id<NSCoding>)responseObject
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

- (void)requestResponded:(BOOL)isValid finish:(dispatch_block_t)finish clean:(BOOL)clean
{
    // !!!: must be called before self.validateResponseObject called, below
    [self requestResponseReset];
    
    if (isValid) {
        __weak typeof(self) wSelf = self;
        [self.cachePolicy writeToCache:self.responseObject finish:^{
            [wSelf callSuperRequestResponded:isValid finish:finish clean:clean];
        }];
    } else {
        [super requestResponded:isValid finish:finish clean:clean];
    }
}

- (void)callSuperRequestResponded:(BOOL)isValid finish:(dispatch_block_t)finish clean:(BOOL)clean
{
    [super requestResponded:isValid finish:finish clean:clean];
}


#pragma mark -

- (void)cachedResponseByForce:(BOOL)force result:(void(^)(id response, TCHTTPCachedResponseState state))result
{
    NSParameterAssert(result);
    
    if (nil == result) {
        return;
    }
    
    TCHTTPCachedResponseState cacheState = self.cachePolicy.cacheState;
    
    if (cacheState == kTCHTTPCachedResponseStateValid || (force && cacheState != kTCHTTPCachedResponseStateNone)) {
        __weak typeof(self) wSelf = self;
        [self.cachePolicy cachedResponseWithoutValidate:^(id response) {
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
    
    if (notFire) {
        __weak typeof(self) wSelf = self;
        [super requestResponded:isValid finish:^{
            // remove from pool
            if (wSelf.isRetainByRequestPool) {
                [wSelf.requestAgent removeRequestObserver:wSelf.observer forIdentifier:wSelf.requestIdentifier];
            }
        } clean:notFire];
    } else if (isValid) {
        [super requestResponded:isValid finish:nil clean:notFire];
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
    
    if (self.shouldIgnoreCache) {
        return [super start:error];
    }
    
    TCHTTPCachedResponseState state = self.cachePolicy.cacheState;
    if (state == kTCHTTPCachedResponseStateValid || (self.cachePolicy.shouldExpiredCacheValid && state != kTCHTTPCachedResponseStateNone)) {
        // !!!: add to pool to prevent self dealloc before cache respond
        [self.requestAgent addObserver:self.observer forRequest:self];
        __weak typeof(self) wSelf = self;
        [self.cachePolicy cachedResponseWithoutValidate:^(id response) {
            
            if (nil == response) {
                [wSelf callSuperStart];
                return;
            }
            
            __strong typeof(wSelf) sSelf = wSelf;
            if (kTCHTTPCachedResponseStateValid == state) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [sSelf cacheRequestCallbackWithoutFiring:YES];
                });
            } else if (wSelf.cachePolicy.shouldExpiredCacheValid) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [sSelf cacheRequestCallbackWithoutFiring:![sSelf callSuperStart]];
                });
            }
        }];
        
        return kTCHTTPCachedResponseStateValid == state ? YES : [super canStart:error];
    }
    
    return [super start:error];
}

- (BOOL)forceStart:(NSError **)error
{
    self.isForceStart = YES;
    
    if (!self.shouldIgnoreCache) {
        TCHTTPCachedResponseState state = self.cachePolicy.cacheState;
        if (kTCHTTPCachedResponseStateExpired == state || kTCHTTPCachedResponseStateValid == state) {
            // !!!: add to pool to prevent self dealloc before cache respond
            [self.requestAgent addObserver:self.observer forRequest:self];
            
            __weak typeof(self) wSelf = self;
            [self.cachePolicy cachedResponseWithoutValidate:^(id response) {
                __strong typeof(wSelf) sSelf = wSelf;
                dispatch_async(dispatch_get_main_queue(), ^{
                    BOOL ret = [sSelf callSuperStart];
                    if (nil != response) {
                        [sSelf cacheRequestCallbackWithoutFiring:!ret];
                    }
                });
            }];
            
            return [super canStart:error];
        }
    }
    
    return [super start:error];
}

@end
