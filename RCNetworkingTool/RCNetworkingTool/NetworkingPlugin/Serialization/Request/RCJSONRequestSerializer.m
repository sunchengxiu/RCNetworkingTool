//
//  RCJSONRequestSerializer.m
//  RCNetworkingTool
//
//  Created by 孙承秀 on 2019/1/11.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCJSONRequestSerializer.h"
@interface RCJSONRequestSerializer()

/**
 需要 query 的方法名称，将 parameters 作为 query，默认为 `get` , `DELETE`,`HEAD`
 */
@property(nonatomic , strong)NSSet <NSString *>*needQueryParametersSet;
@end
@implementation RCJSONRequestSerializer
#pragma mark - init
+(instancetype)requestSerializer{
    return [self serializerWithWritingOptions:(NSJSONWritingOptions)0];
}
+(instancetype)serializerWithWritingOptions:(NSJSONWritingOptions)writingOptions{
    RCJSONRequestSerializer *jsonSer = [[self alloc] init];
    jsonSer.writingOptions = writingOptions;
    return jsonSer;
}
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super initWithCoder:aDecoder]) {
        self.writingOptions = [[aDecoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(writingOptions))] unsignedIntValue];
    }
    return self;
}
-(void)encodeWithCoder:(NSCoder *)aCoder{
    [super encodeWithCoder:aCoder];
    [aCoder encodeInteger:self.writingOptions forKey:NSStringFromSelector(@selector(writingOptions))];
}
-(id)copyWithZone:(NSZone *)zone{
    RCJSONRequestSerializer *jsonSer = [super copyWithZone:zone];
    jsonSer.writingOptions = self.writingOptions;
    return jsonSer;
}
#pragma mark - request
-(NSURLRequest *)serializingRequest:(NSURLRequest *)request withParameters:(id)parameters error:(NSError * _Nullable __autoreleasing *)error{
    if ([self.needQueryParametersSet containsObject:[[request HTTPMethod] uppercaseString]]) {
        return [super serializingRequest:request withParameters:parameters error:error];
    }
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    [self.httpRequestHeaders enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if (![request valueForHTTPHeaderField:key]) {
            [mutableRequest setValue:obj forHTTPHeaderField:key];
        }
    }];
    if (parameters) {
        // json
        if (![mutableRequest valueForHTTPHeaderField:@"Content-Type"]) {
            [mutableRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        }
        if (![NSJSONSerialization isValidJSONObject:parameters]) {
            if (error) {
                NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey: NSLocalizedStringFromTable(@"The `parameters` argument is not valid JSON.", @"AFNetworking", nil)};
                *error = [[NSError alloc] initWithDomain:RCURLRequestSerializationErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:userInfo];
            }
            return nil;
        }
        
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:parameters options:self.writingOptions error:error];
        if (!jsonData) {
            return nil;
        }
        [mutableRequest setHTTPBody:jsonData];
    }
    return mutableRequest;
}
@end
