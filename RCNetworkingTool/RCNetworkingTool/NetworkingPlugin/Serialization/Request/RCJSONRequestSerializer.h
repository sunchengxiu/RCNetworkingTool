//
//  RCJSONRequestSerializer.h
//  RCNetworkingTool
//
//  Created by 孙承秀 on 2019/1/11.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCRequestSerializer.h"
NS_ASSUME_NONNULL_BEGIN

@interface RCJSONRequestSerializer : RCRequestSerializer
/**
 json 序列化器选项
 */
@property (nonatomic, assign) NSJSONWritingOptions writingOptions;

/**
 创建并返回一个 json 序列化器
 
 @param writingOptions The specified JSON writing options.
 */
+ (instancetype)serializerWithWritingOptions:(NSJSONWritingOptions)writingOptions;
@end

NS_ASSUME_NONNULL_END
