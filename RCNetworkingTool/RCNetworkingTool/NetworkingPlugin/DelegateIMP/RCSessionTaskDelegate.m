//
//  RCSessionTaskDelegate.m
//  RCNetworkingTool
//
//  Created by 孙承秀 on 2019/1/11.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCSessionTaskDelegate.h"
#import "RCNetingworkingDefine.h"
static dispatch_group_t RC_completion_group() {
    static dispatch_group_t rc_completion_group;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        rc_completion_group = dispatch_group_create();
    });
    
    return rc_completion_group;
}

static dispatch_queue_t RC_processing_queue() {
    static dispatch_queue_t rc_processing_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        rc_processing_queue = dispatch_queue_create("com.rongcloud.networking.session.manager.processing", DISPATCH_QUEUE_CONCURRENT);
    });
    
    return rc_processing_queue;
}
@interface RCSessionTaskDelegate()

/**
 task
 */
@property(nonatomic , strong)NSURLSessionTask *task;
@end
@implementation RCSessionTaskDelegate
-(instancetype)initWithTask:(NSURLSessionTask *)task{
    if (self = [super init]) {
        _task = task;
    }
    _mutableData = [NSMutableData data];
    return self;
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error{
    __strong RCURLSessionManager *manager = self.manager;
    __block id responseObject = nil;
    __block NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[RCNetworkingTaskDidCompleteResponseSerializerKey] = manager.responseSerializer;
    NSData *data = nil;
    if (self.mutableData) {
        data = self.mutableData.copy;
        self.mutableData = nil;
    }
    if (data) {
        userInfo[RCNetworkingTaskDidCompleteResponseDataKey] = data;
    }
    if (error) {
        userInfo[RCNetworkingTaskDidCompleteErrorKey] = error;
        dispatch_group_async(manager.completionGroup?:RC_completion_group(), manager.completionQueue?:dispatch_get_main_queue(), ^{
            // 回调
            if (self.completionHandler) {
                self.completionHandler(task.response, responseObject, error);
            }
            // 通知
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:RCNetworkingTaskDidCompleteNotification object:userInfo];
            });
        });
    } else {
        dispatch_async(RC_processing_queue(), ^{
            NSError *serError = nil;
            responseObject = [manager.responseSerializer responseObjectForResponse:task.response data:data error:&serError];
            if (responseObject) {
                userInfo[RCNetworkingTaskDidCompleteSerializedResponseKey] = responseObject;
            }
            if (serError) {
                userInfo[RCNetworkingTaskDidCompleteErrorKey] = serError;
            }
            dispatch_group_async(manager.completionGroup?:RC_completion_group(), dispatch_get_main_queue(), ^{
                if (self.completionHandler) {
                    self.completionHandler(task.response, responseObject, serError);
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                   [[NSNotificationCenter defaultCenter] postNotificationName:RCNetworkingTaskDidCompleteNotification object:task userInfo:userInfo];
                });
            });
        });
    }
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
    
    
}
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    [self.mutableData appendData:data];
}
@end
