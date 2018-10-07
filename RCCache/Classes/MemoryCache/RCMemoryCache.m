//
//  RCMemoryCache.m
//  RCCache
//
//  Created by yxj on 2018/9/12.
//

#import "RCMemoryCache.h"
#import "RCMemCacheLRUStrategy.h"

@implementation RCMemoryCache {
    dispatch_queue_t _trimBgQeue; //将 trim 放到 后台串行线程中去
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _trimBgQeue = dispatch_queue_create("com.xiaojukeji.cache.memory", DISPATCH_QUEUE_SERIAL);
        _countLimit = NSUIntegerMax;
        _costLimit = NSUIntegerMax;
        _ageLimit = DBL_MAX;
        _autoTrimInterval = 5.0;
        _shouldRemoveAllObjectsOnMemoryWarning = YES;
        _shouldRemoveAllObjectsWhenEnteringBackground = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appDidReceiveMemoryWarningNotification) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appDidEnterBackgroundNotification) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [self _trimRecursively];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

#pragma mark - notification
- (void)_appDidReceiveMemoryWarningNotification {
    if (self.didReceiveMemoryWarningBlock) {
        self.didReceiveMemoryWarningBlock(self);
    }
    if (self.shouldRemoveAllObjectsOnMemoryWarning) {
        [self removeAllObjects];
    }
}

- (void)_appDidEnterBackgroundNotification {
    if (self.didEnterBackgroundBlock) {
        self.didEnterBackgroundBlock(self);
    }
    if (self.shouldRemoveAllObjectsWhenEnteringBackground) {
        [self removeAllObjects];
    }
}

#pragma mark - getter & setter
- (NSUInteger)totalCount {
    NSUInteger count = self.concreteCacher.totalCount;
    return count;
}

- (NSUInteger)totalCost {
    NSUInteger cost = self.concreteCacher.totalCost;
    return cost;
}

#pragma mark - access method
- (BOOL)needReleaseOnMainThread {
    return self.concreteCacher.needReleaseOnMainThread;
}

- (void)setNeedReleaseOnMainThread:(BOOL)needReleaseOnMainThread {
    self.concreteCacher.needReleaseOnMainThread = needReleaseOnMainThread;
}

- (BOOL)needAsyncRelease {
    return self.concreteCacher.needAsyncRelease;
}

- (void)setNeedAsyncRelease:(BOOL)needAsyncRelease {
    self.concreteCacher.needAsyncRelease = needAsyncRelease;
}

#pragma mark - access method
- (BOOL)containsObjectForKey:(id)key {
    return [self.concreteCacher containsObjectForKey:key];
}

- (id)objectForKey:(id)key {
    return [self.concreteCacher objectForKey:key];
}

- (void)setObject:(id)object forKey:(id)key {
    [self setObject:object forKey:key withCost:0];
}

- (void)setObject:(id)object forKey:(id)key withCost:(NSUInteger)cost {
    [self.concreteCacher setObject:object forKey:key withCost:cost];
    //if over limit trim
    if (self.concreteCacher.totalCost > _costLimit) {
        dispatch_async(_trimBgQeue, ^{
            [self trimToCost:self->_costLimit];
        });
    }
    [self.concreteCacher trimTailNodeIfOverCountLimit:_countLimit];
}

- (void)removeObjectForKey:(id)key {
    [self.concreteCacher removeObjectForKey:key];
}

- (void)removeAllObjects {
    [self.concreteCacher removeAllObjects];
}

#pragma mark - public trim
- (void)trimToCount:(NSUInteger)count {
    if (count == 0) {
        [self removeAllObjects];
        return;
    }
    [self.concreteCacher trimToCount:count];
}

- (void)trimToCost:(NSUInteger)cost {
    [self.concreteCacher trimToCost:cost];
}

- (void)trimToAge:(NSTimeInterval)age {
    [self.concreteCacher trimToAge:age];
}

- (void)_trimRecursively {
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (ino64_t)(_autoTrimInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;
        [strongSelf _trimInBackground];
        [strongSelf _trimRecursively];
    });
}

- (void)_trimInBackground {
    dispatch_async(_trimBgQeue, ^{
        [self trimToCost:self->_costLimit];
        [self trimToCount:self->_countLimit];
        [self trimToAge:self->_ageLimit];
    });
}

#pragma mark - RCCacheSubscriptingProtocol
- (id)objectForKeyedSubscript:(id)key {
    return [self objectForKey:key];
}

- (void)setObject:(id)object forKeyedSubscript:(id)key {
    if (object == nil) {
        [self removeObjectForKey:key];
    } else {
        [self setObject:object forKey:key];
    }
}

- (id<RCMemCacheStrategyProtocol>)concreteCacher{
    if (_concreteCacher == nil) {
        _concreteCacher = [[RCMemCacheLRUStrategy alloc] init];
    }
    return _concreteCacher;
}

- (NSString *)description {
    if (_name) return [NSString stringWithFormat:@"<%@: %p> (%@)", self.class, self, _name];
    else return [NSString stringWithFormat:@"<%@: %p>", self.class, self];
}


@end
