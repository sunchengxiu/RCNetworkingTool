//
//  RCRequestSerializerProtocol.h
//  RCNetworkingTool
//
//  Created by 孙承秀 on 2019/1/10.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RCRequestSerializerProtocol <NSObject>

/**
 通过序列化器来序列化本次请求

 @param request 原始请求
 @param parameters 序列化参数
 @param error 错误
 @return 序列化后的请求
 */
- (nullable NSURLRequest *)serializingRequest:(NSURLRequest *)request
                                        withParameters:(nullable id)parameters
                                                 error:( NSError*__autoreleasing *)error;
@end

NS_ASSUME_NONNULL_END
