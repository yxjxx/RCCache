//
//  RCMemCacheLRUStrategy.m
//  RCCache
//
//  Created by yxj on 2018/9/13.
//

#import "RCMemCacheLRUStrategy.h"
#import "pthread.h"
#import "_RCLinkedMap.h"
#import "RCCacheMacros.h"

@implementation RCMemCacheLRUStrategy {
    pthread_mutex_t _lruLock;
    _RCLinkedMap *_lru;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lruLock, NULL);
        _lru = [[_RCLinkedMap alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_lru removeAll];
    pthread_mutex_destroy(&_lruLock);
}

- (BOOL)containsObjectForKey:(id)key {
    if (!key) return NO;
    [self lock];
    BOOL contains = [_lru containsObjectForKey:key];
    [self unlock];
    return contains;
}

- (id)objectForKey:(id)key {
    if (!key) return nil;
    [self lock];
    _RCLinkedMapNode *node = [_lru nodeForKey:key];
    if (node) {
        node->_time = CACurrentMediaTime();
        [_lru bringNodeToHead:node];
    }
    [self unlock];
    return node ? node->_value : nil;
}

- (void)setObject:(id)object forKey:(id)key {
    [self setObject:object forKey:key withCost:0];
}

- (void)setObject:(id)object forKey:(id)key withCost:(NSUInteger)cost {
    if (!key) return;
    if (!object) {
        [self removeObjectForKey:key];
        return;
    }
    
    [self lock];
    _RCLinkedMapNode *node = [_lru nodeForKey:key];
    NSTimeInterval now = CACurrentMediaTime();
    if (node) { //update exist node
        _lru->_totalCost -= node->_cost;
        _lru->_totalCost += cost;
        node->_cost = cost;
        node->_time = now;
        node->_value = object;
        [_lru bringNodeToHead:node];
    } else { //create new node
        node = [[_RCLinkedMapNode alloc] init];
        node->_cost = cost;
        node->_time = now;
        node->_key = key;
        node->_value = object;
        [_lru insertNodeAtHead:node];
    }
    //check if over costLimit
//    if (_lru->_totalCost > ) {
//        <#statements#>
//    }
    //check if over countLimit
//    if (_lru->_totalCount > _countLimit) {
//
//    }
    [self unlock];
}

- (void)removeObjectForKey:(id)key {
    if (!key) return;
    [self lock];
    _RCLinkedMapNode *node = [_lru nodeForKey:key];
    if (node) {
        [_lru removeNode:node];
        [_lru holdAndReleaseOnQBgQueue:node];//trying, need verify
    }
    [self unlock];
}

- (void)removeAllObjects {
    [self lock];
    [_lru removeAll];
    [self unlock];
}

#pragma mark - getter & setter
- (NSUInteger)totalCount {
    [self lock];
    NSUInteger count = _lru->_totalCount;
    [self unlock];
    return count;
}

- (NSUInteger)totalCost {
    [self lock];
    NSUInteger cost = _lru->_totalCost;
    [self unlock];
    return cost;
}

- (BOOL)needReleaseOnMainThread {
    [self lock];
    BOOL b = _lru->_needReleaseOnMainThread;
    [self unlock];
    return b;
}

- (void)setNeedReleaseOnMainThread:(BOOL)needReleaseOnMainThread {
    [self lock];
    _lru->_needReleaseOnMainThread = needReleaseOnMainThread;
    [self unlock];
}

- (BOOL)needAsyncRelease {
    [self lock];
    BOOL b = _lru->_needAsyncRelease;
    [self unlock];
    return b;
}

- (void)setNeedAsyncRelease:(BOOL)needAsyncRelease {
    [self lock];
    _lru->_needAsyncRelease = needAsyncRelease;
    [self unlock];
}

- (void)trimToCount:(NSUInteger)countLimit {
    BOOL finish = NO;
    [self lock];
    if (countLimit == 0) {
        [_lru removeAll];
        finish = YES;
    } else if (_lru->_totalCount <= countLimit) {
        finish = YES;
    }
    [self unlock];
    if (finish) return;
    
    NSMutableArray *holder = [NSMutableArray array];
    while (!finish) {
        if (pthread_mutex_trylock(&_lruLock) == 0) {
            if (_lru->_totalCount > countLimit) {
                _RCLinkedMapNode *node = [_lru removeTailNode];
                if (node) [holder addObject:node];
            } else {
                finish = YES;
            }
            pthread_mutex_unlock(&_lruLock);
        } else {
            //https://blog.ibireme.com/2015/10/26/yycache/
            //为了尽量保证所有对外的访问方法都不至于阻塞，这个对象移除的方法应当尽量避免与其他访问线程产生冲突。当然这只能在很少一部分使用场景下才可能有些作用吧，而且作用可能也不明显。。。 :?:
            usleep(10 * 1000);
        }
    }
    if (holder.count) {
        dispatch_queue_t queue = _lru->_needReleaseOnMainThread ? dispatch_get_main_queue() : RCMemCacheGetConcurrentReleaseQueue;
        dispatch_async(queue, ^{
            //holder 持有了待释放的对象，这些对象应该根据配置在不同线程进行释放(release)。此处 holder 被 block 持有，然后在另外的 queue 中释放。[holder count] 只是为了让 holder 被 block 捕获，保证编译器不会优化掉这个操作，所以随便调用了一个方法。
            [holder count];
        });
    }
}

- (void)trimToCost:(NSUInteger)costLimit{
    BOOL finish = NO;
    [self lock];
    if (costLimit == 0) {
        [_lru removeAll];
        finish = YES;
    } else if (_lru->_totalCost <= costLimit) {
        finish = YES;
    }
    [self unlock];
    if (finish) return;
    
    NSMutableArray *holder = [NSMutableArray array];
    while (!finish) {
        if (pthread_mutex_trylock(&_lruLock) == 0) {
            if (_lru->_totalCost > costLimit) {
                _RCLinkedMapNode *node = [_lru removeTailNode];
                if (node) [holder addObject:node];
            } else {
                finish = YES;
            }
            pthread_mutex_unlock(&_lruLock);
        } else {
            usleep(10 * 1000); //10 ms
        }
    }
    if (holder.count) {
        dispatch_queue_t queue = _lru->_needReleaseOnMainThread ? dispatch_get_main_queue() : RCMemCacheGetConcurrentReleaseQueue;
        dispatch_async(queue, ^{
            [holder count]; // release in queue
        });
    }
}
- (void)trimToAge:(NSTimeInterval)ageLimit{
    BOOL finish = NO;
    NSTimeInterval now = CACurrentMediaTime();
    [self lock];
    if (ageLimit <= 0) {
        [_lru removeAll];
    } else if (!_lru->_tail || (now - _lru->_tail->_time) <= ageLimit) {
        finish = YES;
    }
    [self unlock];
    if (finish) return;
    
    NSMutableArray *holder = [NSMutableArray array];
    while (!finish) {
        if (pthread_mutex_trylock(&_lruLock) == 0) {
            if (_lru->_tail && (now - _lru->_tail->_time) > ageLimit) {
                _RCLinkedMapNode *node = [_lru removeTailNode];
                if(node) [holder addObject:node];
            } else {
                finish = YES;
            }
            pthread_mutex_unlock(&_lruLock);
        } else {
            usleep(10 * 1000); //10 ms
        }
    }
    if (holder.count) {
        dispatch_queue_t queue = _lru->_needReleaseOnMainThread ? dispatch_get_main_queue() : RCMemCacheGetConcurrentReleaseQueue;
        dispatch_async(queue, ^{
            [holder count]; // release in queue
        });
    }
}

- (void)trimTailNodeIfOverCountLimit:(NSUInteger)countLimit; {
    [self lock];
    if (_lru->_totalCount > countLimit) {
        _RCLinkedMapNode *node = [_lru removeTailNode];
        [_lru holdAndReleaseOnQBgQueue:node];//need verify
    }
    [self unlock];
}

- (void)lock {
    pthread_mutex_lock(&_lruLock);
}

- (void)unlock {
    pthread_mutex_unlock(&_lruLock);
}

@end
