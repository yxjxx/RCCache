//
//  RCCacheSubscriptingProtocol.h
//  RCCache
//
//  Created by yxj on 2018/9/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 http://clang.llvm.org/docs/ObjectiveCLiterals.html#dictionary-style-subscripting
 */
@protocol RCCacheSubscriptingProtocol <NSObject>

@required
/**
 This method enables using literals on the receiving object, such as `id object = cache[key];`.
 
 @param key The key associated with the object.
 @result The object for the specified key.
 */
- (nullable id)objectForKeyedSubscript:(id)key;

/**
 This method enables using literals on the receiving object, such as `cache[key] = object;`.
 
 @param object An object to be assigned for the key. Pass `nil` to remove the existing object for this key.
 @param key A key to associate with the object. This string will be copied.
 */
- (void)setObject:(nullable id)object forKeyedSubscript:(id)key;

@end

NS_ASSUME_NONNULL_END
