//
//  TCBaseResponseValidator.m
//  TCKit
//
//  Created by dake on 13-3-27.
//  Copyright (c) 2013年 dake. All rights reserved.
//

#import "TCBaseResponseValidator.h"

#if ! __has_feature(objc_arc)
#error this file is ARC only. Either turn on ARC for the project or use -fobjc-arc flag
#endif

@implementation TCBaseResponseValidator


#pragma mark - TCHTTPResponseValidator

+ (NSDictionary<NSString *, NSArray<NSNumber *> *> *)errorFilter
{
    return nil;
}

- (BOOL)validateHTTPResponse:(id)obj fromCache:(BOOL)fromCache
{
    self.success = nil != obj;
    self.data = obj;
    self.error = nil;
    
    return self.success;
}

- (void)reset
{
    self.data = nil;
    self.success = NO;
    self.successMsg = nil;
    self.error = nil;
}

- (NSString *)promptToShow
{
    return [self promptToShow:NULL];
}

- (NSString *)promptToShow:(BOOL *)success
{
    if (NULL != success) {
        *success = self.success;
    }
    
    if (self.success) {
        if (self.successMsg.length > 0) {
            return self.successMsg;
        }
    } else {
        NSError *err = self.error;
        if (nil != err) {
            typeof(_errorFilter) sFilter = self.class.errorFilter;
            typeof(_errorFilter) filter = self.errorFilter;
            
            if (filter.count < 1) {
                filter = sFilter;
                
            } else if (sFilter.count > 0) {
                NSMutableDictionary *dic = sFilter.mutableCopy;
                [dic addEntriesFromDictionary:filter];
                filter = dic;
            }
            
            if (filter.count > 0) {
                if ([filter.allKeys containsObject:err.domain] &&
                    (filter[err.domain].count < 1 || [filter[err.domain] containsObject:@(err.code)]) &&
                    err.localizedDescription.length > 0) {
                    
                    return err.localizedDescription;
                }
            } else if (err.localizedDescription.length > 0) {
                return err.localizedDescription;
            }
        }
    }
    
    return nil;
}

@end
