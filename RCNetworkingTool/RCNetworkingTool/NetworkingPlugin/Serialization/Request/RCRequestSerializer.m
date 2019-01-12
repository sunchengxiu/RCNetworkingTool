//
//  RCRequestSerializer.m
//  RCNetworkingTool
//
//  Created by 孙承秀 on 2019/1/10.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCRequestSerializer.h"
#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "RCQueryModel.h"
static void *RCHTTPRequestObserverContext = &RCHTTPRequestObserverContext;
NSString * const RCURLRequestSerializationErrorDomain = @"com.rongcloud.error.serialization.request";
typedef  NSString * (^RCQueryStringSerializationBlock)(NSURLRequest *request, id parameters, NSError  * __autoreleasing*error);
static NSArray *RCHTTPRequestObservedKeyPaths(){
    static NSArray *oparr = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        oparr = @[NSStringFromSelector(@selector(timeoutInterval))];
    });
    return oparr;
}
@interface RCRequestSerializer()

/**
 http headers
 */
@property(nonatomic , strong )NSMutableDictionary <NSString * , NSString *>*mHttpRequestHeaders;
@property (readwrite, nonatomic, strong) dispatch_queue_t requestHeaderQueue;

/**
 需要 query 的方法名称，将 parameters 作为 query，默认为 `get` , `DELETE`,`HEAD`
 */
@property(nonatomic , strong)NSSet <NSString *>*needQueryParametersSet;

/**
 监控属性变化，需要设置到 系统 URLRequest 中
 */
@property (nonatomic, strong) NSMutableSet *mutableObservedChangedKeyPaths;
@property(nonatomic , copy)RCQueryStringSerializationBlock queryBlock;
@end
@implementation RCRequestSerializer
#pragma mark - init
+ (instancetype)requestSerializer {
    return [[self alloc] init];
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.stringEncoding = NSUTF8StringEncoding;
    
    self.mHttpRequestHeaders = [NSMutableDictionary dictionary];
    self.requestHeaderQueue = dispatch_queue_create("com.rongcloud.requestHeaderQueue", DISPATCH_QUEUE_CONCURRENT);
    
    // Accept-Language HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.4
    NSMutableArray *acceptLanguagesComponents = [NSMutableArray array];
    [[NSLocale preferredLanguages] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        float q = 1.0f - (idx * 0.1f);
        [acceptLanguagesComponents addObject:[NSString stringWithFormat:@"%@;q=%0.1g", obj, q]];
        *stop = q <= 0.5f;
    }];
    [self setValue:[acceptLanguagesComponents componentsJoinedByString:@", "] forHTTPHeaderField:@"Accept-Language"];
    
    NSString *userAgent = nil;
    // User-Agent Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.43
    userAgent = [NSString stringWithFormat:@"%@/%@ (%@; iOS %@; Scale/%0.2f)", [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleExecutableKey] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleIdentifierKey], [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] ?: [[NSBundle mainBundle] infoDictionary][(__bridge NSString *)kCFBundleVersionKey], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion], [[UIScreen mainScreen] scale]];

    if (userAgent) {
        if (![userAgent canBeConvertedToEncoding:NSASCIIStringEncoding]) {
            NSMutableString *mutableUserAgent = [userAgent mutableCopy];
            if (CFStringTransform((__bridge CFMutableStringRef)(mutableUserAgent), NULL, (__bridge CFStringRef)@"Any-Latin; Latin-ASCII; [:^ASCII:] Remove", false)) {
                userAgent = mutableUserAgent;
            }
        }
        [self setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    }
    
    // HTTP Method Definitions; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html
    // 需要 query 的方法
    self.needQueryParametersSet = [NSSet setWithObjects:@"GET", @"HEAD", @"DELETE", nil];
    self.mutableObservedChangedKeyPaths = [NSMutableSet set];
    for (NSString *keyPath in RCHTTPRequestObservedKeyPaths()) {
        if ([self respondsToSelector:NSSelectorFromString(keyPath)]) {
            // 需要观察的属性集合
            [self addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:RCHTTPRequestObserverContext];
        }
    }
    return self;
}

- (void)dealloc {
    for (NSString *keyPath in RCHTTPRequestObservedKeyPaths()) {
        if ([self respondsToSelector:NSSelectorFromString(keyPath)]) {
            [self removeObserver:self forKeyPath:keyPath context:RCHTTPRequestObserverContext];
        }
    }
}
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super init]) {
        self.mHttpRequestHeaders = [[aDecoder decodeObjectOfClass:[NSDictionary class] forKey:NSStringFromSelector(@selector(mHttpRequestHeaders))] mutableCopy];
    }
    return self;
}
-(void)encodeWithCoder:(NSCoder *)aCoder{
    dispatch_sync(self.requestHeaderQueue, ^{
        [aCoder encodeObject:self.mHttpRequestHeaders forKey:NSStringFromSelector(@selector(mHttpRequestHeaders))];
    });
}
-(id)copyWithZone:(NSZone *)zone{
    RCRequestSerializer *ser = [[self class] allocWithZone:zone];
    dispatch_sync(self.requestHeaderQueue, ^{
        ser.mHttpRequestHeaders = [self.mHttpRequestHeaders mutableCopyWithZone:zone];
    });
    ser.queryBlock = self.queryBlock;
    return ser;
}
+ (BOOL)supportsSecureCoding{
    return YES;
}
#pragma mark - set get
- (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval {
    [self willChangeValueForKey:NSStringFromSelector(@selector(timeoutInterval))];
    _timeoutInterval = timeoutInterval;
    [self didChangeValueForKey:NSStringFromSelector(@selector(timeoutInterval))];
}
-(void)setNetworkServiceType:(NSURLRequestNetworkServiceType)networkServiceType{
    [self willChangeValueForKey:NSStringFromSelector(@selector(networkServiceType))];
    _networkServiceType = networkServiceType;
    [self didChangeValueForKey:NSStringFromSelector(@selector(networkServiceType))];
}
-(void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field{
    dispatch_sync(self.requestHeaderQueue, ^{
        [self.mHttpRequestHeaders setValue:value forKey:field];
    });
}
-(NSString *)valueForHTTPHeaderField:(NSString *)field{
    __block NSString *value;
    dispatch_sync(self.requestHeaderQueue, ^{
        value = [self.mHttpRequestHeaders valueForKey:field] ;
    });
    return value;
}
-(NSDictionary<NSString *,NSString *> *)httpRequestHeaders{
    __block NSDictionary *value;
    dispatch_sync(self.requestHeaderQueue, ^{
        value = [NSDictionary dictionaryWithDictionary:self.mHttpRequestHeaders];
    });
    return value;
}
- (void)customQueryStringWithBlock:(NSString * _Nonnull (^)(NSURLRequest * _Nonnull, id _Nonnull, NSError *__autoreleasing * ))block{
    self.queryBlock = block;
}
#pragma mark - requset
-(NSMutableURLRequest *)requestWithMethod:(NSString *)method urlString:(NSString *)urlString parameters:(id)parameters error:(NSError *__autoreleasing *)error{
    NSParameterAssert(method);
    NSParameterAssert(urlString);
    NSURL *url = [NSURL URLWithString:urlString];
    NSParameterAssert(url);
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = method;
    for (NSString *keypath in RCHTTPRequestObservedKeyPaths()) {
        if ([self.mutableObservedChangedKeyPaths containsObject:keypath]) {
            [request setValue:[self valueForKey:keypath] forKey:keypath];
        }
    }
    request = [[self serializingRequest:request withParameters:parameters error:error] mutableCopy];
    return request;
}
- (nullable NSURLRequest *)serializingRequest:(nonnull NSURLRequest *)request withParameters:(nullable id)parameters error:( NSError *__autoreleasing*)error {
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    [self.httpRequestHeaders enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if (![request valueForHTTPHeaderField:key]) {
            [mutableRequest setValue:obj forHTTPHeaderField:key];
        }
    }];
    NSString *query = nil;
    // 参数设置
    if (parameters) {
        // 是否自定义 query
        if (self.queryBlock) {
            NSError *qerr;
            query = self.queryBlock(request,parameters,&qerr);
            if (qerr) {
                if (error) {
                    *error = qerr;
                }
                return nil;
            }
        } else {
            query = [self queryStringFromParameters:parameters];
        }
    }
    if ([self.needQueryParametersSet containsObject:[[request HTTPMethod] uppercaseString] ]) {
        if (query && query.length > 0) {
            mutableRequest.URL = [NSURL URLWithString:[[mutableRequest.URL absoluteString] stringByAppendingFormat:mutableRequest.URL.query ? @"&%@" : @"?%@",query] ];
        }
    } else {
        if (!query) {
            query = @"";
        }
        if (![mutableRequest valueForHTTPHeaderField:@"Content-Type"]) {
            [mutableRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        }
        [mutableRequest setHTTPBody:[query dataUsingEncoding:self.stringEncoding]];
    }
    
    return mutableRequest;
}
#pragma mark - query
/**
 将参数转化为 query 字符串
 
 @param parameters 参数
 @return query 字符串
 */
- (NSString *)queryStringFromParameters:(NSDictionary *)parameters{
    NSMutableArray *marr = [NSMutableArray array];
    for (RCQueryModel *model in [self queryFromDic:parameters]) {
        [marr addObject:[model encodeQuery]];
    }
    //name=sun&age=25&sex=man
    return [marr componentsJoinedByString:@"&"];
}
- (NSArray *)queryFromDic:(NSDictionary *)dic{
    return [self queryWithKey:nil value:dic];
}
/**
 转化为query模型
 */
- (NSArray *)queryWithKey:(NSString *)key value:(id)value{
    NSMutableArray *array = [NSMutableArray array];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"description" ascending:YES selector:@selector(compare:)];
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dic = (NSDictionary *)value;
        NSArray *keys = [dic.allKeys sortedArrayUsingDescriptors:@[sort]];
        for (id newKey in keys) {
            id newValue = dic[keys];
            if (newValue) {
                // person[name]=sun
                [array addObjectsFromArray:[self queryWithKey:key?[NSString stringWithFormat:@"%@[%@]",key,newKey]:newKey value:newValue]];
            }
        }
    } else if ([value isKindOfClass:[NSArray class]]){
        NSArray *arr = (NSArray *)value;
        for (id newKey in arr) {
            // person[]=sun
            [array addObjectsFromArray:[self queryWithKey:[NSString stringWithFormat:@"%@[]",key] value:newKey]];
        }
    } else if ([value isKindOfClass:[NSSet class]]){
        NSSet *set = (NSSet *)value;
        NSArray *keys = [set sortedArrayUsingDescriptors:@[sort]];
        for (id newKey in keys) {
            //person=a , person=b
            [array addObjectsFromArray:[self queryWithKey:key value:newKey]];
        }
    } else {
        //name=sun模型
        [array addObject:[[RCQueryModel alloc] initWithField:key value:value] ];
    }
    return array;
}
#pragma mark - kvo
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    // 记录属性变更
    if (context == RCHTTPRequestObserverContext) {
        if ([change[NSKeyValueChangeNewKey] isEqual:[NSNull null]]) {
            [self.mutableObservedChangedKeyPaths removeObject:keyPath];
        } else {
            [self.mutableObservedChangedKeyPaths addObject:keyPath];
        }
    }
    
}
@end
