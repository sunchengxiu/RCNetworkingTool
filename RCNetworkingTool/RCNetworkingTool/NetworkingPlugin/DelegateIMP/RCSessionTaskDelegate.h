//
//  RCSessionTaskDelegate.h
//  RCNetworkingTool
//
//  Created by 孙承秀 on 2019/1/11.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCURLSessionManager.h"
NS_ASSUME_NONNULL_BEGIN
typedef void (^RCURLSessionTaskCompletionHandler)(NSURLResponse *response, id responseObject, NSError *error);
@interface RCSessionTaskDelegate : NSObject<NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
- (instancetype)initWithTask:(NSURLSessionTask *)task;
@property (nonatomic, weak) RCURLSessionManager *manager;
@property (nonatomic, strong , nullable) NSMutableData *mutableData;
@property (nonatomic, copy) RCURLSessionTaskCompletionHandler completionHandler;
@end

NS_ASSUME_NONNULL_END
