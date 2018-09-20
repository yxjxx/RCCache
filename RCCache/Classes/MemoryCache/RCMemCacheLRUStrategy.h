//
//  RCMemCacheLRUStrategy.h
//  RCCache
//
//  Created by yxj on 2018/9/13.
//

#import <Foundation/Foundation.h>
#import "RCMemCacheStrategy.h"

@interface RCMemCacheLRUStrategy : NSObject <RCMemCacheStrategy>

@property (nonatomic, assign, readonly) NSUInteger totalCount;
@property (nonatomic, assign, readonly) NSUInteger totalCost;

@property (nonatomic, assign) BOOL needReleaseOnMainThread;
@property (nonatomic, assign) BOOL needAsyncRelease;

- (void)trimToCount:(NSUInteger)count;
- (void)trimToCost:(NSUInteger)cost;
- (void)trimToAge:(NSTimeInterval)age;
- (void)trimTailNodeIfOverCountLimit:(NSUInteger)countLimit;

@end
