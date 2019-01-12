//
//  RCQueryModel.h
//  RCNetworkingTool
//
//  Created by 孙承秀 on 2019/1/10.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCQueryModel : NSObject

/**
 field
 */
@property(nonatomic , strong)id field;

/**
 value
 */
@property(nonatomic , strong)id value;

/**
 初始化 query model

 @param field key
 @param value value
 @return query 模型
 */
- (instancetype)initWithField:(id)field value:(id)value;

/**
 编码 query 字符串,根据初始化的键值对编码

 @return 编码后的字符串
 */
- (NSString *)encodeQuery;
@end

NS_ASSUME_NONNULL_END
