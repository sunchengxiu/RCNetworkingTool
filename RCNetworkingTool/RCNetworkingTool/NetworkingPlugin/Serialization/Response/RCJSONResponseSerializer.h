//
//  RCJSONResponseSerializer.h
//  RCNetworkingTool
//
//  Created by 孙承秀 on 2019/1/11.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCResponseSerializer.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCJSONResponseSerializer : RCResponseSerializer
- (instancetype)init;

/**
 序列化器格式
 */
@property (nonatomic, assign) NSJSONReadingOptions readingOptions;

/**
 是否移除 `NSNull` 的 value
 */
@property (nonatomic, assign) BOOL removesKeysWithNullValues;

/**
 根据序列化器序列化
 */
+ (instancetype)serializerWithReadingOptions:(NSJSONReadingOptions)readingOptions;
@end

NS_ASSUME_NONNULL_END
