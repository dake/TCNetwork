//
//  TCHTTPBatchRequest.m
//  TCKit
//
//  Created by cdk on 15/3/26.
//  Copyright (c) 2015年 Dake. All rights reserved.
//

#import "TCHTTPBatchRequest.h"

@interface TCHTTPBatchRequest () <TCHTTPRequestDelegate>

@property (atomic, assign, readwrite) BOOL isCancelled;
@property (atomic, strong) NSMutableDictionary *finishDic;

@end

@implementation TCHTTPBatchRequest

@dynamic isCancelled;
@synthesize requestArray = _requestArray;


+ (instancetype)requestWithRequests:(NSArray<__kindof TCHTTPRequest *> *)requests
{
    return [[self alloc] initWithRequests:requests];
}

- (instancetype)initWithRequests:(NSArray<__kindof TCHTTPRequest *> *)requests
{
    self = [self init];
    if (self) {
        BOOL res = NO;
        for (id request in requests) {
            if ([request isKindOfClass:TCHTTPRequest.class]) {
                res = YES;
            } else {
                res = NO;
                break;
            }
        }
        
        if (!res) {
            @throw [NSException exceptionWithName:NSStringFromClass(self.class) reason:@"requests must be none empty and kind of TCHTTPRequest Class !" userInfo:nil];
            return nil;
        }
        self.requestArray = requests;
        self.finishDic = NSMutableDictionary.dictionary;
    }
    return self;
}

#pragma mark -

- (BOOL)start:(NSError **)error
{
    NSParameterAssert(self.requestAgent);
    
    if (nil != self.requestAgent && [self.requestAgent respondsToSelector:@selector(addObserver:forRequest:)]) {
    
        self.state = kTCHTTPRequestStateExecuting;
        [self.requestAgent addObserver:self.observer forRequest:self];
        
        BOOL res = YES;
        for (TCHTTPRequest *request in self.requestArray) {
   
            if (nil == request.requestAgent) {
                request.requestAgent = self.requestAgent;
            }
            request.observer = self;
            request.delegate = self;
            
            NSError *error = nil;
            if (![request start:&error]) {
                NSLog(@"%@", error);
                res = NO;
                break;
            }
        }
        
        if (!res) {
            [self cancel];
            self.state = kTCHTTPRequestStateFinished;
            if (self.isRetainByRequestPool) {
                [self.requestAgent removeRequestObserver:self.observer forIdentifier:self.requestIdentifier];
            }
            
            if (NULL != error) {
                *error = [NSError errorWithDomain:NSStringFromClass(self.class)
                                             code:-1
                                         userInfo:@{NSLocalizedFailureReasonErrorKey: @"start batch request failed.",
                                                    NSLocalizedDescriptionKey: @"any bacth request item start failed."}];
            }
        }
        
        return res;
    }
    
    return NO;
}

- (void)cancel
{
    if (self.isCancelled) {
        return;
    }
    
    self.isCancelled = YES;
    
    for (TCHTTPRequest *request in self.requestArray) {
        request.delegate = nil;
        request.resultBlock = nil;
        request.constructingBodyBlock = nil;
        [request cancel];
    }
}


#pragma mark - TCHTTPRequestDelegate

- (void)processRequest:(TCHTTPRequest *)request success:(BOOL)success
{
    self.finishDic[@((NSUInteger)request)] = @(success);
    if (success) {
        
        if ([self checkFinished]) {
            [self requestCallback:YES];
        }
    } else {

        [self cancel];
        [self requestCallback:NO];
    }
}

- (void)requestCallback:(BOOL)isValid
{
    self.state = kTCHTTPRequestStateFinished;
    // remove from pool
    if (self.isRetainByRequestPool) {
        [self.requestAgent removeRequestObserver:self.observer forIdentifier:self.requestIdentifier];
    }
    
    [self requestResponded:isValid finish:nil clean:YES];
}

- (BOOL)checkFinished
{
    BOOL finished = YES;
    for (TCHTTPRequest *request in self.requestArray) {
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
    return [NSString stringWithFormat:@"🌍🌍🌍 %@: %@\n", NSStringFromClass(self.class), self.requestArray];
}

@end
