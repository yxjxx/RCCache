//
//  RCDiskCacheLRUStrategy.m
//  RCCache
//
//  Created by yxj on 2018/9/24.
//

#import "RCDiskCacheLRUStrategy.h"
#import "RCKVStorage.h"
#import <CommonCrypto/CommonCrypto.h>
#import <objc/runtime.h>
#import "RCDiskCache.h"

#define Lock() dispatch_semaphore_wait(self->_kvLock, DISPATCH_TIME_FOREVER)
#define Unlock() dispatch_semaphore_signal(self->_kvLock)

/// String's md5 hash.
static NSString *_RCNSStringMD5(NSString *string) {
    if (!string) return nil;
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0],  result[1],  result[2],  result[3],
            result[4],  result[5],  result[6],  result[7],
            result[8],  result[9],  result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

static NSMapTable *_globalInstances;
static dispatch_semaphore_t _globalInstancesLock;

static void _RCDiskCacheLRUStrategyInitGlobal() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _globalInstancesLock = dispatch_semaphore_create(1);
        _globalInstances = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
    });
}

static RCDiskCacheLRUStrategy *_RCDiskCacheLRUStrategyGetGlobal(NSString *path) {
    if (path.length == 0) return nil;
    _RCDiskCacheLRUStrategyInitGlobal();
    dispatch_semaphore_wait(_globalInstancesLock, DISPATCH_TIME_FOREVER);
    id lruStrategy = [_globalInstances objectForKey:path];
    dispatch_semaphore_signal(_globalInstancesLock);
    return lruStrategy;
}

static void _RCDiskCacheLRUStrategySetGlobal(RCDiskCacheLRUStrategy *lruStrategy) {
    if (lruStrategy.path.length == 0) return;
    _RCDiskCacheLRUStrategyInitGlobal();
    dispatch_semaphore_wait(_globalInstancesLock, DISPATCH_TIME_FOREVER);
    [_globalInstances setObject:lruStrategy forKey:lruStrategy.path];
    dispatch_semaphore_signal(_globalInstancesLock);
}

@implementation RCDiskCacheLRUStrategy {
    RCKVStorage *_kv;
    dispatch_semaphore_t _kvLock;
    dispatch_queue_t _queue;
}

//when call _trim*, ensure thread safe outside
- (void)_trimToCost:(NSUInteger)costLimit {
    if (costLimit >= INT_MAX) return;
    [_kv removeItemsToFitSize:(int)costLimit];
}

- (void)_trimToCount:(NSUInteger)countLimit {
    if (countLimit >= INT_MAX) return;
    [_kv removeItemsToFitCount:(int)countLimit];
}

- (void)_trimToAge:(NSTimeInterval)ageLimit {
    if (ageLimit <= 0) {
        [_kv removeAllItems];
        return;
    }
    long timestamp = time(NULL);
    if (timestamp <= ageLimit) return;
    long age = timestamp - ageLimit;
    if (age >= INT_MAX) return;
    [_kv removeItemsEarlierThanTime:(int)age];
}

- (instancetype)initWithPath:(NSString *)path inlineThreshold:(NSUInteger)threshold {
    self = [super init];
    if (!self) return nil;
    
    RCDiskCacheLRUStrategy *globalDiskLru = _RCDiskCacheLRUStrategyGetGlobal(path);
    if (globalDiskLru) return globalDiskLru;
    
    RCKVStorageType type;
    if (threshold == 0) {
        type = RCKVStorageTypeFile;
    } else if (threshold == NSUIntegerMax) {
        type = RCKVStorageTypeSQLite;
    } else {
        type = RCKVStorageTypeMixed;
    }
    
    RCKVStorage *kv = [[RCKVStorage alloc] initWithPath:path type:type];
    if (!kv) return nil;
    
    _kv = kv;
    _kvLock = dispatch_semaphore_create(1);
    _queue = dispatch_queue_create("com.xiaojukeji.cache.lru.disk", DISPATCH_QUEUE_CONCURRENT);
    _RCDiskCacheLRUStrategySetGlobal(self);
    return self;
}

- (BOOL)containsObjectForKey:(NSString *)key {
    if (!key) return NO;
    Lock();
    BOOL contains = [_kv itemExistsForKey:key];
    Unlock();
    return contains;
}

- (void)containsObjectForKey:(NSString *)key withBlock:(void (^)(NSString * _Nonnull, BOOL))block {
    if (!block) return;
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        BOOL contains = [strongSelf containsObjectForKey:key];
        block(key, contains);
    });
}

- (id<NSCoding>)objectForKey:(NSString *)key {
    if (!key) return nil;
    Lock();
    RCKVStorageItem *item = [_kv getItemForKey:key];
    Unlock();
    if (!item.value) return nil;
    
    id object = nil;

    if (self.customArchiveBlock) {
        object = self.customArchiveBlock(item.value);
    } else {
        @try {
            object = [NSKeyedUnarchiver unarchiveObjectWithData:item.value];
        } @catch (NSException *exception) {
            //nothing to do...
        }
    }
    if (object && item.extendedData) {
        [RCDiskCache setExtendedData:item.extendedData toObject:object];
    }
    
    return object;
}

- (void)objectForKey:(NSString *)key withBlock:(void (^)(NSString * _Nonnull, id<NSCoding> _Nullable))block {
    if (!block) return;
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        id<NSCoding> object = [strongSelf objectForKey:key];
        block(key, object);
    });
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key {
    if (!key) return;
    if (!object) {
        [self removeObjectForKey:key];
        return;
    }
    
    NSData *extendedData = [RCDiskCache getExtendedDataFromObject:object];
    NSData *value = nil;
    if (self.customArchiveBlock) {
        value = self.customArchiveBlock(object);
    } else {
        @try {
            value = [NSKeyedArchiver archivedDataWithRootObject:object];
        } @catch (NSException *exception) {
            //do nothing
        }
    }
    if (!value) return;
    NSString *filename = nil;
    if (_kv.type != RCKVStorageTypeSQLite) {
        if (value.length > self.inlineThreshold) {
            filename = [self _filenameForKey:key];
        }
    }
    Lock();
    [_kv saveItemWithKey:key value:value filename:filename extendedData:extendedData];
    Unlock();
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key withBlock:(void (^)(void))block {
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf setObject:object forKey:key];
        if (block) block();
    });
}

- (void)removeObjectForKey:(NSString *)key {
    if (!key) return;
    Lock();
    [_kv removeItemForKey:key];
    Unlock();
}

- (void)removeObjectForKey:(NSString *)key withBlock:(void (^)(NSString * _Nonnull))block {
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf removeObjectForKey:key];
        if (block) block(key);
    });
}

- (void)removeAllObjects {
    Lock();
    [_kv removeAllItems];
    Unlock();
}

- (void)removeAllObjectsWithBlock:(void (^)(void))block {
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf removeAllObjects];
        if (block) block();
    });
}

- (void)removeAllObjectsWithProgressBlock:(void (^)(int, int))progress endBlock:(void (^)(BOOL))end {
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            if (end) end(YES);
            return;
        }
        Lock();
        [strongSelf->_kv removeAllItemsWithProgressBlock:progress endBlock:end];
        Unlock();
    });
}

- (NSInteger)totalCount {
    Lock();
    int count = [_kv getItemsCount];
    Unlock();
    return count;
}

- (void)totalCountWithBlock:(void (^)(NSInteger))block {
    if (!block) return;
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSInteger totalCount = [strongSelf totalCount];
        if (block) block(totalCount);
    });
}

- (NSInteger)totalCost {
    Lock();
    int cost = [_kv getItemsSize];
    Unlock();
    return cost;
}

- (void)totalCostWithBlock:(void (^)(NSInteger))block {
    if (!block) return;
    __weak typeof(self) weakSelf = self;
    dispatch_async(_queue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSInteger totalCost = [strongSelf totalCost];
        if (block) block(totalCost);
    });
}

- (void)trimToCount:(NSUInteger)count {
    Lock();
    [self _trimToCount:count];
    Unlock();
}

- (void)trimToCount:(NSUInteger)count withBlock:(void(^)(void))block {
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        [self trimToCount:count];
        if (block) block();
    });
}

- (void)trimToCost:(NSUInteger)cost {
    Lock();
    [self _trimToCost:cost];
    Unlock();
}

- (void)trimToCost:(NSUInteger)cost withBlock:(void(^)(void))block {
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        [self trimToCost:cost];
        if (block) block();
    });
}

- (void)trimToAge:(NSTimeInterval)age {
    Lock();
    [self _trimToAge:age];
    Unlock();
}

- (void)trimToAge:(NSTimeInterval)age withBlock:(void(^)(void))block {
    __weak typeof(self) _self = self;
    dispatch_async(_queue, ^{
        __strong typeof(_self) self = _self;
        [self trimToAge:age];
        if (block) block();
    });
}

- (void)clear {
    Lock();
    _kv = nil;
    Unlock();
}

- (NSString *)_filenameForKey:(NSString *)key {
    NSString *filename = nil;
    if (self.customFileNameBlock) filename = self.customFileNameBlock(key);
    if (!filename) {
        filename = _RCNSStringMD5(key);
    }
    return filename;
}

@end
