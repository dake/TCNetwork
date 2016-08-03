//
//  TCHTTPCachePolicy.m
//  TCKit
//
//  Created by dake on 16/2/29.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "TCHTTPCachePolicy.h"
#import "TCHTTPRequestHelper.h"
#import "TCHTTPStreamPolicy.h"


NSInteger const kTCHTTPRequestCacheNeverExpired = -1;


@implementation TCHTTPCachePolicy
{
    @private
    NSDictionary *_parametersForCachePathFilter;
    id _sensitiveDataForCachePathFilter;
    NSString *_cacheFileName;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _shouldCacheResponse = YES;
        _shouldCacheEmptyResponse = YES;
    }
    return self;
}


- (void)setCachePathFilterWithRequestParameters:(NSDictionary *)parameters
                                  sensitiveData:(NSObject<NSCopying> *)sensitiveData;
{
    _parametersForCachePathFilter = parameters.copy;
    _sensitiveDataForCachePathFilter = sensitiveData.copy;
}

- (NSString *)cacheFileName
{
    if (nil != _cacheFileName) {
        return _cacheFileName;
    }
    
    NSString *requestUrl = nil;
    if (nil != _request.requestAgent && [_request.requestAgent respondsToSelector:@selector(buildRequestUrlForRequest:)]) {
        requestUrl = [_request.requestAgent buildRequestUrlForRequest:_request];
    } else {
        requestUrl = _request.apiUrl;
    }
    NSParameterAssert(requestUrl);
    
    static NSString *const s_fmt = @"Method:%zd RequestUrl:%@ Parames:%@ Sensitive:%@";
    NSString *cacheKey = [NSString stringWithFormat:s_fmt, _request.method, requestUrl, _parametersForCachePathFilter, _sensitiveDataForCachePathFilter];
    _parametersForCachePathFilter = nil;
    _sensitiveDataForCachePathFilter = nil;
    _cacheFileName = [TCHTTPRequestHelper MD5_32:cacheKey];
    
    return _cacheFileName;
}

- (NSString *)cacheFilePath
{
    if (_request.method == kTCHTTPMethodDownload) {
        return _request.streamPolicy.downloadDestinationPath;
    }
    
    NSString *path = nil;
    if (nil != _request.requestAgent && [_request.requestAgent respondsToSelector:@selector(cachePathForResponse)]) {
        path = [_request.requestAgent cachePathForResponse];
    }
    
    NSParameterAssert(path);
    
    if (nil == path) {
        path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"TCHTTPCache.TCNetwork.TCKit"];
    }
    if ([self createDiretoryForCachePath:path]) {
        return [path stringByAppendingPathComponent:self.cacheFileName];
    }
    
    return nil;
}


- (BOOL)validateResponseObjectForCache
{
    id responseObject = _request.responseObject;
    if (nil == responseObject || (NSNull *)responseObject == NSNull.null) {
        return NO;
    }
    
    if (!self.shouldCacheEmptyResponse) {
        if ([responseObject isKindOfClass:NSDictionary.class]) {
            return [(NSDictionary *)responseObject count] > 0;
        } else if ([responseObject isKindOfClass:NSArray.class]) {
            return [(NSArray *)responseObject count] > 0;
        } else if ([responseObject isKindOfClass:NSString.class]) {
            return [(NSString *)responseObject length] > 0;
        }
    }
    
    return YES;
}

- (BOOL)shouldWriteToCache
{
    return _request.method != kTCHTTPMethodDownload &&
    self.shouldCacheResponse &&
    self.cacheTimeoutInterval != 0 &&
    self.validateResponseObjectForCache;
}

- (TCCachedRespState)cacheState
{
    NSString *path = self.cacheFilePath;
    if (nil == path) {
        return kTCCachedRespNone;
    }
    
    BOOL isDir = NO;
    NSFileManager *fileMngr = NSFileManager.defaultManager;
    if (![fileMngr fileExistsAtPath:path isDirectory:&isDir] || isDir) {
        return kTCCachedRespNone;
    }
    
    NSDictionary *attributes = [fileMngr attributesOfItemAtPath:path error:NULL];
    if (nil == attributes || attributes.count < 1) {
        return kTCCachedRespExpired;
    }
    
    NSTimeInterval timeIntervalSinceNow = attributes.fileModificationDate.timeIntervalSinceNow;
    if (timeIntervalSinceNow >= 0) { // deal with wrong system time
        return kTCCachedRespExpired;
    }
    
    NSTimeInterval cacheTimeoutInterval = self.cacheTimeoutInterval;
    
    if (cacheTimeoutInterval < 0 || -timeIntervalSinceNow < cacheTimeoutInterval) {
        if (_request.method == kTCHTTPMethodDownload) {
            if (![fileMngr fileExistsAtPath:path]) {
                return kTCCachedRespNone;
            }
        }
        
        return kTCCachedRespValid;
    }
    
    return kTCCachedRespExpired;
}

- (BOOL)isCacheValid
{
    return self.cacheState == kTCCachedRespValid;
}

- (NSDate *)cacheDate
{
    TCCachedRespState state = self.cacheState;
    if (kTCCachedRespExpired == state || kTCCachedRespValid == state) {
        return [NSFileManager.defaultManager attributesOfItemAtPath:self.cacheFilePath error:NULL].fileModificationDate;
    }
    
    return nil;
}

- (BOOL)isDataFromCache
{
    return nil != _cachedResponse;
}


#pragma mark -

- (BOOL)createDiretoryForCachePath:(NSString *)path
{
    if (nil == path) {
        return NO;
    }
    
    NSFileManager *fileManager = NSFileManager.defaultManager;
    BOOL isDir = NO;
    if ([fileManager fileExistsAtPath:path isDirectory:&isDir]) {
        if (isDir) {
            return YES;
        } else {
            [fileManager removeItemAtPath:path error:NULL];
        }
    }
    
    if ([fileManager createDirectoryAtPath:path
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:NULL]) {
        
        [[NSURL fileURLWithPath:path] setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:NULL];
        return YES;
    }
    
    return NO;
}

@end
