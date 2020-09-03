//
//  GCTRunLoop.m
//  iLife
//
//  Created by xiaopengwang on 2020/8/19.
//  Copyright © 2020 Gecent. All rights reserved.
//

#import "GCTRunLoop.h"
#import <objc/runtime.h>

@interface GCTRunLoop()

@property (nonatomic, strong) NSMutableArray *tasks;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation GCTRunLoop

- (void)removeAllTasks {
    [self.tasks removeAllObjects];
}

- (void)addTask:(RunLoopWorkDistributionUnit)unit {
    [self.tasks addObject:unit];
    if (self.tasks.count > self.maximumQueueLength) {
        [self.tasks removeObjectAtIndex:0];
    }
}

- (void)_timerFiredMethod:(NSTimer *)timer {
    //We do nothing here
}

- (instancetype)init
{
    if ((self = [super init])) {
        _maximumQueueLength = 300000;
        _tasks = [NSMutableArray array];
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_timerFiredMethod:) userInfo:nil repeats:YES];
    }
    return self;
}

+ (instancetype)shareInstance {
    static GCTRunLoop *singleton;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        singleton = [[GCTRunLoop alloc] init];
        [self _registerRunLoopWorkDistributionAsMainRunloopObserver:singleton];
    });
    return singleton;
}

+ (void)_registerRunLoopWorkDistributionAsMainRunloopObserver:(GCTRunLoop *)runLoopWorkDistribution {
    static CFRunLoopObserverRef defaultModeObserver;
    _registerObserver(kCFRunLoopBeforeWaiting, defaultModeObserver, NSIntegerMax - 999, kCFRunLoopDefaultMode, (__bridge void *)runLoopWorkDistribution, &_defaultModeRunLoopWorkDistributionCallback);
}

static void _registerObserver(CFOptionFlags activities, CFRunLoopObserverRef observer, CFIndex order, CFStringRef mode, void *info, CFRunLoopObserverCallBack callback) {
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFRunLoopObserverContext context = {
        0,
        info,
        &CFRetain,
        &CFRelease,
        NULL
    };
    observer = CFRunLoopObserverCreate(NULL,
                                       activities,
                                       YES,
                                       order,
                                       callback,
                                       &context);
    CFRunLoopAddObserver(runLoop, observer, mode);
    CFRelease(observer);
}

static void _runLoopWorkDistributionCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
    GCTRunLoop *runLoopWorkDistribution = (__bridge GCTRunLoop *)info;
    if (runLoopWorkDistribution.tasks.count == 0) {
        return;
    }
    BOOL result = NO;
    while (result == NO && runLoopWorkDistribution.tasks.count) {
        RunLoopWorkDistributionUnit unit  = runLoopWorkDistribution.tasks.firstObject;
        result = unit();
        [runLoopWorkDistribution.tasks removeObjectAtIndex:0];
    }
}

static void _defaultModeRunLoopWorkDistributionCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    _runLoopWorkDistributionCallback(observer, activity, info);
}

@end
