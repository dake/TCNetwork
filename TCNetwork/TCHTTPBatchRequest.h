//
//  TCHTTPBatchRequest.h
//  TCKit
//
//  Created by dake on 15/3/26.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import "TCHTTPRequest.h"

NS_CLASS_AVAILABLE_IOS(7_0) @interface TCHTTPBatchRequest : TCHTTPRequest

@property (nonatomic, copy, readwrite) NSArray<__kindof TCHTTPRequest *> *requestArray;

+ (instancetype)requestWithRequests:(NSArray<__kindof TCHTTPRequest *> *)requests;
- (instancetype)initWithRequests:(NSArray<__kindof TCHTTPRequest *> *)requests;

- (BOOL)start:(NSError **)error;


@end
