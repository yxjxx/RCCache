//
//  RCMemCacheFIFOLRUStrategy.h
//  RCCache
//
//  Created by yxj on 2018/9/20.
//

#import "RCMemCacheAbstractStrategy.h"

NS_ASSUME_NONNULL_BEGIN

/**
 2Q算法有两个缓存队列，一个是FIFO队列，一个是LRU队列。
 当数据第一次访问时，2Q算法将数据缓存在FIFO队列里面，当数据第二次被访问时，则将数据从FIFO队列移到LRU队列里面，两个队列各自按照自己的方法淘汰数据。
 */
@interface RCMemCacheFIFOLRUStrategy : RCMemCacheAbstractStrategy

@end

NS_ASSUME_NONNULL_END
