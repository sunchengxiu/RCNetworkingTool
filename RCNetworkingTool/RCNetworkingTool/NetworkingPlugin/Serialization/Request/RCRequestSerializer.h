//
//  RCRequestSerializer.h
//  RCNetworkingTool
//
//  Created by 孙承秀 on 2019/1/10.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCRequestSerializerProtocol.h"
NS_ASSUME_NONNULL_BEGIN
FOUNDATION_EXPORT NSString * const RCURLRequestSerializationErrorDomain;
@interface RCRequestSerializer : NSObject<RCRequestSerializerProtocol , NSCopying , NSSecureCoding>

/**
 字符串编码，用于序列化参数，默认为 `NSUTF8StringEncoding`
 */
@property(nonatomic , assign)NSStringEncoding stringEncoding;

/**
 超时时间
 */
@property(nonatomic , assign)NSTimeInterval timeoutInterval;
/**
 网络状态变化
 */
@property (nonatomic, assign) NSURLRequestNetworkServiceType networkServiceType;

/**
 http headers
 */
@property(nonatomic , strong , readonly)NSDictionary <NSString * , NSString *>*httpRequestHeaders;

/**
 初始化方法

 @return 初始化的 request 的序列化器
 */
+ (instancetype)requestSerializer;

/**
 设置请求头的值，如果 value 为 nil ， 则会删除已经存在的 field 对应的 value 的值。

 @param value 需要设置的值
 @param field 设置的 key
 */
- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(NSString *)field;

/**
 获取 http header 中 field 对应的值

 @param field field
 @return 对应的值
 */
- (nullable NSString *)valueForHTTPHeaderField:(NSString *)field;

/**
 自定义 query 字符串

 @param block 根据参数自定义 query 字符串
 */
- (void)customQueryStringWithBlock:(nullable NSString *(^)(NSURLRequest *request , id parameters , NSError*__autoreleasing * error))block;
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method urlString:(NSString *)urlString parameters:(nullable id)parameters error:( NSError *__autoreleasing *)error;
@end

NS_ASSUME_NONNULL_END
