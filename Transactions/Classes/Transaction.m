//
//  Transaction.m
//  Pods-Transactions_Example
//
//  Created by xiaopengwang on 2020/9/3.
//

#import "Transaction.h"

@interface TransactionOperation : NSObject
- (instancetype)initWithOperationCompletionBlock:(asyncdisplaykit_async_transaction_operation_completion_block_t)operationCompletionBlock;
@property (nonatomic, copy) asyncdisplaykit_async_transaction_operation_completion_block_t operationCompletionBlock;
@property (nonatomic, strong) id<NSObject> value; // set on bg queue by the operation block
@end

@implementation TransactionOperation

- (instancetype)initWithOperationCompletionBlock:(asyncdisplaykit_async_transaction_operation_completion_block_t)operationCompletionBlock
{
  if ((self = [super init])) {
    _operationCompletionBlock = operationCompletionBlock;
  }
  return self;
}

- (void)dealloc
{
//  NSAssert(_operationCompletionBlock == nil, @"Should have been called and released before -dealloc");
}

- (void)callAndReleaseCompletionBlock:(BOOL)canceled;
{
  if (_operationCompletionBlock) {
    _operationCompletionBlock(self.value, canceled);
    // Guarantee that _operationCompletionBlock is released on _callbackQueue:
    self.operationCompletionBlock = nil;
  }
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<ASAsyncTransactionOperation: %p - value = %@", self, self.value];
}

@end


@implementation Transaction {
//  ASAsyncTransactionQueue::Group *_group;
  NSMutableArray<TransactionOperation *> *_operations;
//  _Atomic(ASAsyncTransactionState) _state;
}

#pragma mark -
#pragma mark Lifecycle

- (instancetype)initWithCallbackQueue:(dispatch_queue_t)callbackQueue
                      completionBlock:(void(^)(Transaction *, BOOL))completionBlock
{
  if ((self = [self init])) {
    if (callbackQueue == NULL) {
      callbackQueue = dispatch_get_main_queue();
    }
    _callbackQueue = callbackQueue;
    _completionBlock = completionBlock;

    //_state = ATOMIC_VAR_INIT(ASAsyncTransactionStateOpen);
  }
  return self;
}

- (void)dealloc
{
  // Uncommitted transactions break our guarantees about releasing completion blocks on callbackQueue.
//  NSAssert(self.state != ASAsyncTransactionStateOpen, @"Uncommitted ASAsyncTransactions are not allowed");
//  if (_group) {
//    _group->release();
//  }
}

#pragma mark - Properties

#pragma mark - Transaction Management

- (void)addOperationWithBlock:(asyncdisplaykit_async_transaction_operation_block_t)block
                        queue:(dispatch_queue_t)queue
                   completion:(asyncdisplaykit_async_transaction_operation_completion_block_t)completion {
    
    [self addOperationWithBlock:block 
                       priority:0
                          queue:queue
                     completion:completion];
}

- (void)addOperationWithBlock:(asyncdisplaykit_async_transaction_operation_block_t)block
                     priority:(NSInteger)priority
                        queue:(dispatch_queue_t)queue
                   completion:(asyncdisplaykit_async_transaction_operation_completion_block_t)completion {
    
//    ASAsyncTransactionAssertMainThread();
//    NSAssert(self.state == ASAsyncTransactionStateOpen, @"You can only add operations to open transactions");
//
    [self _ensureTransactionData];

    TransactionOperation *operation = [[TransactionOperation alloc] initWithOperationCompletionBlock:completion];
    [_operations addObject:operation];
//    _group->schedule(priority, queue, ^{
//      @autoreleasepool {
//        if (self.state != ASAsyncTransactionStateCanceled) {
//          operation.value = block();
//        }
//      }
//    });
}

- (void)commit
{
//  ASAsyncTransactionAssertMainThread();
//  NSAssert(self.state == ASAsyncTransactionStateOpen, @"You cannot double-commit a transaction");
//  self.state = ASAsyncTransactionStateCommitted;
  
  if ([_operations count] == 0) {
    // Fast path: if a transaction was opened, but no operations were added, execute completion block synchronously.
    if (_completionBlock) {
      _completionBlock(self, NO);
    }
  } else {
//    NSAssert(_group != NULL, @"If there are operations, dispatch group should have been created");
      
      if (_completionBlock) {
        _completionBlock(self, YES);
      }
    
//    _group->notify(_callbackQueue, ^{
//      // _callbackQueue is the main queue in current practice (also asserted in -waitUntilComplete).
//      // This code should be reviewed before taking on significantly different use cases.
//      ASAsyncTransactionAssertMainThread();
//      [self completeTransaction];
//    });
  }
}

#pragma mark -
#pragma mark Helper Methods

- (void)_ensureTransactionData
{
  // Lazily initialize _group and _operations to avoid overhead in the case where no operations are added to the transaction
//  if (_group == NULL) {
//    _group = ASAsyncTransactionQueue::instance().createGroup();
//  }
  if (_operations == nil) {
    _operations = [[NSMutableArray alloc] init];
  }
}

//- (NSString *)description
//{
//  return [NSString stringWithFormat:@"<_ASAsyncTransaction: %p - _state = %lu, _group = %p, _operations = %@>", self, (unsigned long)self.state, _group, _operations];
//}

@end
