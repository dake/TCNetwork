//
//  TCHTTPRequestCenter+Private.m
//  TCKit
//
//  Created by dake on 16/3/27.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "TCHTTPRequestCenter+Private.h"
#import "TCHTTPRequest+Public.h"
#import "NSURLSessionTask+TCResumeDownload.h"


@implementation TCHTTPRequestCenter (Private)

- (void)loadResumeData:(void(^)(NSData *data))finish forPolicy:(TCHTTPStreamPolicy *)policy
{
    if (nil == finish) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        @autoreleasepool {
            NSData *data = [NSURLSessionTask tc_resumeDataWithIdentifier:policy.downloadIdentifier inDirectory:policy.downloadResumeCacheDirectory];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                finish(data);
            });
        }
    });
}

- (void)clearCachedResumeDataForRequest:(id<TCHTTPReqAgentDelegate>)request
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        @autoreleasepool {
            [request.requestTask tc_purgeResumeData];
        }
    });
}


#pragma mark - Making HTTP Requests

- (id<TCHTTPRequest>)requestWithMethod:(TCHTTPMethod)method apiUrl:(NSString *)apiUrl host:(NSString *)host
{
    return [self requestWithMethod:method cachePolicy:nil apiUrl:apiUrl host:host];
}

- (id<TCHTTPRequest>)requestWithMethod:(TCHTTPMethod)method cachePolicy:(TCHTTPCachePolicy *)policy apiUrl:(NSString *)apiUrl host:(NSString *)host
{
    TCHTTPRequest *request = nil == policy ? [TCHTTPRequest requestWithMethod:method] : [TCHTTPRequest cacheRequestWithMethod:method cachePolicy:policy];
    request.requestAgent = self;
    request.apiUrl = apiUrl;
    request.baseUrl = host;
    
    return request;
}

- (id<TCHTTPRequest>)batchRequestWithRequests:(NSArray<id<TCHTTPRequest>> *)requests
{
    NSParameterAssert(requests);
    if (requests.count < 1) {
        return nil;
    }
    
    TCHTTPRequest *request = [TCHTTPRequest batchRequestWithRequests:requests];
    request.requestAgent = self;
    
    return request;
}

- (id<TCHTTPRequest>)requestForDownload:(NSString *)url streamPolicy:(TCHTTPStreamPolicy *)streamPolicy cachePolicy:(TCHTTPCachePolicy *)cachePolicy
{
    NSParameterAssert(url);
    NSParameterAssert(streamPolicy);
    NSParameterAssert(streamPolicy.downloadDestinationPath);
    
    if (nil == url || nil == streamPolicy || nil == streamPolicy.downloadDestinationPath) {
        return nil;
    }
    
    id<TCHTTPRequest> request = [self requestWithMethod:kTCHTTPMethodDownload cachePolicy:cachePolicy apiUrl:url host:nil];
    request.streamPolicy = streamPolicy;
    
    return request;
}

- (id<TCHTTPRequest>)requestForUploadTo:(NSString *)url streamPolicy:(TCHTTPStreamPolicy *)streamPolicy
{
    NSParameterAssert(url);
    NSParameterAssert(streamPolicy);
    NSParameterAssert(streamPolicy.constructingBodyBlock);
    
    if (nil == url || nil == streamPolicy || nil == streamPolicy.constructingBodyBlock) {
        return nil;
    }
    
    id<TCHTTPRequest> request = [self requestWithMethod:kTCHTTPMethodPost apiUrl:url host:nil];
    request.streamPolicy = streamPolicy;
    
    return request;
}


@end
