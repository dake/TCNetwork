//
//  TCHTTPRequest+Private.m
//  SudiyiClient
//
//  Created by cdk on 15/11/13.
//  Copyright © 2015年 Sudiyi. All rights reserved.
//

#import "TCHTTPRequest+Private.h"
#import "NSURLSessionTask+TCResumeDownload.h"


static NSString *const kNSURLSessionResumeInfoTempFileName = @"NSURLSessionResumeInfoTempFileName";
static NSString *const kNSURLSessionResumeInfoLocalPath = @"NSURLSessionResumeInfoLocalPath";

@implementation TCHTTPRequest (Private)

@dynamic requestTask;
@dynamic uploadProgress;
@dynamic downloadProgress;

- (void)loadResumeData:(void(^)(NSData *data))finish
{
    if (nil == finish) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        @autoreleasepool {
            NSData *data = [NSURLSessionDownloadTask tc_resumeDataWithIdentifier:self.downloadIdentifier inDirectory:self.downloadResumeCacheDirectory];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                finish(data);
            });
        }
    });
}

- (void)clearCachedResumeData
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        @autoreleasepool {
            [self.requestTask tc_purgeResumeData];
        }
    });
}

@end
