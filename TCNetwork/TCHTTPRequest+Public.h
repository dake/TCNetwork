//
//  TCHTTPRequest+Public.h
//  TCKit
//
//  Created by cdk on 15/3/30.
//  Copyright (c) 2015年 Dake. All rights reserved.
//

#import "TCHTTPRequest.h"

@interface TCHTTPRequest (Public)

+ (instancetype)requestWithMethod:(TCHTTPRequestMethod)method;
+ (instancetype)cacheRequestWithMethod:(TCHTTPRequestMethod)method;
+ (instancetype)batchRequestWithRequests:(NSArray<__kindof TCHTTPRequest *> *)requests;

@end
