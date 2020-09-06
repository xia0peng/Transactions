//
//  TransactionGroup.m
//  Pods-Transactions_Example
//
//  Created by xiaopengwang on 2020/9/3.
//

#import "TransactionGroup.h"
#import "TransactionContainer.h"
#import "Transaction.h"

static void _transactionGroupRunLoopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info);

@interface TransactionGroup ()
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation TransactionGroup {
    NSMutableArray<id<TransactionContainer>> *_containers;
}

+ (TransactionGroup *)mainTransactionGroup {
    TransactionAssertMainThread();
    static TransactionGroup *mainTransactionGroup;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        mainTransactionGroup = [[TransactionGroup alloc] init];
        [self registerTransactionGroupAsMainRunloopObserver:mainTransactionGroup];
    });
    return mainTransactionGroup;
}

- (void)_timerFiredMethod:(NSTimer *)timer {
    //We do nothing here
}

+ (void)registerTransactionGroupAsMainRunloopObserver:(TransactionGroup *)transactionGroup {
    TransactionAssertMainThread();
    static CFRunLoopObserverRef observer;
    Assert(observer == NULL, @"A _ASAsyncTransactionGroup should not be registered on the main runloop twice");
    // defer the commit of the transaction so we can add more during the current runloop iteration
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFOptionFlags activities = (kCFRunLoopBeforeWaiting); // before the run loop starts sleeping
        
    CFRunLoopObserverContext context = {
      0,           // version
      (__bridge void *)transactionGroup,  // info
      &CFRetain,   // retain
      &CFRelease,  // release
      NULL         // copyDescription
    };

    observer = CFRunLoopObserverCreate(NULL,        // allocator
                                       activities,  // activities
                                       YES,         // repeats
                                       INT_MAX,     // order after CA transaction commits
                                       &_transactionGroupRunLoopObserverCallback,  // callback
                                       &context);   // context
    CFRunLoopAddObserver(runLoop, observer, kCFRunLoopDefaultMode);
    CFRelease(observer);
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _containers = [NSMutableArray array];
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_timerFiredMethod:) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)addTransactionContainer:(id<TransactionContainer>)container {
    TransactionAssertMainThread();
    Assert(container != nil, @"No container");
    [_containers addObject:container];
}

- (void)commit {
    TransactionAssertMainThread();

    if (_containers.count == 0) {
        return;
    }
    
    BOOL result = NO;
    while (result == NO && _containers.count) {
        Transaction *transaction  = _containers.firstObject;
        [transaction commit];
        result = YES;
        [_containers removeObjectAtIndex:0];
    }
}

+ (void)commit {
    [[TransactionGroup mainTransactionGroup] commit];
}

@end

static void _transactionGroupRunLoopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    TransactionCAssertMainThread();
    TransactionGroup *group = (__bridge TransactionGroup *)info;
    [group commit];
}
