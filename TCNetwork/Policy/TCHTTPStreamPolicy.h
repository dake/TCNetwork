//
//  TCHTTPStreamPolicy.h
//  TCKit
//
//  Created by dake on 16/3/28.
//  Copyright © 2016年 dake. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TCHTTPRequestProtocol.h"


@protocol AFMultipartFormData;
typedef void (^AFConstructingBlock)(id<AFMultipartFormData> formData);

@interface TCHTTPStreamPolicy : NSObject

@property (nonatomic, weak) id<TCHTTPRequest> request;
@property (nonatomic, strong) NSProgress *progress;


#pragma mark - Upload

@property (nonatomic, copy) AFConstructingBlock constructingBodyBlock;


#pragma mark - Download

@property (nonatomic, assign) BOOL shouldResumeDownload; // default: NO
@property (nonatomic, copy) NSString *downloadIdentifier; // such as hash string, but can not be file system path! if nil, apiUrl's md5 used.
@property (nonatomic, copy) NSString *downloadResumeCacheDirectory; // if nil, `tmp` directory used.
@property (nonatomic, copy) NSString *downloadDestinationPath;

@end
