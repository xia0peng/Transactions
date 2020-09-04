//
//  TransactionGroup.m
//  Pods-Transactions_Example
//
//  Created by xiaopengwang on 2020/9/3.
//

#import "TransactionGroup.h"
#import "TransactionContainer.h"
#import "Transaction.h"
#import <pthread.h>

#define Assert(condition, desc, ...) NSAssert(condition, desc, ##__VA_ARGS__)
#define CAssert(condition, desc, ...) NSCAssert(condition, desc, ##__VA_ARGS__)

#define TransactionAssertMainThread() Assert(0 != pthread_main_np(), @"This method must be called on the main thread")
#define TransactionCAssertMainThread() CAssert(0 != pthread_main_np(), @"This function must be called on the main thread")

static void _transactionGroupRunLoopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info);

@interface TransactionGroup ()

@end

@implementation TransactionGroup {
    NSHashTable<id<TransactionContainer>> *_containers;
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

+ (void)registerTransactionGroupAsMainRunloopObserver:(TransactionGroup *)transactionGroup {
    TransactionAssertMainThread();
    static CFRunLoopObserverRef observer;
    Assert(observer == NULL, @"A _ASAsyncTransactionGroup should not be registered on the main runloop twice");
    // defer the commit of the transaction so we can add more during the current runloop iteration
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFOptionFlags activities = (kCFRunLoopBeforeWaiting | // before the run loop starts sleeping
                                kCFRunLoopExit);          // before exiting a runloop run
    CFRunLoopObserverContext context = {
      0,           // version
      (__bridge void *)transactionGroup,  // info
      &CFRetain,   // retain
      &CFRelease,  // release
      NULL         // copyDescription
    };

    observer = CFRunLoopObserverCreate(NULL,        // allocator
                                       kCFRunLoopBeforeWaiting,  // activities
                                       YES,         // repeats
                                       INT_MAX,     // order after CA transaction commits
                                       &_transactionGroupRunLoopObserverCallback,  // callback
                                       &context);   // context
    CFRunLoopAddObserver(runLoop, observer, kCFRunLoopDefaultMode);
    CFRelease(observer);
}

- (instancetype)init {
  if ((self = [super init])) {
    _containers = [NSHashTable hashTableWithOptions:NSHashTableObjectPointerPersonality];
  }
  return self;
}

- (void)addTransactionContainer:(id<TransactionContainer>)container
{
  TransactionAssertMainThread();
  Assert(container != nil, @"No container");
  [_containers addObject:container];
}

- (void)commit {
    TransactionAssertMainThread();

    if ([_containers count]) {
      NSHashTable *containersToCommit = _containers;
      _containers = [NSHashTable hashTableWithOptions:NSHashTableObjectPointerPersonality];

      for (id<TransactionContainer> container in containersToCommit) {
        // Note that the act of committing a transaction may open a new transaction,
        // so we must nil out the transaction we're committing first.
//        Transaction *transaction = container.asyncdisplaykit_currentAsyncTransaction;
//        container.asyncdisplaykit_currentAsyncTransaction = nil;
//        [transaction commit];
      }
    }
}

+ (void)commit {
    [[TransactionGroup mainTransactionGroup] commit];
}

@end

static void _transactionGroupRunLoopObserverCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
//    TransactionCAssertMainThread();
//    TransactionGroup *group = (__bridge TransactionGroup *)info;
//    [group commit];
    
    NSLog(@"111");
}
