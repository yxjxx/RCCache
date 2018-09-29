//
//  RCDiskCacheLRUStrategy.h
//  RCCache
//
//  Created by yxj on 2018/9/24.
//

#import "RCDiskCacheAbstractStrategy.h"
#import "RCDiskCacheStrategyProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface RCDiskCacheLRUStrategy : RCDiskCacheAbstractStrategy <RCDiskCacheStrategyProtocol>

@end

NS_ASSUME_NONNULL_END
