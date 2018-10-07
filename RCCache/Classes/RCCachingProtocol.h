//
//  RCCachingProtocol.h
//  RCCache
//
//  Created by yxj on 2018/9/12.
//

#import <Foundation/Foundation.h>

///> 适用于内存缓存
@protocol RCCachingSyncProtocol <NSObject>

- (BOOL)containsObjectForKey:(NSString *)key;

- (nullable id<NSCoding>)objectForKey:(NSString *)key;

- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key;

- (void)removeObjectForKey:(NSString *)key;

- (void)removeAllObjects;

@end

@protocol RCCachingAsyncProtocol <NSObject>

- (void)containsObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key, BOOL contains))block;

- (void)objectForKey:(NSString *)key withBlock:(void(^)(NSString *key, id<NSCoding> _Nullable object))block;

- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key withBlock:(void(^)(void))block;

- (void)removeObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key))block;

- (void)removeAllObjectsWithBlock:(void(^)(void))block;
- (void)removeAllObjectsWithProgressBlock:(nullable void(^)(int removedCount, int totalCount))progress
                                 endBlock:(nullable void(^)(BOOL error))end;

@end

///> 使用于磁盘缓存
@protocol RCCachingProtocol <RCCachingSyncProtocol, RCCachingAsyncProtocol>

@end
