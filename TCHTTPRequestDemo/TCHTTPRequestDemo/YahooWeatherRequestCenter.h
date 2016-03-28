//
//  YahooWeatherRequestCenter.h
//  TCHTTPRequestDemo
//
//  Created by cdk on 15/4/9.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import "TCHTTPRequestCenter.h"

@interface YahooWeatherRequestCenter : TCHTTPRequestCenter

- (id<TCHTTPRequest>)fetchWeatherForWOEID:(NSString *)woeiID beforeRun:(void(^)(id<TCHTTPRequest> request))beforeRun;

@end
