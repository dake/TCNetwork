//
//  TCHTTPRequestCenter+Private.h
//  TCKit
//
//  Created by dake on 16/3/27.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "TCHTTPRequestCenter.h"

@interface TCHTTPRequestCenter (Private)

- (void)loadResumeData:(void(^)(NSData *data))finish forPolicy:(TCHTTPStreamPolicy *)policy;
- (void)clearCachedResumeDataForRequest:(id<TCHTTPReqAgentDelegate>)request;


#pragma mark - Making HTTP Requests

//
// request method below, will not auto start
//
- (id<TCHTTPRequest>)requestWithMethod:(TCHTTPMethod)method apiUrl:(NSString *)apiUrl host:(NSString *)host;
- (id<TCHTTPRequest>)requestWithMethod:(TCHTTPMethod)method cachePolicy:(TCHTTPCachePolicy *)policy apiUrl:(NSString *)apiUrl host:(NSString *)host;
- (id<TCHTTPRequest>)requestForDownload:(NSString *)url streamPolicy:(TCHTTPStreamPolicy *)streamPolicy cachePolicy:(TCHTTPCachePolicy *)cachePolicy;
- (id<TCHTTPRequest>)requestForUploadTo:(NSString *)url streamPolicy:(TCHTTPStreamPolicy *)streamPolicy;
- (id<TCHTTPRequest>)batchRequestWithRequests:(NSArray<id<TCHTTPRequest>> *)requests;

@end
