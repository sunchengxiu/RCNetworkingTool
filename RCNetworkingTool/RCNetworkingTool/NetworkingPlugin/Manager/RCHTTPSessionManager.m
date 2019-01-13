//
//  RCHTTPSessionManager.m
//  RCNetworkingTool
//
//  Created by 孙承秀 on 2019/1/11.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCHTTPSessionManager.h"
#import "RCRequestSerializer.h"
#import "RCJSONResponseSerializer.h"
@interface RCHTTPSessionManager()
@property (readwrite, nonatomic, strong) NSURL *baseURL;

/**
 指定请求的序列化格式，目前只有 json
 */
@property (nonatomic, strong)RCRequestSerializer  <RCRequestSerializerProtocol>  *requestSerializer;

/**
 请求的 response 序列化格式，目前只有 json
 */
@property (nonatomic, strong) RCResponseSerializer <RCResponseSerializerProtocol>  *responseSerializer;

@end
@implementation RCHTTPSessionManager
+ (instancetype)sessionManager {
    return [[[self class] alloc] initWithBaseURL:nil];
}

- (instancetype)init {
    return [self initWithBaseURL:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    return [self initWithBaseURL:url sessionConfiguration:nil];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration {
    return [self initWithBaseURL:nil sessionConfiguration:configuration];
}
-(instancetype)initWithBaseURL:(NSURL *)url sessionConfiguration:(NSURLSessionConfiguration *)configuration{
    self = [super initWithSessionConfiguration:configuration];
    if (!self) {
        return nil;
    }
    self.requestSerializer = [RCRequestSerializer requestSerializer];
    self.responseSerializer = [RCJSONResponseSerializer responseSerializer];
    return self;
}
- (NSString *)switchMethodType:(RCNetworkingMethodType)methodType{
    NSString *method = @"GET";
    switch (methodType) {
        case RCNetworkingMethodTypeGET:
            method = @"GET";
            break;
        case RCNetworkingMethodTypePOST:
            method = @"POST";
            break;
        case RCNetworkingMethodTypePUT:
            method = @"PUT";
            break;
        case RCNetworkingMethodTypeDELETE:
            method = @"DELETE";
            break;
        case RCNetworkingMethodTypeHEAD:
            method = @"HEAD";
            break;
        default:
            break;
    }
    return method;
}
-(NSURLSessionDataTask *)requestWithMethod:(RCNetworkingMethodType )methodType URLString:(NSString *)urlString parameters:(id)parameters success:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))success failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure{
    NSString *method = [self switchMethodType:methodType];
    NSError *requestSer = nil;
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method urlString:urlString parameters:parameters error:&requestSer];
    if (requestSer) {
        if (failure) {
            dispatch_async(self.completionQueue?:dispatch_get_main_queue(), ^{
                failure(nil , requestSer);
            });
        }
        return nil;
    }
    __block NSURLSessionDataTask *dataTask = nil;
    dataTask = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
            if (failure) {
                failure(dataTask,error);
            }
        } else {
            if (success) {
                success(dataTask , responseObject);
            }
        }
    }];
    [dataTask resume];
    return dataTask;
}
@dynamic responseSerializer;
-(void)setRequestSerializer:(RCRequestSerializer<RCRequestSerializerProtocol> *)requestSerializer{
    NSParameterAssert(requestSerializer);
    _requestSerializer = requestSerializer;
}
-(void)setResponseSerializer:(RCResponseSerializer<RCResponseSerializerProtocol> *)responseSerializer{
    NSParameterAssert(responseSerializer);
    [super setResponseSerializer:responseSerializer];
}
@end
