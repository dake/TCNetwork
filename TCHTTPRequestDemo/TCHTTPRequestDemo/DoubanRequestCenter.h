//
//  DoubanRequestCenter.h
//  TCHTTPRequestDemo
//
//  Created by cdk on 15/4/9.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import "TCHTTPRequestCenter.h"

@interface DoubanRequestCenter : TCHTTPRequestCenter

// fetch book info for id with caching response
- (id<TCHTTPRequest>)fetchBookInfoForID:(NSString *)bookID beforeRun:(void(^)(id<TCHTTPRequest> request))beforeRun;

// search books for keyword without caching response
- (id<TCHTTPRequest>)searchBookListForKeyword:(NSString *)keyword beforeRun:(void(^)(id<TCHTTPRequest> request))beforeRun;

@end
