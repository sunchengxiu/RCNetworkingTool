//
//  RCNetingworkingDefine.m
//  RCNetworkingTool
//
//  Created by 孙承秀 on 2019/1/11.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCNetingworkingDefine.h"
NSString * const RCNetworkingTaskDidCompleteResponseSerializerKey = @"com.rongcloud.networking.task.complete.responseserializer";
NSString * const RCNetworkingTaskDidCompleteResponseDataKey = @"com.rongcloud.networking.complete.finish.responsedata";
NSString * const RCNetworkingTaskDidCompleteErrorKey = @"com.rongcloud.networking.task.complete.error";
NSString * const RCNetworkingTaskDidCompleteSerializedResponseKey = @"com.rongcloud.networking.task.complete.serializedresponse";
NSString * const RCNetworkingTaskDidCompleteNotification = @"com.rongcloud.networking.task.complete";
NSString * const RCNetworkingOperationFailingURLResponseErrorKey = @"com.rongcloud.serialization.response.error.response";
NSString * const RCNetworkingOperationFailingURLResponseDataErrorKey = @"com.rongcloud.serialization.response.error.data";
NSString * const RCURLResponseSerializationErrorDomain = @"com.rongcloud.error.serialization.response";
NSString * const RCURLSessionManagerLockName = @"com.rongcloud.networking.session.manager.lock";
NSString * const RCNSURLSessionTaskDidResumeNotification  = @"com.rongcloud.networking.nsurlsessiontask.resume";
NSString * const RCNSURLSessionTaskDidSuspendNotification = @"com.rongcloud.networking.nsurlsessiontask.suspend";
NSString * const RCNetworkingTaskDidResumeNotification = @"com.rongcloud.networking.task.resume";
NSString * const RCNetworkingTaskDidSuspendNotification = @"com.rongcloud.networking.task.suspend";
NSString * const RCURLSessionDidInvalidateNotification = @"com.rongcloud.networking.session.invalidate";
