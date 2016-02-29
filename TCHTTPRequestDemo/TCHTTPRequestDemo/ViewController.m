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
    [[DoubanRequestCenter defaultCenter] removeAllCachedResponse];
    [[YahooWeatherRequestCenter defaultCenter] removeAllCachedResponse];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
   
#pragma mark - Douban
    
    //
    // test Douban api
    //
    
    // fetch book info with caching response
    [[DoubanRequestCenter defaultCenter] fetchBookInfoForID:@"17604305" beforeRun:^(TCHTTPRequest *request) {
        request.observer = self;
        request.requestIdentifier = NSStringFromSelector(@selector(fetchBookInfoForID:beforeRun:));
        
        // You can set delegate here
        //request.delegate = self;
        // or use resultBlock
        request.resultBlock = ^(TCHTTPRequest *request, BOOL successe) {
            NSLog(@"%@", request.responseObject);
        };
    }];
    
    // search book list without caching response
    [[DoubanRequestCenter defaultCenter] searchBookListForKeyword:@"python" beforeRun:^(TCHTTPRequest *request) {
        request.observer = self;
        request.requestIdentifier = NSStringFromSelector(@selector(searchBookListForKeyword:beforeRun:));
        
        // You can set delegate here
        //request.delegate = self;
        // or use resultBlock
        request.resultBlock = ^(TCHTTPRequest *request, BOOL successe) {
            NSLog(@"%@", request.responseObject);
        };
    }];
    
    
#pragma mark - Yahoo
    
    //
    // test Yahoo weather api
    //
    
    static NSString *const kBeijingW = @"2151330";
    [[YahooWeatherRequestCenter defaultCenter] fetchWeatherForWOEID:kBeijingW beforeRun:^(TCHTTPRequest *request) {
        request.observer = self;
        request.requestIdentifier = NSStringFromSelector(@selector(fetchWeatherForWOEID:beforeRun:));
        
        // You can set delegate here
        //request.delegate = self;
        // or use resultBlock
        request.resultBlock = ^(TCHTTPRequest *request, BOOL successe) {
            NSLog(@"%@", request.responseObject);
        };
    }];
   
    
#pragma mark - Batch
    
    YahooWeatherRequestCenter *center = [YahooWeatherRequestCenter defaultCenter];
    TCHTTPCachePolicy *policy = [[TCHTTPCachePolicy alloc] init];
    policy.cacheTimeoutInterval = 5 * 60;
    TCHTTPRequest *request1 = [center requestWithMethod:kTCHTTPRequestMethodGet cachePolicy:policy apiUrl:@"forecastrss" host:nil];
    request1.parameters = @{@"w": kBeijingW, @"u": @"c"};
    
    TCHTTPRequest *request2 = [center requestWithMethod:kTCHTTPRequestMethodGet apiUrl:@"ig/api" host:@"http://www.google.com/"];
    request2.parameters = @{@"weather": @"Beijing"};
    

    TCHTTPRequest *batchRequest = [center batchRequestWithRequests:@[request1, request2]];
    batchRequest.observer = self;
    batchRequest.requestIdentifier = NSStringFromSelector(@selector(batchRequestWithRequests:));
    
    // You can set delegate here
    //request.delegate = self;
    // or use resultBlock
    [batchRequest startWithResult:^(TCHTTPRequest *request, BOOL successe) {
        for (TCHTTPRequest *req in request.requestArray) {
            NSLog(@"%@", req.responseObject);
        }
    } error:NULL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
