//
//  RCMemCacheLRUStrategy.h
//  RCCache
//
//  Created by yxj on 2018/9/13.
//

#import <Foundation/Foundation.h>
#import "RCMemCacheStrategyProtocol.h"
#import "RCMemCacheAbstractStrategy.h"

@interface RCMemCacheLRUStrategy : RCMemCacheAbstractStrategy <RCMemCacheStrategyProtocol>
//从父类继承
//@property (nonatomic, assign, readonly) NSUInteger totalCount;
//@property (nonatomic, assign, readonly) NSUInteger totalCost;
//@property (nonatomic, assign) BOOL needReleaseOnMainThread;
//@property (nonatomic, assign) BOOL needAsyncRelease;

@end
