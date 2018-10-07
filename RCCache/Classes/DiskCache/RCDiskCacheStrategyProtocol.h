//
//  RCDiskCacheStrategyProtocol.h
//  RCCache
//
//  Created by yxj on 2018/9/28.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RCDiskCacheStrategyProtocol <NSObject>

@property (nullable, nonatomic, copy) NSString *name;
@property (nonatomic, copy, readonly) NSString *path;

@property (nonatomic, assign, readonly) NSUInteger inlineThreshold;

@property (nullable, nonatomic, copy) NSData *(^customArchiveBlock)(id object);
@property (nullable, nonatomic, copy) id (^customUnarchiveBlock)(NSData *data);
@property (nullable, nonatomic, copy) NSString *(^customFileNameBlock)(NSString *key);

//@property (nonatomic, assign) NSUInteger countLimit;
//@property (nonatomic, assign) NSUInteger costLimit;
//@property (nonatomic, assign) NSUInteger ageLimit;
//@property (nonatomic, assign) NSUInteger freeDiskSpaceLimit;//剩余磁盘空间需大于这个值

@property (nonatomic, assign) BOOL enableErrorLogs;

//- (instancetype)initWithPath:(NSString *)path;
- (instancetype)initWithPath:(NSString *)path inlineThreshold:(NSUInteger)threshold;

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

- (void)clear;

@end

NS_ASSUME_NONNULL_END
