//
//  _RCLinkedMap.h
//  RCCache
//
//  Created by yxj on 2018/9/13.
//

#import <Foundation/Foundation.h>

@interface _RCLinkedMapNode : NSObject {
    @package // only accessible by code from the same framework, library or executable
    __unsafe_unretained _RCLinkedMapNode *_prev;
    __unsafe_unretained _RCLinkedMapNode *_next;
    id _key;
    id _value;
    NSUInteger _cost;
    NSTimeInterval _time;
}
@end


@interface _RCLinkedMap : NSObject{
    @package
    NSUInteger _totalCost;
    NSUInteger _totalCount;
    BOOL _needReleaseOnMainThread;
    BOOL _needAsyncRelease;
    _RCLinkedMapNode *_tail;
}

- (BOOL)containsObjectForKey:(id)key;
- (_RCLinkedMapNode *)nodeForKey:(id)key;

- (void)insertNodeAtHead:(_RCLinkedMapNode *)node;
- (void)bringNodeToHead:(_RCLinkedMapNode *)node;
- (void)removeNode:(_RCLinkedMapNode *)node;
- (_RCLinkedMapNode *)removeTailNode;
- (void)removeAll;


/**
 iOS 保持界面流畅的技巧： https://blog.ibireme.com/2015/11/12/smooth_user_interfaces_for_ios/
 在后台线程销毁对象
 */
- (void)holdAndReleaseInQueue:(id)obj;

@end
