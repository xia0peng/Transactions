//
//  Transaction.h
//  Pods-Transactions_Example
//
//  Created by xiaopengwang on 2020/9/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class Transaction;

//用于执行绘制代码，返回一个UIImage(此block就是在后台进行绘制逻辑的block)。
typedef void(^asyncdisplaykit_async_transaction_completion_block_t)(Transaction *completedTransaction, BOOL canceled);
//在主线程中将第二步displayBlock返回的图片赋值给layer.contents，使之在屏幕上显示。
typedef id<NSObject> _Nullable(^asyncdisplaykit_async_transaction_operation_block_t)(void);
typedef void(^asyncdisplaykit_async_transaction_operation_completion_block_t)(id<NSObject> _Nullable value, BOOL canceled);

@interface Transaction : NSObject

/**
 The dispatch queue that the completion blocks will be called on.
 */
@property (nonatomic, readonly, strong) dispatch_queue_t callbackQueue;

/**
 A block that is called when the transaction is completed.
 */
@property (nonatomic, readonly, copy, nullable) asyncdisplaykit_async_transaction_completion_block_t completionBlock;

- (void)addOperationWithBlock:(asyncdisplaykit_async_transaction_operation_block_t)block
                        queue:(dispatch_queue_t)queue
                   completion:(nullable asyncdisplaykit_async_transaction_operation_completion_block_t)completion;

- (void)addOperationWithBlock:(asyncdisplaykit_async_transaction_operation_block_t)block
                     priority:(NSInteger)priority
                        queue:(dispatch_queue_t)queue
                   completion:(nullable asyncdisplaykit_async_transaction_operation_completion_block_t)completion;

- (void)commit;

@end

NS_ASSUME_NONNULL_END
