//
//  TCHTTPCachePolicy.m
//  TCKit
//
//  Created by dake on 16/2/29.
//  Copyright © 2016年 dake. All rights reserved.
//

#import "TCHTTPCachePolicy.h"
#import "TCHTTPRequestHelper.h"


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
    NSString *cacheKey = [NSString stringWithFormat:s_fmt, _request.requestMethod, requestUrl, _parametersForCachePathFilter, _sensitiveDataForCachePathFilter];
    _parametersForCachePathFilter = nil;
    _sensitiveDataForCachePathFilter = nil;
    _cacheFileName = [TCHTTPRequestHelper MD5_32:cacheKey];
    
    return _cacheFileName;
}

- (NSString *)cacheFilePath
{
    if (_request.requestMethod == kTCHTTPRequestMethodDownload) {
        return _request.downloadDestinationPath;
    }
    
    NSString *path = nil;
    if (nil != _request.requestAgent && [_request.requestAgent respondsToSelector:@selector(cachePathForResponse)]) {
        path = [_request.requestAgent cachePathForResponse];
    }
    
    NSParameterAssert(path);
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
    return _request.requestMethod != kTCHTTPRequestMethodDownload &&
    self.shouldCacheResponse &&
    self.cacheTimeoutInterval != 0 &&
    self.validateResponseObjectForCache;
}

- (TCHTTPCachedResponseState)cacheState
{
    NSString *path = self.cacheFilePath;
    if (nil == path) {
        return kTCHTTPCachedResponseStateNone;
    }
    
    BOOL isDir = NO;
    NSFileManager *fileMngr = NSFileManager.defaultManager;
    if (![fileMngr fileExistsAtPath:path isDirectory:&isDir] || isDir) {
        return kTCHTTPCachedResponseStateNone;
    }
    
    NSDictionary *attributes = [fileMngr attributesOfItemAtPath:path error:NULL];
    if (nil == attributes || attributes.count < 1) {
        return kTCHTTPCachedResponseStateExpired;
    }
    
    NSTimeInterval timeIntervalSinceNow = attributes.fileModificationDate.timeIntervalSinceNow;
    if (timeIntervalSinceNow >= 0) { // deal with wrong system time
        return kTCHTTPCachedResponseStateExpired;
    }
    
    NSTimeInterval cacheTimeoutInterval = self.cacheTimeoutInterval;
    
    if (cacheTimeoutInterval < 0 || -timeIntervalSinceNow < cacheTimeoutInterval) {
        if (_request.requestMethod == kTCHTTPRequestMethodDownload) {
            if (![fileMngr fileExistsAtPath:path]) {
                return kTCHTTPCachedResponseStateNone;
            }
        }
        
        return kTCHTTPCachedResponseStateValid;
    }
    
    return kTCHTTPCachedResponseStateExpired;
}

- (BOOL)isCacheValid
{
    return self.cacheState == kTCHTTPCachedResponseStateValid;
}

- (BOOL)isDataFromCache
{
    return nil != _cachedResponse;
}


#pragma mark - cached response access

- (void)writeToCache:(id)response finish:(dispatch_block_t)block
{
    __weak typeof(self) wSelf = self;
    dispatch_async(self.responseQueue, ^{
        @autoreleasepool {
            if (wSelf.shouldWriteToCache) {
                NSString *path = wSelf.cacheFilePath;
                if (nil != path && ![NSKeyedArchiver archiveRootObject:response toFile:path]) {
                    NSAssert(false, @"write response failed.");
                }
            }
            
            if (nil != block) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block();
                });
            }
        }
    });
}

- (void)cachedResponseWithoutValidate:(void(^)(id response))result
{
    NSParameterAssert(result);
    
    if (nil == result) {
        return;
    }
    
    if (nil == _cachedResponse) {
        NSString *path = self.cacheFilePath;
        if (nil == path) {
            result(nil);
            return;
        }
        
        NSFileManager *fileMngr = NSFileManager.defaultManager;
        BOOL isDir = NO;
        if (![fileMngr fileExistsAtPath:path isDirectory:&isDir] || isDir) {
            result(nil);
            return;
        }
        
        if (_request.requestMethod == kTCHTTPRequestMethodDownload) {
            _cachedResponse = path;
            result(_cachedResponse);
        } else {
            __weak typeof(self) wSelf = self;
            dispatch_async(self.responseQueue, ^{
                @autoreleasepool {
                    id cachedResponse = nil;
                    @try {
                        cachedResponse = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
                    }
                    @catch (NSException *exception) {
                        cachedResponse = nil;
                        NSLog(@"%@", exception);
                    }
                    @finally {
                        __strong typeof(wSelf) sSelf = wSelf;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            sSelf.cachedResponse = cachedResponse;
                            result(cachedResponse);
                        });
                    }
                }
            });
        }
    } else {
        result(_cachedResponse);
    }
}


#pragma mark -

- (dispatch_queue_t)responseQueue
{
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
}

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
