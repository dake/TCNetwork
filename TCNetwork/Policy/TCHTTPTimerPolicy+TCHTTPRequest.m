//
//  TCHTTPTimerPolicy+TCHTTPRequest.m
//  TCKit
//
//  Created by dake on 16/3/21.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "TCHTTPTimerPolicy+TCHTTPRequest.h"

@implementation TCHTTPTimerPolicy (TCHTTPRequest)

@dynamic isValid;
@dynamic polledCount;
@dynamic finished;
@dynamic delegate;


- (BOOL)needStartTimer
{
    return self.polledCount < 1 && !self.isValid && self.canForward;
}

- (BOOL)checkForwardForRequest:(BOOL)success
{
    if (self.timerType == kTCHTTPTimerTypeRetry && self.isValid && success) {
        [self complete:YES];
        return NO;
    }
    return self.canForward;
}

- (BOOL)canForward
{
    if (nil == self.intervalFunc || self.intervalFunc(self, self.polledCount) < 0) {
        [self complete:YES];
        return NO;
    } else {
        self.isValid = YES;
    }
    
    return YES;
}

- (BOOL)forward
{
    if (!self.isValid) {
        return NO;
    }
    
    NSParameterAssert(self.intervalFunc);
    
    NSTimeInterval interval = self.intervalFunc(self, self.polledCount++);
    if (interval > 0) {
        [self fireTimerWithInterval:interval];
        
    } else if (0 == interval) {
        [self fireRequest:nil];
    } else {
        [self complete:YES];
        return NO;
    }
    
    return YES;
}

- (void)fireTimerWithInterval:(NSTimeInterval)interval
{
    _timer = [NSTimer timerWithTimeInterval:interval target:self selector:@selector(fireRequest:) userInfo:nil repeats:NO];
    [NSRunLoop.mainRunLoop addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)fireRequest:(NSTimer *)timer
{
    _timer = nil;
    
    if (nil == self.delegate || ![self.delegate timerRequestForPolicy:self]) {
        [self complete:NO];
        [self.delegate requestResponded:NO clean:YES];
    }
}


- (void)invalidate
{
    if (!self.isValid) {
        return;
    }
    
    [_timer invalidate], _timer = nil;
    [self complete:NO];
}

- (BOOL)isTicking
{
    return nil != _timer && _timer.valid;
}

- (void)complete:(BOOL)finish
{
    self.intervalFunc = nil;
    self.isValid = NO;
    self.finished = finish;
}


@end
