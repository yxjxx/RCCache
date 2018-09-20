//
//  RCMemoryCache.h
//  RCCache
//
//  Created by yxj on 2018/9/12.
//

#import <Foundation/Foundation.h>
#import "RCMemCacheStrategy.h"

@interface RCMemoryCache : NSObject

///> 具体实现缓存的策略类，任何实现 RCMemCacheStrategy 协议的类都可以，默认使用 RCMemCacheLRUStrategy
@property (nonatomic, strong) id <RCMemCacheStrategy> concreteCacher;

@property (nonatomic, assign, readonly) NSUInteger totalCount;
@property (nonatomic, assign, readonly) NSUInteger totalCost;
@property (nonatomic, assign) NSUInteger countLimit;
@property (nonatomic, assign) NSUInteger costLimit;
@property (nonatomic, assign) NSTimeInterval ageLimit;
@property (nonatomic, assign) NSUInteger autoTrimInterval;
@property (nonatomic, assign) BOOL shouldRemoveAllObjectsOnMemoryWarning;
@property (nonatomic, assign) BOOL shouldRemoveAllObjectsWhenEnteringBackground;
@property (nullable, copy) void(^didReceiveMemoryWarningBlock)(RCMemoryCache *cache);
@property (nullable, copy) void(^didEnterBackgroundBlock)(RCMemoryCache *cache);
@property (nonatomic, assign) BOOL needReleaseOnMainThread;
@property (nonatomic, assign) BOOL needAsyncRelease;


#pragma mark - Access Methods
- (BOOL)containsObjectForKey:(id)key;
- (nullable id)objectForKey:(id)key;
- (void)setObject:(nullable id)object forKey:(id)key;
- (void)setObject:(nullable id)object forKey:(id)key withCost:(NSUInteger)cost;
- (void)removeObjectForKey:(id)key;
- (void)removeAllObjects;

#pragma mark - Trim
- (void)trimToCount:(NSUInteger)count;
- (void)trimToCost:(NSUInteger)cost;
- (void)trimToAge:(NSTimeInterval)age;

@end
