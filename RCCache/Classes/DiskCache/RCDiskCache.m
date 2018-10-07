//
//  RCDiskCache.m
//  RCCache
//
//  Created by yxj on 2018/9/24.
//

#import "RCDiskCache.h"
#import "RCDiskCacheLRUStrategy.h"
#import <objc/runtime.h>

static const int extended_data_key;

/// Free disk space in bytes.
static int64_t _RCDiskSpaceFree() {
    NSError *error = nil;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (error) return -1;
    int64_t space =  [[attrs objectForKey:NSFileSystemFreeSize] longLongValue];
    if (space < 0) space = -1;
    return space;
}

@implementation RCDiskCache {
    NSString *_path;
    NSUInteger _inlineThreshold;
}

- (instancetype)initWithPath:(NSString *)path {
    return [self initWithPath:path inlineThreshold:1024 * 20]; // 20KB
}

- (instancetype)initWithPath:(NSString *)path inlineThreshold:(NSUInteger)threshold {
    self = [super init];
    if (!self) return nil;
    
    //stash
    _path = path;
    _inlineThreshold = threshold;
    
    _countLimit = NSUIntegerMax;
    _costLimit = NSUIntegerMax;
    _ageLimit = DBL_MAX;
    _freeDiskSpaceLimit = 0;
    _autoTrimInterval = 60;
    
    [self _trimRecursively];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appWillBeTerminated) name:UIApplicationWillTerminateNotification object:nil];
    
    return self;
}

- (void)_trimRecursively {
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_autoTrimInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf _trimInBackground];
        [strongSelf _trimRecursively];
    });
}

- (void)_trimInBackground {
    // 切到 后台线程去

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self.concreteCacher trimToCost:self.costLimit];
        [self.concreteCacher trimToCount:self.countLimit];
        [self.concreteCacher trimToAge:self.ageLimit];
        [self _trimToFreeDiskSpace:self.freeDiskSpaceLimit];
    });
}

- (void)_trimToFreeDiskSpace:(NSUInteger)targetFreeDiskSpace {
    if (targetFreeDiskSpace == 0) return;
    int64_t totalBytes = self.concreteCacher.totalCost;
    if (totalBytes <= 0) return;
    int64_t diskFreeBytes = _RCDiskSpaceFree();
    if (diskFreeBytes < 0) return;
    int64_t needTrimBytes = targetFreeDiskSpace - diskFreeBytes;
    if (needTrimBytes <= 0) return;
    int64_t costLimit = totalBytes - needTrimBytes;
    if (costLimit < 0) costLimit = 0;
    [self.concreteCacher trimToCost:(int)costLimit];
}

- (void)_appWillBeTerminated {
    [self.concreteCacher clear];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}

- (id<RCDiskCacheStrategyProtocol>)concreteCacher{
    if (_concreteCacher == nil) {
        _concreteCacher = [[RCDiskCacheLRUStrategy alloc] initWithPath:_path inlineThreshold:_inlineThreshold];
    }
    return _concreteCacher;
}

- (BOOL)containsObjectForKey:(NSString *)key {
    return [self.concreteCacher containsObjectForKey:key];
}

- (void)containsObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key, BOOL contains))block {
    [self.concreteCacher containsObjectForKey:key withBlock:block];
}

- (nullable id<NSCoding>)objectForKey:(NSString *)key{
    return [self.concreteCacher objectForKey:key];
}

- (void)objectForKey:(NSString *)key withBlock:(void(^)(NSString *key, id<NSCoding> _Nullable object))block{
    [self.concreteCacher objectForKey:key withBlock:block];
}

- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key {
    [self.concreteCacher setObject:object forKey:key];
}
- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key withBlock:(void(^)(void))block {
    [self.concreteCacher setObject:object forKey:key withBlock:block];
}

- (void)removeObjectForKey:(NSString *)key {
    [self.concreteCacher removeObjectForKey:key];
}
- (void)removeObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key))block {
    [self.concreteCacher removeObjectForKey:key withBlock:block];
}
- (void)removeAllObjects {
    [self.concreteCacher removeAllObjects];
}

- (void)removeAllObjectsWithBlock:(void(^)(void))block {
    [self.concreteCacher removeAllObjectsWithBlock:block];
}
- (void)removeAllObjectsWithProgressBlock:(nullable void(^)(int removedCount, int totalCount))progress
                                 endBlock:(nullable void(^)(BOOL error))end{
    [self.concreteCacher removeAllObjectsWithProgressBlock:progress endBlock:end];
}
- (NSInteger)totalCount {
    return [self.concreteCacher totalCount];
}

- (void)totalCountWithBlock:(void(^)(NSInteger totalCount))block {
    [self.concreteCacher totalCountWithBlock:block];
}

- (NSInteger)totalCost {
    return [self.concreteCacher totalCost];
}

- (void)totalCostWithBlock:(void(^)(NSInteger totalCost))block{
    [self.concreteCacher totalCostWithBlock:block];
}

- (void)trimToCount:(NSUInteger)count {
    [self.concreteCacher trimToCount:count];
}

- (void)trimToCount:(NSUInteger)count withBlock:(void(^)(void))block {
    [self.concreteCacher trimToCount:count withBlock:block];
}

- (void)trimToCost:(NSUInteger)cost {
    [self.concreteCacher trimToCost:cost];
}
- (void)trimToCost:(NSUInteger)cost withBlock:(void(^)(void))block {
    [self.concreteCacher trimToCost:cost withBlock:block];
}

- (void)trimToAge:(NSTimeInterval)age {
    [self.concreteCacher trimToAge:age];
}

- (void)trimToAge:(NSTimeInterval)age withBlock:(void(^)(void))block {
    [self.concreteCacher trimToAge:age withBlock:block];
}

+ (NSData *)getExtendedDataFromObject:(id)object {
    if (!object) return nil;
    return (NSData *)objc_getAssociatedObject(object, &extended_data_key);
}

+ (void)setExtendedData:(NSData *)extendedData toObject:(id)object {
    if (!object) return;
    objc_setAssociatedObject(object, &extended_data_key, extendedData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - RCCacheSubscriptingProtocol
- (id)objectForKeyedSubscript:(id)key {
    return [self objectForKey:key];
}

- (void)setObject:(id)object forKeyedSubscript:(id)key {
    if (object == nil) {
        [self removeObjectForKey:key];
    } else {
        [self setObject:object forKey:key];
    }
}

@end
