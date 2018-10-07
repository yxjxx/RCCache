//
//  RCViewController.m
//  RCCache
//
//  Created by rico on 07/07/2018.
//  Copyright (c) 2018 rico. All rights reserved.
//

#import "RCViewController.h"
//#import <RCCache/RCMemoryCache.h>
#import "RCMemoryCache.h"
#import "RCDiskCache.h"
#import "YYMemoryCache.h"
#import "DCCache.h"
#import "RCCache.h"

@interface RCViewController ()

@property (nonatomic, strong) RCMemoryCache *memCache;
@property (nonatomic, strong) RCDiskCache *diskCache;
@property (nonatomic, strong) RCCache *rccache;
@property (nonatomic, strong) DCCache *dccache;

@end

@implementation RCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
//    YYMemoryCache *c
//    self.memCache = [[RCMemoryCache alloc] init];
//    RCMemoryCache *memCache = self.memCache;
//    memCache.countLimit = 1;
//    memCache.costLimit = 10;
////    memCache.ageLimit = 6;
//    NSString *key = @"firstObjectKey";
//    NSString *key2 = @"secondObjectKey";
//    [memCache setObject:@"firstObject" forKey:key];
//    [memCache setObject:@"secondObject" forKey:key2];
//    BOOL b = [memCache containsObjectForKey:key];
//    id obj = [memCache objectForKey:key];
//    obj = [memCache objectForKey:key2];
////    [memCache removeObjectForKey:key];
//    b = [memCache containsObjectForKey:key2];
    
    //test for RCDiskCache
    /*
    NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *path = [cacheFolder stringByAppendingPathComponent:@"RCCache-demo"];
    self.diskCache = [[RCDiskCache alloc] initWithPath:path];
    NSString *key = @"key1";
    [self.diskCache setObject:@"value1" forKey:key];
    
    BOOL b = [self.diskCache containsObjectForKey:key];
    [self.diskCache removeObjectForKey:key];
    [self.diskCache containsObjectForKey:key withBlock:^(NSString * _Nonnull key, BOOL contains) {
        if (contains) {
            NSLog(@"%@", key);
        }
    }];
    */
    
    //test for RCCache
    /*
    self.rccache = [[RCCache alloc] initWithName:@"demo"];
    NSString *key = @"rccache-demo-key";
    BOOL b = [self.rccache containsObjectForKey:key];
    [self.rccache setObject:@"rccache-demo-value" forKey:key];
    [self.rccache containsObjectForKey:key withBlock:^(NSString * _Nonnull key, BOOL contains) {
        if (contains) {
            NSLog(@"%@", key);
        }
    }];
    */
    
    //test for RCCache
    self.dccache = [[DCCache alloc] initWithName:@"demo"];
    NSString *key = @"dccache-demo-key";
    BOOL b = [self.dccache containsObjectForKey:key];
    [self.dccache setObject:@"rccache-demo-value" forKey:key];
    [self.dccache containsObjectForKey:key withBlock:^(NSString * _Nonnull key, BOOL contains) {
        if (contains) {
            NSLog(@"%@", key);
        }
    }];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.memCache[@"secondObjectKey"] = @"2object";
    id obj = self.memCache[@"secondObjectKey"];    
}

@end
