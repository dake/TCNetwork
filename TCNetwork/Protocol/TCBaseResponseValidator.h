//
//  TCBaseResponseValidator.h
//  TCKit
//
//  Created by dake on 13-3-27.
//  Copyright (c) 2013年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCHTTPResponseValidator.h"

@interface TCBaseResponseValidator : NSObject <TCHTTPResponseValidator>

@property (nonatomic, strong) id data;
@property (nonatomic, assign) BOOL success;
@property (nonatomic, strong) NSError *error;

- (BOOL)validateHTTPResponse:(id)obj fromCache:(BOOL)fromCache;

@end

