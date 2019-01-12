//
//  RCResponseSerializer.m
//  RCNetworkingTool
//
//  Created by 孙承秀 on 2019/1/11.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCResponseSerializer.h"

NSError * RCErrorWithUnderlyingError(NSError *error, NSError *underlyingError) {
    if (!error) {
        return underlyingError;
    }
    
    if (!underlyingError || error.userInfo[NSUnderlyingErrorKey]) {
        return error;
    }
    
    NSMutableDictionary *mutableUserInfo = [error.userInfo mutableCopy];
    mutableUserInfo[NSUnderlyingErrorKey] = underlyingError;
    
    return [[NSError alloc] initWithDomain:error.domain code:error.code userInfo:mutableUserInfo];
}

@implementation RCResponseSerializer

+ (instancetype)responseSerializer {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    // code : 200-299
    self.acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    self.acceptableContentTypes = nil;
    return self;
}
-(BOOL)validateResponse:(NSHTTPURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error{
    BOOL responseIsValid = YES;
    NSError *validError = nil;
    if (response && [response isKindOfClass:[NSHTTPURLResponse class]]) {
        // saccept content type
        if (self.acceptableContentTypes && ![self.acceptableContentTypes containsObject:response.MIMEType] && response.MIMEType != nil && data != nil && data.length > 0) {
            if (data.length > 0 && [response URL]) {
                NSMutableDictionary *mdic = [@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"unacceptable content-type: %@",[response MIMEType]],NSURLErrorFailingURLErrorKey:[response URL] , RCNetworkingOperationFailingURLResponseErrorKey : response} mutableCopy];
                if (data) {
                    mdic[RCNetworkingOperationFailingURLResponseDataErrorKey] = data;
                }
                validError = RCErrorWithUnderlyingError([NSError errorWithDomain:RCURLResponseSerializationErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:mdic], validError);
            }
            responseIsValid = NO;
        }
        // accept status code
        if (self.acceptableStatusCodes && ![self.acceptableStatusCodes containsIndex:(NSUInteger)response.statusCode] && [response URL]) {
            NSMutableDictionary *mdic = [@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"request code faild:%@(%ld)",[NSHTTPURLResponse localizedStringForStatusCode:response.statusCode],response.statusCode],NSURLErrorFailingURLErrorKey : [response URL] , RCNetworkingOperationFailingURLResponseErrorKey : response} mutableCopy];
            if (data) {
                mdic[RCNetworkingOperationFailingURLResponseDataErrorKey] = data;
            }
            validError = RCErrorWithUnderlyingError([NSError errorWithDomain:RCURLResponseSerializationErrorDomain code:NSURLErrorBadServerResponse userInfo:mdic], validError);
            responseIsValid = NO;
        }
    }
    if (error && !responseIsValid) {
        *error = validError;
    }
    return responseIsValid;
}
-(id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error{
    [self validateResponse:(NSHTTPURLResponse *)response data:data error:error];
    return data;
}
- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [self init];
    if (!self) {
        return nil;
    }
    
    self.acceptableStatusCodes = [decoder decodeObjectOfClass:[NSIndexSet class] forKey:NSStringFromSelector(@selector(acceptableStatusCodes))];
    self.acceptableContentTypes = [decoder decodeObjectOfClass:[NSIndexSet class] forKey:NSStringFromSelector(@selector(acceptableContentTypes))];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.acceptableStatusCodes forKey:NSStringFromSelector(@selector(acceptableStatusCodes))];
    [coder encodeObject:self.acceptableContentTypes forKey:NSStringFromSelector(@selector(acceptableContentTypes))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    RCResponseSerializer *serializer = [[[self class] allocWithZone:zone] init];
    serializer.acceptableStatusCodes = [self.acceptableStatusCodes copyWithZone:zone];
    serializer.acceptableContentTypes = [self.acceptableContentTypes copyWithZone:zone];
    
    return serializer;
}
+(BOOL)supportsSecureCoding{
    return YES;
}
@end
