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
@property (nonatomic, strong) NSError *error;

- (void)reset;

@optional
+ (BOOL)validateHTTPResponse:(id)obj fromCache:(BOOL)fromCache;
- (BOOL)validateHTTPResponse:(id)obj fromCache:(BOOL)fromCache;

@end
