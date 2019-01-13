//
//  ViewController.m
//  RCNetworkingTool
//
//  Created by 孙承秀 on 2019/1/10.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "ViewController.h"
#import "RCQueryModel.h"
#import "RCHTTPSessionManager.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //1.创建AFHTTPSessionManager管理者
    //AFHTTPSessionManager内部是基于NSURLSession实现的
    RCHTTPSessionManager *manager = [RCHTTPSessionManager sessionManager];
    
    //2.发送请求
    NSDictionary *param = @{
                            @"username":@"520it",
                            @"pwd":@"520it"
                            };
    
   
    [manager requestWithMethod:RCNetworkingMethodTypeGET URLString:@"http://guanyu.rce-dev.rongcloud.net/api/appversion?platform=iOS&version_code=2018041914" parameters:nil success:^(NSURLSessionDataTask * _Nonnull dataTask, id  _Nullable responseObject) {
        NSLog(@"%@",responseObject);
    } failure:^(NSURLSessionDataTask * _Nullable dataTask, NSError * _Nonnull error) {
        NSLog(@"%@",error);
    }];
}


@end
