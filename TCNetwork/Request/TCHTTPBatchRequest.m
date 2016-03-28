//
//  TCHTTPBatchRequest.m
//  TCKit
//
//  Created by dake on 15/3/26.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import "TCHTTPBatchRequest.h"

@interface TCHTTPBatchRequest () <TCHTTPRequestDelegate>

@property (atomic, assign, readwrite) BOOL isCancelled;
@property (atomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *finishDic;

@end

@implementation TCHTTPBatchRequest

@dynamic isCancelled;
@synthesize batchRequests = _batchRequests;


+ (instancetype)requestWithRequests:(NSArray<id<TCHTTPRequest>> *)requests
{
    return [[self alloc] initWithRequests:requests];
}

- (instancetype)initWithRequests:(NSArray<id<TCHTTPRequest>> *)requests
{
    self = [self init];
    if (self) {
        BOOL res = NO;
        for (id<TCHTTPRequest> request in requests) {
            if ([request conformsToProtocol:@protocol(TCHTTPRequest)] && (nil == request.timerPolicy || kTCHTTPTimerTypeDelay == request.timerPolicy.timerType)) {
                res = YES;
            } else {
                res = NO;
                break;
            }
        }
        
        if (!res) {
            @throw [NSException exceptionWithName:NSStringFromClass(self.class) reason:@"request must be none empty and conform to TCHTTPRequest protocol !" userInfo:nil];
        }
        self.batchRequests = requests;
        self.finishDic = NSMutableDictionary.dictionary;
    }
    return self;
}


#pragma mark -

- (BOOL)start:(NSError **)error
{
    NSParameterAssert(self.requestAgent);
    
    if (nil == self.requestAgent) {
        return NO;
    }
    
    NSAssert(nil == self.timerPolicy || kTCHTTPTimerTypeDelay == self.timerPolicy.timerType, @"batch request support delay timer only");
    if (nil != self.timerPolicy && kTCHTTPTimerTypeDelay != self.timerPolicy.timerType) {
        return NO;
    }
    
    self.state = kTCRequestNetwork;
    [self.requestAgent addRequestToPool:self];
    
    BOOL res = YES;
    for (id<TCHTTPRequest, TCHTTPReqAgentDelegate> request in self.batchRequests) {
        
        if (nil == request.requestAgent) {
            request.requestAgent = self.requestAgent;
        }
        request.observer = self;
        request.delegate = self;
        
        // ignore expired cache
        if (nil != request.cachePolicy) {
            request.cachePolicy.shouldExpiredCacheValid = NO;
        }
        
        NSError *error = nil;
        if (![request start:&error]) {
            NSLog(@"%@", error);
            res = NO;
            break;
        }
    }
    
    if (!res) {
        [self cancel];
        self.state = kTCRequestFinished;
        [self.requestAgent removeRequestFromPool:self];
        
        if (NULL != error) {
            *error = [NSError errorWithDomain:NSStringFromClass(self.class)
                                         code:-1
                                     userInfo:@{NSLocalizedFailureReasonErrorKey: @"start batch request failed.",
                                                NSLocalizedDescriptionKey: @"any bacth request item start failed."}];
        }
    }
    
    return res;
}

- (void)cancel
{
    if (self.isCancelled || kTCRequestUnFire == self.state || kTCRequestFinished == self.state ) {
        return;
    }
    
    self.isCancelled = YES;
    
    for (TCHTTPRequest *request in self.batchRequests) {
        request.delegate = nil;
        request.resultBlock = nil;
        request.streamPolicy.constructingBodyBlock = nil;
        [request cancel];
    }
}


#pragma mark - TCHTTPRequestDelegate

- (void)processRequest:(id<TCHTTPRequest>)request success:(BOOL)success
{
    self.finishDic[@((NSUInteger)request)] = @(success);
    if (success) {
        if (self.allRequestFinished) {
            // called in next runloop to avoid resultBlock = nil of sub request;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self requestCallback:YES];
            });
        }
    } else {
        [self cancel];
        [self requestCallback:NO];
    }
}

- (void)requestCallback:(BOOL)isValid
{
    self.state = kTCRequestFinished;
    [self requestResponded:isValid clean:YES];
}

- (BOOL)allRequestFinished
{
    BOOL finished = YES;
    for (TCHTTPRequest *request in self.batchRequests) {
        NSNumber *res = self.finishDic[@((NSUInteger)request)];
        if (nil == res || !res.boolValue) {
            finished = NO;
            break;
        }
    }
    return finished;
}


#pragma mark - Helper

- (NSString *)description
{
    return [NSString stringWithFormat:@"🌍🌍🌍 %@: %@\n", NSStringFromClass(self.class), self.batchRequests];
}

@end
