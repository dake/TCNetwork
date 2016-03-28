//
//  TCHTTPTimerPolicy+TCHTTPRequest.h
//  TCKit
//
//  Created by dake on 16/3/21.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "TCHTTPTimerPolicy.h"

@protocol TCHTTPTimerDelegate;
@interface TCHTTPTimerPolicy (TCHTTPRequest)

@property (atomic, assign, readwrite) BOOL isValid;
@property (nonatomic, assign, readwrite) NSUInteger polledCount;
@property (atomic, assign, readwrite) BOOL finished;
@property (nonatomic, weak) id<TCHTTPTimerDelegate> delegate;


- (void)invalidate; // stop timer, cancel executing request, only called by request.

/**
 @brief	go to next polling, called by request
 
 @return YES: entry polling, NO: finished
 */
- (BOOL)forward;

- (BOOL)canForward;

- (BOOL)isTicking;

- (BOOL)needStartTimer;
- (BOOL)checkForwardForRequest:(BOOL)success;

@end


@protocol TCHTTPTimerDelegate <NSObject>

@required
- (BOOL)timerRequestForPolicy:(TCHTTPTimerPolicy *)policy;
- (void)requestResponded:(BOOL)isValid clean:(BOOL)clean;


@end
