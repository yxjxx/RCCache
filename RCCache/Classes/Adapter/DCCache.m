//
//  DCCache.m
//  RCCache
//
//  Created by yxj on 2018/10/7.
//

#import "DCCache.h"
#import "YYCache.h"
#import "RCCache.h"

@interface DCCache()

@property (nonatomic, copy) NSNumber *isUseYYCache;

@end

@implementation DCCache {
    YYCache *_yycache;
    RCCache *_rccache;
}

- (nullable instancetype)initWithName:(NSString *)name {
    if (name.length == 0) return nil;
    NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *path = [cacheFolder stringByAppendingPathComponent:name];
    return [self initWithPath:path];
}

- (nullable instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        if ([self p_useYYCache]) {
            _yycache = [[YYCache alloc] initWithPath:path];
        } else {
            _rccache = [[RCCache alloc] initWithPath:path];
        }
    }
    return self;
}

+ (nullable instancetype)cacheWithName:(NSString *)name {
    return [[self alloc] initWithName:name];
}

+ (nullable instancetype)cacheWithPath:(NSString *)path {
    return [[self alloc] initWithPath:path];
}

- (id<RCCachingProtocol>)concreteCacher {
    if ([self p_useYYCache]) {
        return (id<RCCachingProtocol>)_yycache;
    } else {
        return _rccache;
    }
}

#pragma mark - access method
- (BOOL)containsObjectForKey:(NSString *)key {
    return [self.concreteCacher containsObjectForKey:key];
}

- (void)containsObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key, BOOL contains))block {
    [self.concreteCacher containsObjectForKey:key withBlock:block];
}

- (nullable id<NSCoding>)objectForKey:(NSString *)key{
    return [self.concreteCacher objectForKey:key];
}

- (void)objectForKey:(NSString *)key withBlock:(void(^)(NSString *key, id<NSCoding> _Nullable object))block {
    [self.concreteCacher objectForKey:key withBlock:block];
}

- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key{
    [self.concreteCacher setObject:object forKey:key];
}

- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key withBlock:(void(^)(void))block{
    [self.concreteCacher setObject:object forKey:key withBlock:block];
}

- (void)removeObjectForKey:(NSString *)key {
    [self.concreteCacher removeObjectForKey:key];
}

- (void)removeObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key))block{
    [self.concreteCacher removeObjectForKey:key withBlock:block];
}

- (void)removeAllObjects{
    [self.concreteCacher removeAllObjects];
}

- (void)removeAllObjectsWithBlock:(void(^)(void))block {
    [self.concreteCacher removeAllObjectsWithBlock:block];
}

- (void)removeAllObjectsWithProgressBlock:(nullable void(^)(int removedCount, int totalCount))progress
                                 endBlock:(nullable void(^)(BOOL error))end {
    [self.concreteCacher removeAllObjectsWithProgressBlock:progress endBlock:end];
}

- (id<RCCachingSyncProtocol>)memoryCache {
    if ([self p_useYYCache]) {
        return (id<RCCachingSyncProtocol>)_yycache.memoryCache;
    } else {
        return _rccache.memoryCache;
    }
}

- (id<RCCachingProtocol>)diskCache {
    if ([self p_useYYCache]) {
        return (id<RCCachingProtocol>)_yycache.diskCache;
    } else {
        return _rccache.diskCache;
    }
}

- (BOOL)p_useYYCache {
    return self.isUseYYCache.boolValue;
}

- (NSNumber *)isUseYYCache {
    if (!_isUseYYCache) {
        _isUseYYCache = @0; //RICO TODO:apollo switch
    }
    return _isUseYYCache;
}

@end
