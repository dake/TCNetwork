//
//  TCHTTPTimerPolicy.m
//  TCKit
//
//  Created by dake on 16/3/21.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "TCHTTPTimerPolicy.h"


NSTimeInterval kTCHTTPTimerIntervalEnd = -1;

@interface TCHTTPTimerPolicy ()

@property (atomic, assign, readwrite) BOOL isValid;
@property (nonatomic, assign, readwrite) NSUInteger polledCount;
@property (atomic, assign, readwrite) BOOL finished;
@property (nonatomic, weak) id delegate;

@end


@implementation TCHTTPTimerPolicy
{
    @private
    TCHTTPTimerType _timerType;
}

+ (instancetype)pollingPolicyWithIntervals:(NSTimeInterval (^)(TCHTTPTimerPolicy *policy, NSUInteger index))intervalFunc
{
    NSParameterAssert(intervalFunc);
    if (nil == intervalFunc) {
        return nil;
    }
    
    TCHTTPTimerPolicy *policy = [[self alloc] init];
    policy.intervalFunc = intervalFunc;
    policy->_timerType = kTCHTTPTimerTypePolling;
    return policy;
}

+ (instancetype)delayPolicyWithInterval:(NSTimeInterval)interval
{
    NSAssert(interval > 0, @"delay interval must > 0");
    
    if (interval <= 0) {
        return nil;
    }
    
    TCHTTPTimerPolicy *policy = [[self alloc] init];
    policy.intervalFunc = ^NSTimeInterval (TCHTTPTimerPolicy *policy, NSUInteger index) {
        return 0 == index ? interval : kTCHTTPTimerIntervalEnd;
    };
    policy->_timerType = kTCHTTPTimerTypeDelay;
    return policy;
}

+ (instancetype)retryPolicyWithIntervals:(NSTimeInterval (^)(TCHTTPTimerPolicy *policy, NSUInteger index))intervalFunc
{
    NSParameterAssert(intervalFunc);
    if (nil == intervalFunc) {
        return nil;
    }
    
    TCHTTPTimerPolicy *policy = [[self alloc] init];
    policy.intervalFunc = intervalFunc;
    policy->_timerType = kTCHTTPTimerTypeRetry;
    return policy;
}


@end

