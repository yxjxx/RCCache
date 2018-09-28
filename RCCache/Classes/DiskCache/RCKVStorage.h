//
//  RCKVStorage.h
//  RCCache
//
//  Created by yxj on 2018/9/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RCKVStorageItem : NSObject

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSData *value;
@property (nullable, nonatomic, strong) NSString *filename; //nil if inline
@property (nonatomic, assign) int size;
@property (nonatomic, assign) int modTime;
@property (nonatomic, assign) int accessTime;
@property (nullable, nonatomic, strong) NSData *extendedData;
@end

typedef NS_ENUM(NSUInteger, RCKVStorageType) {
    RCKVStorageTypeFile = 0,
    RCKVStorageTypeSQLite = 1,
    RCKVStorageTypeMixed = 2
};

@interface RCKVStorage : NSObject

@property (nonatomic, copy, readonly) NSString *path;
@property (nonatomic, assign, readonly) RCKVStorageType type;
#ifdef DEBUG
@property (nonatomic, assign) BOOL enableErrorLogs;
#endif

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

- (nullable instancetype)initWithPath:(NSString *)path type:(RCKVStorageType)type NS_DESIGNATED_INITIALIZER;

#pragma mark - save
- (BOOL)saveItem:(RCKVStorageItem *)item;
- (BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value;
- (BOOL)saveItemWithKey:(NSString *)key
                  value:(NSData *)value
               filename:(nullable NSString *)filename
           extendedData:(nullable NSData *)extendedData;

#pragma mark - remove
- (BOOL)removeItemForKey:(NSString *)key;
- (BOOL)removeItemForKyes:(NSArray<NSString *> *)keys;
- (BOOL)removeItemsLargerThanSize:(int)size;
- (BOOL)removeItemsEarlierThanTime:(int)time;
- (BOOL)removeItemsToFitSize:(int)maxSize;
- (BOOL)removeItemsToFitCount:(int)maxCount;
- (BOOL)removeAllItems;
- (void)removeAllItemsWithProgressBlock:(nullable void(^)(int removedCount, int totalCount))progress endBlock:(nullable void(^)(BOOL error))end;

#pragma mark - get
- (nullable RCKVStorageItem *)getItemForKey:(NSString *)key;
- (nullable RCKVStorageItem *)getItemInfoForKey:(NSString *)key;
- (nullable NSData *)getItemValueForKey:(NSString *)key;
- (nullable NSArray<RCKVStorageItem *> *)getItemsForKeys:(NSArray<NSString *> *)keys;
- (nullable NSArray<RCKVStorageItem *> *)getItemInfoForKeys:(NSArray<NSString *> *)keys;
- (nullable NSDictionary<NSString *, NSData *> *)getItemValueForKeys:(NSArray<NSString *> *)keys;

#pragma mark - storage stauts
- (BOOL)itemExistsForKey:(NSString *)key;
- (int)getItemsCount;
- (int)getItemsSize;

@end

NS_ASSUME_NONNULL_END
