//
//  RCResponseSerializer.h
//  RCNetworkingTool
//
//  Created by 孙承秀 on 2019/1/11.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCResponseSerializerProtocol.h"
#import "RCNetingworkingDefine.h"
NS_ASSUME_NONNULL_BEGIN

@interface RCResponseSerializer : NSObject<RCResponseSerializerProtocol , NSCopying , NSSecureCoding>
/**
 初始化
 */
+ (instancetype)responseSerializer;
/**
 允许的状态码域
 */
@property (nonatomic, copy, nullable) NSIndexSet *acceptableStatusCodes;

/**
 允许的 ContentTypes
 */
@property (nonatomic, copy, nullable) NSSet <NSString *> *acceptableContentTypes;

/**
 检测 response 合法性

 @param response response
 @param data data
 @param error error
 @return 是否合法
 */
- (BOOL)validateResponse:(nullable NSHTTPURLResponse *)response
                    data:(nullable NSData *)data
                   error:(NSError * _Nullable __autoreleasing *)error;
NSError * RCErrorWithUnderlyingError(NSError *error, NSError *underlyingError);
@end

NS_ASSUME_NONNULL_END
