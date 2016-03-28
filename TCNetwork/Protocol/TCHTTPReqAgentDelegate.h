//
//  TCHTTPReqAgentDelegate.h
//  TCKit
//
//  Created by dake on 16/3/18.
//  Copyright © 2016年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCHTTPRequestAgent.h"

@protocol TCHTTPReqAgentDelegate <NSObject>

@required

@property (nonatomic, strong) NSURLSessionTask *requestTask;
@property (nonatomic, weak) id<TCHTTPRequestAgent> requestAgent;
@property (nonatomic, strong) id rawResponseObject;

- (void)requestResponded:(BOOL)isValid clean:(BOOL)clean;

@end
