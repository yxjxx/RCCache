//
//  _RCLinkedMap.m
//  RCCache
//
//  Created by yxj on 2018/9/13.
//

#import "_RCLinkedMap.h"
#import "RCCacheMacros.h"
#import <pthread.h>

@implementation _RCLinkedMapNode
@end


@implementation _RCLinkedMap {
    @package
    CFMutableDictionaryRef _dic;
    _RCLinkedMapNode *_head;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _dic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        _needReleaseOnMainThread = NO;
        _needAsyncRelease = YES;
    }
    return self;
}

- (void)dealloc {
    CFRelease(_dic);
}

- (void)insertNodeAtHead:(_RCLinkedMapNode *)node {
    CFDictionarySetValue(_dic, (__bridge const void *)(node->_key), (__bridge const void *)(node));
    _totalCost += node->_cost;
    _totalCount++;
    if (_head) {
        node->_next = _head;
        _head->_prev = node;
        _head = node;
    } else {
        _head = _tail = node;
    }
}

- (void)bringNodeToHead:(_RCLinkedMapNode *)node {
    if (_head == node) return;
    
    //remove this node from list
    if (_tail == node) {
        _tail = node->_prev;
        _tail->_next = nil;
    } else {
        node->_next->_prev = node->_prev;
        node->_prev->_next = node->_next;
    }
    //insert node to head
    node->_next = _head;
    node->_prev = nil;
    _head->_prev = node;
    _head = node;
}

- (void)removeNode:(_RCLinkedMapNode *)node {
    CFDictionaryRemoveValue(_dic, (__bridge const void *)(node->_key));
    _totalCost -= node->_cost;
    _totalCount--;
    if (node->_next) {
        node->_next->_prev = node->_prev;
    }
    if (node->_prev) {
        node->_prev->_next = node->_next;
    }
    if (_head == node) {
        _head = node->_next;
    }
    if (_tail == node) {
        _tail = node->_prev;
    }
}

- (_RCLinkedMapNode *)removeTailNode {
    if (!_tail) return nil;
    _RCLinkedMapNode *tail = _tail;
    CFDictionaryRemoveValue(_dic, (__bridge const void *)(_tail->_key));
    _totalCost -= _tail->_cost;
    _totalCount--;
    
    if (_head == _tail) {
        _head = _tail = nil;
    } else {
        _tail = _tail->_prev;
        _tail->_next = nil;
    }
    
    return tail;
}

- (void)removeAll {
    _totalCost = 0;
    _totalCount = 0;
    _head = nil;
    _tail = nil;
    if (CFDictionaryGetCount(_dic) > 0) {
        CFMutableDictionaryRef holder = _dic;
        _dic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        //1. async release 2. need release on main thread 3. is current on main thread
        if (_needAsyncRelease) {
            dispatch_queue_t queue = _needReleaseOnMainThread ? dispatch_get_main_queue() : RCMemCacheGetConcurrentReleaseQueue;
            dispatch_async(queue, ^{
                CFRelease(holder);// hold and release in specified queue
            });
        } else if (_needReleaseOnMainThread && !pthread_main_np()) {
            dispatch_async(dispatch_get_main_queue(), ^{
                CFRelease(holder);// hold and release in specified queue
            });
        } else {
            CFRelease(holder);
        }
    }
}

- (BOOL)containsObjectForKey:(id)key {
    if (!key) return NO;
    BOOL contains = CFDictionaryContainsKey(_dic, (__bridge const void *)(key));
    return contains;
}

- (_RCLinkedMapNode *)nodeForKey:(id)key{
    if (!key) return nil;
    _RCLinkedMapNode *node = CFDictionaryGetValue(_dic, (__bridge const void *)(key));
    return node;
}

- (void)holdAndReleaseOnQBgQueue:(id)obj {
    id holder = obj;
    //1. async release 2. need release on main thread 3. is current on main thread
    if (_needAsyncRelease) {
        dispatch_queue_t queue = _needReleaseOnMainThread ? dispatch_get_main_queue() : RCMemCacheGetConcurrentReleaseQueue;
        dispatch_async(queue, ^{
            [holder class];// hold and release in specified queue
        });
    } else if (_needReleaseOnMainThread && !pthread_main_np()) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [holder class];// hold and release in specified queue
        });
    }
}

@end
