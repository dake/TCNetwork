//
//  TCHTTPRespValidator.h
//  TCKit
//
//  Created by dake on 15/3/15.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TCHTTPRespValidator <NSObject>

@required

@property (nonatomic, strong) id data;
@property (nonatomic, assign) BOOL success;
@property (nonatomic, copy) NSString *successMsg;
@property (nonatomic, strong) NSError *error;

@property (nonatomic, strong) NSDictionary<NSString *, NSArray<NSNumber *> *> *errorFilter;


+ (NSDictionary<NSString *, NSArray<NSNumber *> *> *)errorFilter;

- (void)reset;
- (NSString *)promptToShow:(BOOL *)success;
- (NSString *)promptToShow;

@optional

@property (nonatomic, assign) NSUInteger totalNum;
@property (nonatomic, assign) NSUInteger pageIndex;
@property (nonatomic, assign) NSUInteger pageSize;

+ (BOOL)validateHTTPResponse:(id)obj fromCache:(BOOL)fromCache;
- (BOOL)validateHTTPResponse:(id)obj fromCache:(BOOL)fromCache;

@end
