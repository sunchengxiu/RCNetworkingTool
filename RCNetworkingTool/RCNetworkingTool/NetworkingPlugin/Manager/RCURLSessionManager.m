//
//  RCURLSessionManager.m
//  RCNetworkingTool
//
//  Created by 孙承秀 on 2019/1/11.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "RCURLSessionManager.h"
#import "RCJSONResponseSerializer.h"
#import "RCSessionTaskDelegate.h"
#import <objc/runtime.h>
typedef void (^RCURLSessionDidBecomeInvalidBlock)(NSURLSession *session, NSError *error);
typedef NSURLSessionAuthChallengeDisposition (^RCURLSessionDidReceiveAuthenticationChallengeBlock)(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential);
typedef NSURLSessionAuthChallengeDisposition (^RCURLSessionTaskDidReceiveAuthenticationChallengeBlock)(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential);
typedef void (^RCURLSessionTaskDidCompleteBlock)(NSURLSession *session, NSURLSessionTask *task, NSError *error);
typedef NSURLSessionResponseDisposition (^RCURLSessionDataTaskDidReceiveResponseBlock)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response);
typedef void (^RCURLSessionDataTaskDidReceiveDataBlock)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data);
typedef void (^RCURLSessionTaskCompletionHandler)(NSURLResponse *response, id responseObject, NSError *error);

@interface RCSwapClass : NSObject

@end

@implementation RCSwapClass
- (NSURLSessionTaskState)state{
    return NSURLSessionTaskStateCanceling;
}
// 交换系统方法
+(void)load{
    if (NSClassFromString(@"NSURLSessionTask")) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wnonnull"
        NSURLSessionDataTask *oriDataTask = [session dataTaskWithURL:nil];
#pragma clang diagnostic pop
        IMP selfResume = method_getImplementation(class_getInstanceMethod([self class], @selector(rc_resume)));
        Class currentClass = [oriDataTask class];
        while (class_getInstanceMethod(currentClass, @selector(resume))) {
            Class superClass = [currentClass superclass];
            IMP oriResume = method_getImplementation(class_getInstanceMethod(currentClass, @selector(resume)));
            IMP superResume = method_getImplementation(class_getInstanceMethod(superClass, @selector(resume)));
            if (oriResume != superResume && selfResume != oriResume) {
                [self rc_swapMethodForClass:currentClass];
            }
            currentClass = [currentClass superclass];
        }
        [oriDataTask cancel];
        [session finishTasksAndInvalidate];
    }
}
+ (void)rc_swapMethodForClass:(Class)cls{
    Method selfResume = class_getInstanceMethod(self, @selector(rc_resume));
    Method selfSuspend = class_getInstanceMethod(self, @selector(rc_suspend));
    if ([self rc_addMethod:cls selector:@selector(rc_resume) method:selfResume]) {
        [self rc_swapMethodForClass:cls oriSelector:@selector(resume) currentSelector:@selector(rc_resume)];
    }
    if ([self rc_addMethod:cls selector:@selector(rc_suspend) method:selfSuspend]) {
        [self rc_swapMethodForClass:cls oriSelector:@selector(suspend) currentSelector:@selector(rc_suspend)];
    }
}
+ (void)rc_swapMethodForClass:(Class)cls oriSelector:(SEL)oriSel currentSelector:(SEL)currentSel{
    Method ori = class_getInstanceMethod(cls, oriSel);
    Method current = class_getInstanceMethod(cls, currentSel);
    method_exchangeImplementations(ori, current);
}
+ (BOOL)rc_addMethod:(Class )cls selector:(SEL)sel method:(Method)med{
    return class_addMethod(cls, sel, method_getImplementation(med), method_getTypeEncoding(med));
}
- (void)rc_resume{
    NSURLSessionTaskState state = [self state];
    [self rc_resume];
    if (state != NSURLSessionTaskStateRunning) {
         [[NSNotificationCenter defaultCenter] postNotificationName:RCNSURLSessionTaskDidResumeNotification object:self];
    }
}
- (void)rc_suspend{
    NSURLSessionTaskState state = [self state];
    [self rc_resume];
    if (state != NSURLSessionTaskStateSuspended) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RCNSURLSessionTaskDidSuspendNotification object:self];
    }
}
@end

@interface RCURLSessionManager()<NSURLSessionTaskDelegate, NSURLSessionDataDelegate>
@property (readwrite, nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;

/**
 session
 */
@property(nonatomic , strong )NSURLSession *session;

/**
 task : taskDelegate
 */
@property(nonatomic , strong)NSMutableDictionary *mutableTaskDelegatesKeyedByTaskIdentifier;
@property (readwrite, nonatomic, strong) NSLock *lock;

/**
 The data, upload, and download tasks currently run by the managed session.
 */
@property (readonly, nonatomic, strong) NSArray <NSURLSessionTask *> *tasks;
@property (readwrite, nonatomic, copy) RCURLSessionDidBecomeInvalidBlock sessionDidBecomeInvalid;
@property (readwrite, nonatomic, copy) RCURLSessionDidReceiveAuthenticationChallengeBlock sessionDidReceiveAuthenticationChallenge;
@property (readwrite, nonatomic, copy) RCURLSessionTaskDidReceiveAuthenticationChallengeBlock taskDidReceiveAuthenticationChallenge;
@property (readwrite, nonatomic, copy) RCURLSessionTaskDidCompleteBlock taskDidComplete;
@property (readwrite, nonatomic, copy) RCURLSessionDataTaskDidReceiveResponseBlock dataTaskDidReceiveResponse;
@property (readwrite, nonatomic, copy) RCURLSessionDataTaskDidReceiveDataBlock dataTaskDidReceiveData;
- (void)setSessionDidReceiveAuthenticationChallengeBlock:(nullable NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * _Nullable __autoreleasing * _Nullable credential))block;
- (void)setTaskDidReceiveAuthenticationChallengeBlock:(nullable NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, NSURLCredential * _Nullable __autoreleasing * _Nullable credential))block;
@end
@implementation RCURLSessionManager
#pragma mark - init
-(instancetype)init{
    return [self initWithSessionConfiguration:nil];
}
-(instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration{
    if (self = [super init]) {
        if (!configuration) {
            configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        }
        self.sessionConfiguration = configuration;
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
        self.session = [NSURLSession sessionWithConfiguration:self.sessionConfiguration delegate:self delegateQueue:self.operationQueue];
        self.responseSerializer = [RCJSONResponseSerializer responseSerializer];
        self.mutableTaskDelegatesKeyedByTaskIdentifier = [NSMutableDictionary dictionary];
        self.lock = [[NSLock alloc] init];
        self.lock.name = RCURLSessionManagerLockName;
        [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
            for (NSURLSessionDataTask *task in dataTasks) {
                [self addDelegateForDataTask:task complementionHander:nil];
            }
        }];
    }
    return self;
}
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#pragma mark - set/get
- (void)addDelegateForDataTask:(NSURLSessionDataTask *)dataTask complementionHander:(void (^)(NSURLResponse *response , id responseObject , NSError *error ))completionHandler{
    RCSessionTaskDelegate *taskDelegate = [[RCSessionTaskDelegate alloc] initWithTask:dataTask];
    taskDelegate.manager = self;
    taskDelegate.completionHandler = completionHandler;
    dataTask.taskDescription = [self taskDescription];
    [self setDelegate:taskDelegate forDataTask:dataTask];
    
}
- (RCSessionTaskDelegate *)delegateForTask:(NSURLSessionTask *)task{
    NSParameterAssert(task);
    RCSessionTaskDelegate *delegate = nil;
    [self.lock lock];
    delegate = self.mutableTaskDelegatesKeyedByTaskIdentifier[@(task.taskIdentifier)];
    [self.lock unlock];
    return delegate;
}
- (void)removeDelegateForTask:(NSURLSessionTask *)task{
    NSParameterAssert(task);
    [self.lock lock];
    [self removeDelegateForTask:task];
    [self.mutableTaskDelegatesKeyedByTaskIdentifier removeObjectForKey:@(task.taskIdentifier)];
    [self.lock unlock];
}
- (void)addNotificationObserverForTask:(NSURLSessionDataTask *)task{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskDidResume:) name:RCNSURLSessionTaskDidResumeNotification object:task];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskDidSubpend:) name:RCNSURLSessionTaskDidSuspendNotification object:task];
}
- (void)removeNotificationObserverForTask:(NSURLSessionTask *)task {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RCNSURLSessionTaskDidSuspendNotification object:task];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RCNSURLSessionTaskDidResumeNotification object:task];
}
- (void)setDelegate:(RCSessionTaskDelegate *)delegate forDataTask:(NSURLSessionDataTask *)task{
    NSParameterAssert(delegate);
    NSParameterAssert(task);
    [self.lock lock];
    self.mutableTaskDelegatesKeyedByTaskIdentifier[@(task.taskIdentifier)] = delegate;
    [self addNotificationObserverForTask:task];
    [self.lock unlock];
}
- (NSArray *)taskForKeyPath:(NSString *)keypath{
    __block NSArray *tasks = nil;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        if ([keypath isEqualToString:NSStringFromSelector(@selector(dataTasks))]) {
            tasks = dataTasks;
        } else if ([keypath isEqualToString:NSStringFromSelector(@selector(uploadTasks))]){
            tasks = uploadTasks;
        } else if ([keypath isEqualToString:NSStringFromSelector(@selector(downloadTasks))]){
            tasks = downloadTasks;
        } else {
            // 合并,保留重复值
            tasks = [@[dataTasks , uploadTasks , downloadTasks] valueForKeyPath:@"@unionOfArrays.self"];
        }
        dispatch_semaphore_signal(sem);
    }];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    return tasks;
}
-(void)setResponseSerializer:(id<RCResponseSerializerProtocol>)responseSerializer{
    NSParameterAssert(responseSerializer);
    _responseSerializer = responseSerializer;
}
-(NSArray<NSURLSessionTask *> *)tasks{
    return [self taskForKeyPath:NSStringFromSelector(_cmd)];
}
-(NSArray<NSURLSessionDataTask *> *)dataTasks{
    return [self taskForKeyPath:NSStringFromSelector(_cmd)];
}
- (NSString *)taskDescription{
    return [NSString stringWithFormat:@"%@_%p",@"rongcloud",self];
}
-(void)setSessionDidBecomeInvalidBlock:(void (^)(NSURLSession * _Nonnull, NSError * _Nullable))block{
    self.sessionDidBecomeInvalid = block;
}
- (void)setSessionDidReceiveAuthenticationChallengeBlock:(NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential))block {
    self.sessionDidReceiveAuthenticationChallenge = block;
}
- (void)setTaskDidReceiveAuthenticationChallengeBlock:(NSURLSessionAuthChallengeDisposition (^)(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, NSURLCredential * __autoreleasing *credential))block {
    self.taskDidReceiveAuthenticationChallenge = block;
}
- (void)setTaskDidCompleteBlock:(void (^)(NSURLSession *session, NSURLSessionTask *task, NSError *error))block {
    self.taskDidComplete = block;
}
- (void)setDataTaskDidReceiveResponseBlock:(NSURLSessionResponseDisposition (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSURLResponse *response))block {
    self.dataTaskDidReceiveResponse = block;
}
- (void)setDataTaskDidReceiveDataBlock:(void (^)(NSURLSession *session, NSURLSessionDataTask *dataTask, NSData *data))block {
    self.dataTaskDidReceiveData = block;
}

- (BOOL)respondsToSelector:(SEL)selector {
    if (selector == @selector(URLSession:dataTask:didReceiveResponse:completionHandler:)) {
        return self.dataTaskDidReceiveResponse != nil;
    }
    
    return [[self class] instancesRespondToSelector:selector];
}
#pragma mark - method
-(NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLResponse * _Nonnull, id _Nullable, NSError * _Nullable))completionHandler{
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request];
    [self addDelegateForDataTask:dataTask complementionHander:completionHandler];
    return dataTask;
}
- (void)taskDidResume:(NSNotification *)notification{
    NSURLSessionTask *task = (NSURLSessionTask *)notification.object;
    if ([task respondsToSelector:@selector(taskDescription)]) {
        if ([[task taskDescription] isEqualToString:[self taskDescription]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:RCNetworkingTaskDidResumeNotification object:task];
            });
        }
    }
}
- (void)taskDidSubpend:(NSNotification *)notification{
    NSURLSessionTask *task = (NSURLSessionTask *)notification.object;
    if ([task respondsToSelector:@selector(taskDescription)]) {
        if ([[task taskDescription] isEqualToString:[self taskDescription]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:RCNetworkingTaskDidSuspendNotification object:task];
            });
        }
    }
}
#pragma mark - delegate
-(void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
    if (self.sessionDidBecomeInvalid) {
        self.sessionDidBecomeInvalid(session, error);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:RCURLSessionDidInvalidateNotification object:session];
}
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    RCSessionTaskDelegate *delegate = [self delegateForTask:task];
    if (delegate) {
        [delegate URLSession:session task:task didCompleteWithError:error];
        [self removeDelegateForTask:task];
    }
    if (self.taskDidComplete) {
        self.taskDidComplete(session, task, error);
    }
}
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    NSURLSessionResponseDisposition disposition = NSURLSessionResponseAllow;
    if (self.dataTaskDidReceiveResponse) {
        disposition = self.dataTaskDidReceiveResponse(session , dataTask , response);
    }
    if (completionHandler) {
        completionHandler(disposition);
    }
}
-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    RCSessionTaskDelegate *delegate = [self delegateForTask:dataTask];
    if (delegate) {
        [delegate URLSession:session dataTask:dataTask didReceiveData:data];
    }
    if (self.dataTaskDidReceiveData) {
        self.dataTaskDidReceiveData(session, dataTask, data);
    }
}
@end
