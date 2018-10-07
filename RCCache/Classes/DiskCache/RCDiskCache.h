//
//  RCDiskCache.h
//  RCCache
//
//  Created by yxj on 2018/9/24.
//

#import <Foundation/Foundation.h>
#import "RCDiskCacheStrategyProtocol.h"
#import "RCCachingProtocol.h"
#import "RCCacheSubscriptingProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCDiskCache : NSObject <RCCacheSubscriptingProtocol, RCCachingProtocol>

///> 具体实现缓存的策略类，任何实现 RCDiskCacheStrategyProtocol 协议的类都可以，默认使用 RCDiskCacheLRUStrategy
@property (nonatomic, strong) id <RCDiskCacheStrategyProtocol> concreteCacher;

@property NSTimeInterval autoTrimInterval;

@property (nonatomic, assign) NSUInteger countLimit;
@property (nonatomic, assign) NSUInteger costLimit;
@property (nonatomic, assign) NSUInteger ageLimit;
@property (nonatomic, assign) NSUInteger freeDiskSpaceLimit;//剩余磁盘空间需大于这个值

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

- (instancetype)initWithPath:(NSString *)path;
- (instancetype)initWithPath:(NSString *)path inlineThreshold:(NSUInteger)threshold NS_DESIGNATED_INITIALIZER;

- (BOOL)containsObjectForKey:(NSString *)key;
- (void)containsObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key, BOOL contains))block;

- (nullable id<NSCoding>)objectForKey:(NSString *)key;
- (void)objectForKey:(NSString *)key withBlock:(void(^)(NSString *key, id<NSCoding> _Nullable object))block;

- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key;
- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key withBlock:(void(^)(void))block;

- (void)removeObjectForKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key withBlock:(void(^)(NSString *key))block;
- (void)removeAllObjects;
- (void)removeAllObjectsWithBlock:(void(^)(void))block;
- (void)removeAllObjectsWithProgressBlock:(nullable void(^)(int removedCount, int totalCount))progress
                                 endBlock:(nullable void(^)(BOOL error))end;
- (NSInteger)totalCount;
- (void)totalCountWithBlock:(void(^)(NSInteger totalCount))block;

- (NSInteger)totalCost;
- (void)totalCostWithBlock:(void(^)(NSInteger totalCost))block;

- (void)trimToCount:(NSUInteger)count;
- (void)trimToCount:(NSUInteger)count withBlock:(void(^)(void))block;

- (void)trimToCost:(NSUInteger)cost;
- (void)trimToCost:(NSUInteger)cost withBlock:(void(^)(void))block;

- (void)trimToAge:(NSTimeInterval)age;
- (void)trimToAge:(NSTimeInterval)age withBlock:(void(^)(void))block;

+ (nullable NSData *)getExtendedDataFromObject:(id)object;
+ (void)setExtendedData:(nullable NSData *)extendedData toObject:(id)object;

@end

NS_ASSUME_NONNULL_END
