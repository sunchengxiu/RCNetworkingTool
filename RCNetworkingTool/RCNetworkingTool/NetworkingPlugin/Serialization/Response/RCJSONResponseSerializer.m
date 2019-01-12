//
//  RCJSONResponseSerializer.m
//  RCNetworkingTool
//
//  Created by 孙承秀 on 2019/1/11.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCJSONResponseSerializer.h"

static BOOL RCErrorOrUnderlyingErrorHasCodeInDomain(NSError *error, NSInteger code, NSString *domain) {
    if ([error.domain isEqualToString:domain] && error.code == code) {
        return YES;
    } else if (error.userInfo[NSUnderlyingErrorKey]) {
        return RCErrorOrUnderlyingErrorHasCodeInDomain(error.userInfo[NSUnderlyingErrorKey], code, domain);
    }
    
    return NO;
}

/**
 去掉 `nsnull` value
 
 */
static id RCJSONObjectByRemovingKeysWithNullValue(id JSONObject , NSJSONReadingOptions readingOptions){
    if ([JSONObject isKindOfClass:[NSArray class]]) {
        NSMutableArray *marr = [NSMutableArray arrayWithCapacity:((NSArray *)JSONObject).count];
        for (id value in (NSArray *)JSONObject) {
            [marr addObject:RCJSONObjectByRemovingKeysWithNullValue(value, readingOptions)];
        }
        // 是否可变
        return (readingOptions & NSJSONReadingMutableLeaves) ? marr : [NSArray arrayWithArray:marr];
    } else if ([JSONObject isKindOfClass:[NSDictionary class]]){
        NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary *)JSONObject];
        for (id key in ((NSDictionary *)JSONObject).allKeys) {
            id value = ((NSDictionary *)JSONObject)[key];
            if (!value || [value isEqual:[NSNull null]]) {
                [mdic removeObjectForKey:key];
            } else if([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class ]]){
                mdic[key] = RCJSONObjectByRemovingKeysWithNullValue(value, readingOptions);
            }
        }
        return (readingOptions & NSJSONReadingMutableLeaves) ? mdic : [NSDictionary dictionaryWithDictionary:mdic];
    }
    return JSONObject;
}
@implementation RCJSONResponseSerializer
+ (instancetype)responseSerializer {
    return [self serializerWithReadingOptions:(NSJSONReadingOptions)0];
}

+ (instancetype)serializerWithReadingOptions:(NSJSONReadingOptions)readingOptions {
    RCJSONResponseSerializer *serializer = [[self alloc] init];
    serializer.readingOptions = readingOptions;
    
    return serializer;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    self.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", nil];
    return self;
}
-(id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error{
    // 如果不合法，如果没有错误或者code为NSURLErrorCannotDecodeContentData 不能解析，并且是规定的domain则返回nil.
    if (![self validateResponse:(NSHTTPURLResponse *)response data:data error:error]) {
        if (!error || RCErrorOrUnderlyingErrorHasCodeInDomain(*error, NSURLErrorCannotDecodeContentData, RCURLResponseSerializationErrorDomain)) {
            return nil;
        }
    }
    BOOL isSpace = [data isEqualToData:[NSData dataWithBytes:@" " length:1]];
    if (data.length == 0 || isSpace) {
        return nil;
    }
    NSError *serializationError = nil;
    id responseObject = [NSJSONSerialization JSONObjectWithData:data options:self.readingOptions error:&serializationError];
    if (!responseObject) {
        if (error) {
            *error = RCErrorWithUnderlyingError(serializationError, *error);
        }
        return nil;
    }
    // 去空
    if (self.removesKeysWithNullValues) {
        return RCJSONObjectByRemovingKeysWithNullValue(responseObject, self.readingOptions);
    }
    return responseObject;
}
#pragma mark - NSSecureCoding

- (instancetype)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (!self) {
        return nil;
    }
    self.readingOptions = [[decoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(readingOptions))] unsignedIntegerValue];
    self.removesKeysWithNullValues = [[decoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(removesKeysWithNullValues))] boolValue];
    return self;
}
- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    [coder encodeObject:@(self.readingOptions) forKey:NSStringFromSelector(@selector(readingOptions))];
    [coder encodeObject:@(self.removesKeysWithNullValues) forKey:NSStringFromSelector(@selector(removesKeysWithNullValues))];
}

#pragma mark - NSCopying
- (instancetype)copyWithZone:(NSZone *)zone {
    RCJSONResponseSerializer *serializer = [super copyWithZone:zone];
    serializer.readingOptions = self.readingOptions;
    serializer.removesKeysWithNullValues = self.removesKeysWithNullValues;
    return serializer;
}
@end
