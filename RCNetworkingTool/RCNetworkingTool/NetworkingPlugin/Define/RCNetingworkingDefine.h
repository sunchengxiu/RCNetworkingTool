//
//  RCNetingworkingDefine.h
//  RCNetworkingTool
//
//  Created by 孙承秀 on 2019/1/11.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSUInteger , RCNetworkingMethodType) {
    RCNetworkingMethodTypeGET = 1 ,
    RCNetworkingMethodTypePOST = 2 ,
    RCNetworkingMethodTypePUT = 3 ,
    RCNetworkingMethodTypeDELETE = 4 ,
    RCNetworkingMethodTypeHEAD = 5,
    
};
FOUNDATION_EXTERN NSString * const RCNetworkingTaskDidCompleteResponseSerializerKey;
FOUNDATION_EXTERN NSString * const RCNetworkingTaskDidCompleteResponseDataKey;
FOUNDATION_EXTERN NSString * const RCNetworkingTaskDidCompleteErrorKey;
FOUNDATION_EXTERN NSString * const RCNetworkingTaskDidCompleteSerializedResponseKey;
FOUNDATION_EXTERN NSString * const RCNetworkingTaskDidCompleteNotification;
FOUNDATION_EXPORT NSString * const RCNetworkingOperationFailingURLResponseErrorKey;
FOUNDATION_EXPORT NSString * const RCNetworkingOperationFailingURLResponseDataErrorKey;
FOUNDATION_EXPORT NSString * const RCURLResponseSerializationErrorDomain;
FOUNDATION_EXPORT NSString * const RCURLSessionManagerLockName;
FOUNDATION_EXPORT NSString * const RCNSURLSessionTaskDidResumeNotification;
FOUNDATION_EXPORT NSString * const RCNSURLSessionTaskDidSuspendNotification;
FOUNDATION_EXPORT NSString * const RCNetworkingTaskDidResumeNotification;
FOUNDATION_EXPORT NSString * const RCNetworkingTaskDidSuspendNotification;
FOUNDATION_EXPORT NSString * const RCURLSessionDidInvalidateNotification;
