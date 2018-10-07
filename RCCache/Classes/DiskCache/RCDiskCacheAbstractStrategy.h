//
//  RCDiskCacheAbstractStrategy.h
//  RCCache
//
//  Created by yxj on 2018/9/28.
//

#import <Foundation/Foundation.h>
#

NS_ASSUME_NONNULL_BEGIN

@interface RCDiskCacheAbstractStrategy : NSObject

@property (nullable, nonatomic, copy) NSString *name;
@property (nonatomic, copy, readonly) NSString *path;

@property (nonatomic, assign, readonly) NSUInteger inlineThreshold;

@property (nullable, nonatomic, copy) NSData *(^customArchiveBlock)(id object);
@property (nullable, nonatomic, copy) id (^customUnarchiveBlock)(NSData *data);
@property (nullable, nonatomic, copy) NSString *(^customFileNameBlock)(NSString *key);

@property (nonatomic, assign) BOOL enableErrorLogs;

@end

NS_ASSUME_NONNULL_END
