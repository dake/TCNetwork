//
//  TCHTTPTimerPolicy.h
//  TCKit
//
//  Created by dake on 16/3/21.
//  Copyright © 2016年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>



typedef NS_ENUM(NSInteger, TCHTTPTimerType) {
    kTCHTTPTimerTypePolling = 0,
    kTCHTTPTimerTypeRetry,
    kTCHTTPTimerTypeDelay,
};

extern NSTimeInterval kTCHTTPTimerIntervalEnd;

/**
 @brief	ignore cache reading by default
 */
@interface TCHTTPTimerPolicy : NSObject
{
    @protected
    NSTimer *_timer;
}

@property (atomic, assign, readonly) BOOL isValid;
@property (nonatomic, assign, readonly) NSUInteger polledCount;
@property (atomic, assign, readonly) BOOL finished;

@property (nonatomic, assign, readonly) TCHTTPTimerType timerType;

@property (nonatomic, copy) NSTimeInterval (^intervalFunc)(TCHTTPTimerPolicy *policy, NSUInteger index); // return >= 0: continue, return < 0: break


// for polling
+ (instancetype)pollingPolicyWithIntervals:(NSTimeInterval (^)(TCHTTPTimerPolicy *policy, NSUInteger index))intervalFunc;

// for delay
+ (instancetype)delayPolicyWithInterval:(NSTimeInterval)interval;

// for retry
+ (instancetype)retryPolicyWithIntervals:(NSTimeInterval (^)(TCHTTPTimerPolicy *policy, NSUInteger index))intervalFunc;

@end



