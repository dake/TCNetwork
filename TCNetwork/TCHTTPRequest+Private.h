//
//  TCHTTPRequest+Private.h
//  SudiyiClient
//
//  Created by cdk on 15/11/13.
//  Copyright © 2015年 Sudiyi. All rights reserved.
//

#import "TCHTTPRequest.h"

@interface TCHTTPRequest (Private)

@property (nonatomic, strong, readwrite) NSURLSessionTask *requestTask;
@property (nonatomic, strong, readwrite) NSProgress *uploadProgress;
@property (nonatomic, strong, readwrite) NSProgress *downloadProgress;

- (void)loadResumeData:(void(^)(NSData *data))finish;
//- (void)saveResumeData:(NSData *)data finish:(void(^)(BOOL success))finish;
- (void)clearCachedResumeData;

@end
