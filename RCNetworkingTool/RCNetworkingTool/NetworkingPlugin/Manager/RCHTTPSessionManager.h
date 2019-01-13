//
//  RCHTTPSessionManager.h
//  RCNetworkingTool
//
//  Created by 孙承秀 on 2019/1/11.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCURLSessionManager.h"
#import "RCNetingworkingDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCHTTPSessionManager : RCURLSessionManager
/**
 base url
 */
@property (readonly, nonatomic, strong, nullable) NSURL *baseURL;

/**
 实例化方法

 @return sessionManager 对象
 */
+ (instancetype)sessionManager;
/**
 初始化 baseUrl

 @param url baseUrl
 @return sessionManager 对象
 */
- (instancetype)initWithBaseURL:(nullable NSURL *)url;

/**
 默认初始化方法，代替 init

 @param url baseUrl
 @param configuration configuration
 @return 实例化对象
 */
- (instancetype)initWithBaseURL:(nullable NSURL *)url
           sessionConfiguration:(nullable NSURLSessionConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

- (NSURLSessionDataTask *)requestWithMethod:(RCNetworkingMethodType )methodType URLString:(NSString *)urlString parameters:(nullable id)parameters success:(nullable void (^) (NSURLSessionDataTask *dataTask , _Nullable id responseObject))success failure:(nullable void (^) (NSURLSessionDataTask * _Nullable  dataTask, NSError * error))failure;
@end

NS_ASSUME_NONNULL_END
