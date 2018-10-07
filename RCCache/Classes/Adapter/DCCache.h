//
//  DCCache.h
//  RCCache
//
//  Created by yxj on 2018/10/7.
//

#import <Foundation/Foundation.h>
#import "RCCachingProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface DCCache : NSObject <RCCachingProtocol>

@property (nonatomic, strong, readonly) id<RCCachingSyncProtocol> memoryCache;

@property (nonatomic, strong, readonly) id<RCCachingProtocol> diskCache;


- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

- (nullable instancetype)initWithName:(NSString *)name;

- (nullable instancetype)initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;

+ (nullable instancetype)cacheWithName:(NSString *)name;
+ (nullable instancetype)cacheWithPath:(NSString *)path;


@end

NS_ASSUME_NONNULL_END
