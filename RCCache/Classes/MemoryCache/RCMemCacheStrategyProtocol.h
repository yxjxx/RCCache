//
//  RCMemCacheStrategy.h
//  RCCache
//
//  Created by yxj on 2018/9/12.
//

#import <Foundation/Foundation.h>

/**
 Memory cache abstract Strategy
 */
@protocol RCMemCacheStrategyProtocol <NSObject>

@property (nonatomic, assign, readonly) NSUInteger totalCount;
@property (nonatomic, assign, readonly) NSUInteger totalCost;
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
- (void)trimToCount:(NSUInteger)countLimit;
- (void)trimToCost:(NSUInteger)costLimit;
- (void)trimToAge:(NSTimeInterval)ageLimit;
- (void)trimTailNodeIfOverCountLimit:(NSUInteger)countLimit;

@end
