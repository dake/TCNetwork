//
//  ViewController.m
//  TCHTTPRequestDemo
//
//  Created by cdk on 15/4/9.
//  Copyright (c) 2015年 dake. All rights reserved.
//

#import "ViewController.h"

#import "YahooWeatherRequestCenter.h"
#import "DoubanRequestCenter.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)dealloc
{
    //
    // for Douban api
    //
    
    // cancel all request with observer self in Douban
    [[DoubanRequestCenter defaultCenter] removeRequestObserver:self];
    
    // or cancel request one by one
    
    //[[DoubanRequestCenter defaultCenter] removeRequestObserver:self forIdentifier:NSStringFromSelector(@selector(fetchBookInfoForID:beforeRun:))];
    //[[DoubanRequestCenter defaultCenter] removeRequestObserver:self forIdentifier:NSStringFromSelector(@selector(searchBookListForKeyword:beforeRun:))];
    
    
    //
    // for Yahoo weather api
    //
    [[YahooWeatherRequestCenter defaultCenter] removeRequestObserver:self];
}

- (IBAction)clearRequestCacheTapped:(UIButton *)sender
{
    [[DoubanRequestCenter defaultCenter] removeAllCachedResponses];
    [[YahooWeatherRequestCenter defaultCenter] removeAllCachedResponses];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
   
#pragma mark - Douban
    
    //
    // test Douban api
    //
    
    // fetch book info with caching response
    [[DoubanRequestCenter defaultCenter] fetchBookInfoForID:@"17604305" beforeRun:^(id<TCHTTPRequest> request) {
        request.observer = self;
        request.identifier = NSStringFromSelector(@selector(fetchBookInfoForID:beforeRun:));
        
        // You can set delegate here
        //request.delegate = self;
        // or use resultBlock
        request.resultBlock = ^(id<TCHTTPRequest> request, BOOL successe) {
            NSLog(@"%@", request.responseObject);
        };
    }];
    
    // search book list without caching response
    [[DoubanRequestCenter defaultCenter] searchBookListForKeyword:@"python" beforeRun:^(id<TCHTTPRequest> request) {
        request.observer = self;
        request.identifier = NSStringFromSelector(@selector(searchBookListForKeyword:beforeRun:));
        
        // You can set delegate here
        //request.delegate = self;
        // or use resultBlock
        request.resultBlock = ^(id<TCHTTPRequest> request, BOOL successe) {
            NSLog(@"%@", request.responseObject);
        };
    }];
    
    
#pragma mark - Yahoo
    
    //
    // test Yahoo weather api
    //
    
    static NSString *const kBeijingW = @"2151330";
    [[YahooWeatherRequestCenter defaultCenter] fetchWeatherForWOEID:kBeijingW beforeRun:^(id<TCHTTPRequest> request) {
        request.observer = self;
        request.identifier = NSStringFromSelector(@selector(fetchWeatherForWOEID:beforeRun:));
        
        // You can set delegate here
        //request.delegate = self;
        // or use resultBlock
        request.resultBlock = ^(id<TCHTTPRequest> request, BOOL successe) {
            NSLog(@"%@", request.responseObject);
        };
    }];
   
    
#pragma mark - Batch
    
    YahooWeatherRequestCenter *center = [YahooWeatherRequestCenter defaultCenter];
    TCHTTPCachePolicy *policy = [[TCHTTPCachePolicy alloc] init];
    policy.cacheTimeoutInterval = 5 * 60;
    id<TCHTTPRequest> request1 = [center requestWithMethod:kTCHTTPMethodGet cachePolicy:policy apiUrl:@"forecastrss" host:nil];
    request1.parameters = @{@"w": kBeijingW, @"u": @"c"};
    
    id<TCHTTPRequest> request2 = [center requestWithMethod:kTCHTTPMethodGet apiUrl:@"ig/api" host:@"http://www.google.com/"];
    request2.parameters = @{@"weather": @"Beijing"};
    

    id<TCHTTPRequest> batchRequest = [center batchRequestWithRequests:@[request1, request2]];
    batchRequest.observer = self;
    batchRequest.identifier = NSStringFromSelector(@selector(batchRequestWithRequests:));
    
    // You can set delegate here
    //request.delegate = self;
    // or use resultBlock
    [batchRequest startWithResult:^(id<TCHTTPRequest> request, BOOL successe) {
        for (id<TCHTTPRequest> req in request.batchRequests) {
            NSLog(@"%@", req.responseObject);
        }
    } error:NULL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
