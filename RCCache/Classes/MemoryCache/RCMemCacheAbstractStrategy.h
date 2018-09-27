//
//  RCMemCacheAbstractStrategy.h
//  Pods-RCCache_Example
//
//  Created by yxj on 2018/9/20.
//

#import <Foundation/Foundation.h>
#import "RCMemCacheStrategyProtocol.h"

NS_ASSUME_NONNULL_BEGIN


/**
 内存缓存的抽象策略基类，不做具体实现，不要直接使用这个类，一般不推荐外部继承这个类，导致影响范围不可控制
 */
@interface RCMemCacheAbstractStrategy : NSObject <RCMemCacheStrategyProtocol>

@property (nonatomic, assign, readonly) NSUInteger totalCount;
@property (nonatomic, assign, readonly) NSUInteger totalCost;

@property (nonatomic, assign) BOOL needReleaseOnMainThread;
@property (nonatomic, assign) BOOL needAsyncRelease;


@end

NS_ASSUME_NONNULL_END
