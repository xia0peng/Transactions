//
//  Transaction.h
//  Pods-Transactions_Example
//
//  Created by xiaopengwang on 2020/9/3.
//

#import <Foundation/Foundation.h>
#import <pthread.h>

NS_ASSUME_NONNULL_BEGIN

#define Assert(condition, desc, ...) NSAssert(condition, desc, ##__VA_ARGS__)
#define CAssert(condition, desc, ...) NSCAssert(condition, desc, ##__VA_ARGS__)

#define TransactionAssertMainThread() Assert(0 != pthread_main_np(), @"This method must be called on the main thread")
#define TransactionCAssertMainThread() CAssert(0 != pthread_main_np(), @"This function must be called on the main thread")

@class Transaction;

//  transaction completion block
typedef void(^async_transaction_completion_block_t)(Transaction *completedTransaction, BOOL canceled);

// display block
typedef id<NSObject> _Nullable(^async_transaction_operation_block_t)(void);

// operation completion block
typedef void(^async_transaction_operation_completion_block_t)(id<NSObject> _Nullable value, BOOL canceled);


typedef void(^async_transaction_complete_async_operation_block_t)(id<NSObject> _Nullable value);
typedef void(^async_transaction_async_operation_block_t)(async_transaction_complete_async_operation_block_t completeOperationBlock);


typedef NS_ENUM(NSUInteger, AsyncTransactionState) {
  AsyncTransactionStateOpen = 0,
  AsyncTransactionStateCommitted,
  AsyncTransactionStateCanceled,
  AsyncTransactionStateComplete
};

@interface Transaction : NSObject

/**
 The dispatch queue that the completion blocks will be called on.
 */
@property (nonatomic, readonly, strong) dispatch_queue_t callbackQueue;

/**
 A block that is called when the transaction is completed.
 */
@property (nonatomic, readonly, copy, nullable) async_transaction_completion_block_t completionBlock;

/**
The state of the transaction.
@see AsyncTransactionState
*/
@property (readonly, assign) AsyncTransactionState state;

/**
@param callbackQueue 调用完成块的调度队列。Default is the main queue.
@param completionBlock 事务完成时调用的块。
*/
/**
 闲时主线程队列
 闲时异步串行队列
 异步串行队列
 异步并行队列
*/
- (instancetype)initWithCallbackQueue:(nullable dispatch_queue_t)callbackQueue
                      completionBlock:(nullable async_transaction_completion_block_t)completionBlock;

/**
@summary 向事务添加同步操作。执行块将立即执行。
@desc 块将在指定队列上执行，并预期同步完成。异步
事务将等待所有操作在其相应的队列上执行，因此块可能仍在执行
异步，如果它们在并发队列上运行，即使此块的工作是同步的。

@param block 将在后台队列上执行的执行块。这就是耗时工作的地方。
@param queue 要在其上执行块的调度队列。
@param completion 当所有事务中的操作已完成。在callbackQueue上执行并释放。
*/
- (void)addOperationWithBlock:(async_transaction_operation_block_t)block
                     priority:(NSInteger)priority
                        queue:(dispatch_queue_t)queue
                   completion:(nullable async_transaction_operation_completion_block_t)completion;

/**
@summary 向事务添加异步操作。执行块将立即执行。
@desc 该块将在指定队列上执行，并预期异步完成。将会是
提供了一个可在异步操作完成后执行的完成块。这对网络下载和其他具有异步API的操作。
警告：使用者必须调用传递到工作块中的completeOperationBlock，否则对象将泄漏！

@param block 将在后台队列上执行的执行块。这就是昂贵工作的地方。
@param priority  Execution priority；优先级较高的任务将更快地执行
@param queue 要在其上执行块的调度队列。
@param completion 当所有事务中的操作已完成。在callbackQueue上执行并释放。
*/
- (void)addAsyncOperationWithBlock:(async_transaction_async_operation_block_t)block
                          priority:(NSInteger)priority
                             queue:(dispatch_queue_t)queue
                        completion:(nullable async_transaction_operation_completion_block_t)completion;

- (void)addCompletionBlock:(async_transaction_completion_block_t)completion;

- (void)waitUntilComplete;

- (void)cancel;

- (void)commit;

@end

NS_ASSUME_NONNULL_END
