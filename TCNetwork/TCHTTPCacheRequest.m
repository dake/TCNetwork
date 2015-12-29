//
//  TCHTTPCacheRequest.m
//  TCKit
//
//  Created by dake on 15/3/16.
//  Copyright (c) 2015年 Dake. All rights reserved.
//

#import "TCHTTPCacheRequest.h"
#import "TCHTTPRequestHelper.h"


@interface TCHTTPCacheRequest ()

@property (nonatomic, strong) id cachedResponse;

@end

@implementation TCHTTPCacheRequest
{
    @private
    NSDictionary *_parametersForCachePathFilter;
    id _sensitiveDataForCachePathFilter;
    NSString *_cacheFileName;
}

@dynamic isForceStart;

@synthesize shouldIgnoreCache = _shouldIgnoreCache;
@synthesize shouldCacheResponse = _shouldCacheResponse;
@synthesize cacheTimeoutInterval = _cacheTimeoutInterval;
@synthesize shouldExpiredCacheValid = _shouldExpiredCacheValid;
@synthesize shouldCacheEmptyResponse = _shouldCacheEmptyResponse;


+ (dispatch_queue_t)responseQueue
{
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
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

- (BOOL)isDataFromCache
{
    return nil != _cachedResponse;
}

- (id<NSCoding>)responseObject
{
    if (nil != _cachedResponse) {
        return _cachedResponse;
    }
    return [super responseObject];
}

- (NSDictionary *)parametersForCachePathFilter
{
    return _parametersForCachePathFilter ?: self.parameters;
}

- (void)setCachePathFilterWithRequestParameters:(NSDictionary *)parameters
                                  sensitiveData:(NSObject<NSCopying> *)sensitiveData;
{
    _parametersForCachePathFilter = parameters.copy;
    _sensitiveDataForCachePathFilter = sensitiveData.copy;
}


- (BOOL)validateResponseObjectForCache
{
    id responseObject = self.responseObject;
    if (nil == responseObject || (NSNull *)responseObject == NSNull.null) {
        return NO;
    }
    
    if (!_shouldCacheEmptyResponse) {
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

- (void)requestResponseReset
{
    _cachedResponse = nil;
}

- (void)requestResponded:(BOOL)isValid finish:(dispatch_block_t)finish clean:(BOOL)clean
{
    // !!!: must be called before self.validateResponseObject called, below
    [self requestResponseReset];
    
    if (isValid) {
        __weak typeof(self) wSelf = self;
        dispatch_async(self.class.responseQueue, ^{
            @autoreleasepool {
                __strong typeof(wSelf) sSelf = wSelf;
                
                if (sSelf.requestMethod != kTCHTTPRequestMethodDownload && sSelf.shouldCacheResponse && sSelf.cacheTimeoutInterval != 0 && sSelf.validateResponseObjectForCache) {
                    NSString *path = sSelf.cacheFilePath;
                    if (nil != path && ![NSKeyedArchiver archiveRootObject:sSelf.responseObject toFile:path]) {
                        NSAssert(false, @"write response failed.");
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [sSelf callSuperRequestResponded:isValid finish:finish clean:clean];
                });
            }
        });
    } else {
        [super requestResponded:isValid finish:finish clean:clean];
    }
}

- (void)callSuperRequestResponded:(BOOL)isValid finish:(dispatch_block_t)finish clean:(BOOL)clean
{
    [super requestResponded:isValid finish:finish clean:clean];
}


#pragma mark -

- (void)cachedResponseWithoutValidate:(void(^)(id response))result
{
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
        
        if (self.requestMethod == kTCHTTPRequestMethodDownload) {
            _cachedResponse = path;
            result(_cachedResponse);
        } else {
            __weak typeof(self) wSelf = self;
            dispatch_async(self.class.responseQueue, ^{
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

- (void)cachedResponseByForce:(BOOL)force result:(void(^)(id response, TCHTTPCachedResponseState state))result
{
    if (nil == result) {
        return;
    }
    
    TCHTTPCachedResponseState cacheState = self.cacheState;
    
    if (cacheState == kTCHTTPCachedResponseStateValid || (force && cacheState != kTCHTTPCachedResponseStateNone)) {
        __weak typeof(self) wSelf = self;
        [self cachedResponseWithoutValidate:^(id response) {
            if (nil != response && nil != wSelf.responseValidator && [wSelf.responseValidator respondsToSelector:@selector(validateHTTPResponse:fromCache:)]) {
                [wSelf.responseValidator validateHTTPResponse:response fromCache:YES];
            }
            
            result(response, cacheState);
        }];
        
        return;
    }

    result(nil, cacheState);
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
    
    if (self.cacheTimeoutInterval < 0 || -timeIntervalSinceNow < self.cacheTimeoutInterval) {
        if (self.requestMethod == kTCHTTPRequestMethodDownload) {
            if (![fileMngr fileExistsAtPath:path]) {
                return kTCHTTPCachedResponseStateNone;
            }
        }
        
        return kTCHTTPCachedResponseStateValid;
    }
    
    return kTCHTTPCachedResponseStateExpired;
}

- (void)cacheRequestCallbackWithoutFiring:(BOOL)notFire
{
    BOOL isValid = YES;
    if (nil != self.responseValidator && [self.responseValidator respondsToSelector:@selector(validateHTTPResponse:fromCache:)]) {
        isValid = [self.responseValidator validateHTTPResponse:self.responseObject fromCache:YES];
    }
    
    if (notFire) {
        __weak typeof(self) wSelf = self;
        [super requestResponded:isValid finish:^{
            // remove from pool
            if (wSelf.isRetainByRequestPool) {
                [wSelf.requestAgent removeRequestObserver:wSelf.observer forIdentifier:wSelf.requestIdentifier];
            }
        } clean:notFire];
    } else if (isValid) {
        [super requestResponded:isValid finish:nil clean:notFire];
    }
}

- (BOOL)callSuperStart
{
    return [super start:NULL];
}


- (BOOL)start:(NSError **)error
{
    if (self.isForceStart) {
        return [self forceStart:error];
    }
    
    if (self.shouldIgnoreCache) {
        return [super start:error];
    }
    
    TCHTTPCachedResponseState state = self.cacheState;
    if (state == kTCHTTPCachedResponseStateValid || (self.shouldExpiredCacheValid && state != kTCHTTPCachedResponseStateNone)) {
        // !!!: add to pool to prevent self dealloc before cache respond
        [self.requestAgent addObserver:self.observer forRequest:self];
        __weak typeof(self) wSelf = self;
        [self cachedResponseWithoutValidate:^(id response) {
            
            if (nil == response) {
                [wSelf callSuperStart];
                return;
            }
            
            __strong typeof(wSelf) sSelf = wSelf;
            if (kTCHTTPCachedResponseStateValid == state) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [sSelf cacheRequestCallbackWithoutFiring:YES];
                });
            } else if (wSelf.shouldExpiredCacheValid) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [sSelf cacheRequestCallbackWithoutFiring:![sSelf callSuperStart]];
                });
            }
        }];
        
        return kTCHTTPCachedResponseStateValid == state ? YES : [super canStart:error];
    }
    
    return [super start:error];
}

- (BOOL)forceStart:(NSError **)error
{
    self.isForceStart = YES;
    
    if (!self.shouldIgnoreCache) {
        TCHTTPCachedResponseState state = self.cacheState;
        if (kTCHTTPCachedResponseStateExpired == state || kTCHTTPCachedResponseStateValid == state) {
            // !!!: add to pool to prevent self dealloc before cache respond
            [self.requestAgent addObserver:self.observer forRequest:self];
            
            __weak typeof(self) wSelf = self;
            [self cachedResponseWithoutValidate:^(id response) {
                __strong typeof(wSelf) sSelf = wSelf;
                dispatch_async(dispatch_get_main_queue(), ^{
                    BOOL ret = [sSelf callSuperStart];
                    if (nil != response) {
                        [sSelf cacheRequestCallbackWithoutFiring:!ret];
                    }
                });
            }];
            
            return [super canStart:error];
        }
    }
    
    return [super start:error];
}


#pragma mark -

- (NSString *)cacheFileName
{
    if (nil != _cacheFileName) {
        return _cacheFileName;
    }
    
    NSString *requestUrl = nil;
    if (nil != self.requestAgent && [self.requestAgent respondsToSelector:@selector(buildRequestUrlForRequest:)]) {
        requestUrl = [self.requestAgent buildRequestUrlForRequest:self];
    } else {
        requestUrl = self.apiUrl;
    }
    NSParameterAssert(requestUrl);

    NSString *cacheKey = [NSString stringWithFormat:@"Method:%zd RequestUrl:%@ Parames:%@ Sensitive:%@", self.requestMethod, requestUrl, self.parametersForCachePathFilter, _sensitiveDataForCachePathFilter];
    _parametersForCachePathFilter = nil;
    _sensitiveDataForCachePathFilter = nil;
    _cacheFileName = [TCHTTPRequestHelper MD5_32:cacheKey];
    
    return _cacheFileName;
}

- (NSString *)cacheFilePath
{
    if (self.requestMethod == kTCHTTPRequestMethodDownload) {
        return self.downloadDestinationPath;
    }
    
    NSString *path = nil;
    if (nil != self.requestAgent && [self.requestAgent respondsToSelector:@selector(cachePathForResponse)]) {
        path = [self.requestAgent cachePathForResponse];
    }
    
    NSParameterAssert(path);
    if ([self.class createDiretoryForCachePath:path]) {
        return [path stringByAppendingPathComponent:self.cacheFileName];
    }
    
    return nil;
}

+ (BOOL)createDiretoryForCachePath:(NSString *)path
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
