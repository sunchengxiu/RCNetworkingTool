//
//  RCResponseSerializerProtocol.h
//  RCNetworkingTool
//
//  Created by 孙承秀 on 2019/1/11.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 工厂模式，以后有除了 json 解析之外，如 xml 解析，继承这个即可
@protocol RCResponseSerializerProtocol <NSObject>

- (nullable id)responseObjectForResponse:(nullable NSURLResponse *)response
                                    data:(nullable NSData *)data
                                   error:(NSError * _Nullable __autoreleasing *)error ;
@end

NS_ASSUME_NONNULL_END
