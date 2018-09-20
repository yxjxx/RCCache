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
//#import "YYMemoryCache.h"

@interface RCViewController ()

@property (nonatomic, strong) RCMemoryCache *memCache;

@end

@implementation RCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
//    YYMemoryCache *c
    self.memCache = [[RCMemoryCache alloc] init];
    RCMemoryCache *memCache = self.memCache;
    memCache.countLimit = 1;
    memCache.costLimit = 10;
//    memCache.ageLimit = 6;
    NSString *key = @"firstObjectKey";
    NSString *key2 = @"secondObjectKey";
    [memCache setObject:@"firstObject" forKey:key];
    [memCache setObject:@"secondObject" forKey:key2];
    BOOL b = [memCache containsObjectForKey:key];
    id obj = [memCache objectForKey:key];
    obj = [memCache objectForKey:key2];
//    [memCache removeObjectForKey:key];
    b = [memCache containsObjectForKey:key2];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.memCache[@"secondObjectKey"] = @"2object";
    id obj = self.memCache[@"secondObjectKey"];    
}

@end
