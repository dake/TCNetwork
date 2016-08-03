//
//  TCBaseResponseValidator.h
//  TCKit
//
//  Created by dake on 13-3-27.
//  Copyright (c) 2013年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCHTTPRespValidator.h"

@interface TCBaseResponseValidator : NSObject <TCHTTPRespValidator>

@property (nonatomic, strong) id data;
@property (nonatomic, assign) BOOL success;
@property (nonatomic, copy) NSString *successMsg;
@property (nonatomic, strong) NSError *error;

@property (nonatomic, strong) NSDictionary<NSString *, NSArray<NSNumber *> *> *errorFilter;

- (BOOL)validateHTTPResponse:(id)obj fromCache:(BOOL)fromCache;

@end

