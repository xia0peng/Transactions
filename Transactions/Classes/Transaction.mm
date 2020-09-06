//
//  Transaction.m
//  Pods-Transactions_Example
//
//  Created by xiaopengwang on 2020/9/3.
//

#import "Transaction.h"
#import <list>
#import <map>
#import <mutex>
#import <stdatomic.h>

@interface TransactionOperation : NSObject
- (instancetype)initWithOperationCompletionBlock:(async_transaction_operation_completion_block_t)operationCompletionBlock;
@property (nonatomic, copy) async_transaction_operation_completion_block_t operationCompletionBlock;
@property (nonatomic, strong) id<NSObject> value; // set on bg queue by the operation block
@end

@implementation TransactionOperation

- (instancetype)initWithOperationCompletionBlock:(async_transaction_operation_completion_block_t)operationCompletionBlock
{
  if ((self = [super init])) {
    _operationCompletionBlock = operationCompletionBlock;
  }
  return self;
}

- (void)dealloc
{
  NSAssert(_operationCompletionBlock == nil, @"Should have been called and released before -dealloc");
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
  return [NSString stringWithFormat:@"<AsyncTransactionOperation: %p - value = %@", self, self.value];
}

@end

// Lightweight operation queue for _ASAsyncTransaction that limits number of spawned threads
class ASAsyncTransactionQueue
{
public:
  
  // Similar to dispatch_group_t
  class Group
  {
  public:
    // call when group is no longer needed; after last scheduled operation the group will delete itself
    virtual void release() = 0;
    
    // schedule block on given queue
    virtual void schedule(NSInteger priority, dispatch_queue_t queue, dispatch_block_t block) = 0;
    
    // dispatch block on given queue when all previously scheduled blocks finished executing
    virtual void notify(dispatch_queue_t queue, dispatch_block_t block) = 0;
    
    // used when manually executing blocks
    virtual void enter() = 0;
    virtual void leave() = 0;
    
    // wait until all scheduled blocks finished executing
    virtual void wait() = 0;
    
  protected:
    virtual ~Group() { }; // call release() instead
  };
  
  // Create new group
  Group *createGroup();
  
  static ASAsyncTransactionQueue &instance();
  
private:
  
  struct GroupNotify
  {
    dispatch_block_t _block;
    dispatch_queue_t _queue;
  };
  
  class GroupImpl : public Group
  {
  public:
    GroupImpl(ASAsyncTransactionQueue &queue)
      : _pendingOperations(0)
      , _releaseCalled(false)
      , _queue(queue)
    {
    }
    
    virtual void release();
    virtual void schedule(NSInteger priority, dispatch_queue_t queue, dispatch_block_t block);
    virtual void notify(dispatch_queue_t queue, dispatch_block_t block);
    virtual void enter();
    virtual void leave();
    virtual void wait();
    
    int _pendingOperations;
    std::list<GroupNotify> _notifyList;
    std::condition_variable _condition;
    BOOL _releaseCalled;
    ASAsyncTransactionQueue &_queue;
  };
  
  struct Operation
  {
    dispatch_block_t _block;
    GroupImpl *_group;
    NSInteger _priority;
  };
    
  struct DispatchEntry // entry for each dispatch queue
  {
    typedef std::list<Operation> OperationQueue;
    typedef std::list<OperationQueue::iterator> OperationIteratorList; // each item points to operation queue
    typedef std::map<NSInteger, OperationIteratorList> OperationPriorityMap; // sorted by priority

    OperationQueue _operationQueue;
    OperationPriorityMap _operationPriorityMap;
    int _threadCount;
      
    Operation popNextOperation(bool respectPriority);  // assumes locked mutex
    void pushOperation(Operation operation);           // assumes locked mutex
  };
  
  std::map<dispatch_queue_t, DispatchEntry> _entries;
  std::mutex _mutex;
};

ASAsyncTransactionQueue::Group* ASAsyncTransactionQueue::createGroup()
{
  Group *res = new GroupImpl(*this);
  return res;
}

void ASAsyncTransactionQueue::GroupImpl::release()
{
  std::lock_guard<std::mutex> l(_queue._mutex);
  
  if (_pendingOperations == 0)  {
    delete this;
  } else {
    _releaseCalled = YES;
  }
}

ASAsyncTransactionQueue::Operation ASAsyncTransactionQueue::DispatchEntry::popNextOperation(bool respectPriority)
{
  NSCAssert(!_operationQueue.empty() && !_operationPriorityMap.empty(), @"No scheduled operations available");

  OperationQueue::iterator queueIterator;
  OperationPriorityMap::iterator mapIterator;
  
  if (respectPriority) {
    mapIterator = --_operationPriorityMap.end();  // highest priority "bucket"
    queueIterator = *mapIterator->second.begin();
  } else {
    queueIterator = _operationQueue.begin();
    mapIterator = _operationPriorityMap.find(queueIterator->_priority);
  }
  
  // no matter what, first item in "bucket" must match item in queue
  NSCAssert(mapIterator->second.front() == queueIterator, @"Queue inconsistency");
  
  Operation res = *queueIterator;
  _operationQueue.erase(queueIterator);
  
  mapIterator->second.pop_front();
  if (mapIterator->second.empty()) {
    _operationPriorityMap.erase(mapIterator);
  }

  return res;
}

void ASAsyncTransactionQueue::DispatchEntry::pushOperation(ASAsyncTransactionQueue::Operation operation)
{
  _operationQueue.push_back(operation);

  OperationIteratorList &list = _operationPriorityMap[operation._priority];
  list.push_back(--_operationQueue.end());
}

void ASAsyncTransactionQueue::GroupImpl::schedule(NSInteger priority, dispatch_queue_t queue, dispatch_block_t block)
{
  ASAsyncTransactionQueue &q = _queue;
  std::lock_guard<std::mutex> l(q._mutex);
  
  DispatchEntry &entry = q._entries[queue];
  
  Operation operation;
  operation._block = block;
  operation._group = this;
  operation._priority = priority;
  entry.pushOperation(operation);
  
  ++_pendingOperations; // enter group
  
#if ASDISPLAYNODE_DELAY_DISPLAY
  NSUInteger maxThreads = 1;
#else
  NSUInteger maxThreads = [NSProcessInfo processInfo].activeProcessorCount * 2;

  // Bit questionable maybe - we can give main thread more CPU time during tracking;
  if ([[NSRunLoop mainRunLoop].currentMode isEqualToString:UITrackingRunLoopMode])
    --maxThreads;
#endif
  
  if (entry._threadCount < maxThreads) { // we need to spawn another thread

    // first thread will take operations in queue order (regardless of priority), other threads will respect priority
    bool respectPriority = entry._threadCount > 0;
    ++entry._threadCount;
    
    dispatch_async(queue, ^{
      std::unique_lock<std::mutex> lock(q._mutex);
      
      // go until there are no more pending operations
      while (!entry._operationQueue.empty()) {
        Operation operation = entry.popNextOperation(respectPriority);
        lock.unlock();
        if (operation._block) {
          // ASProfilingSignpostStart(3, operation._block);
          operation._block();
          // ASProfilingSignpostEnd(3, operation._block);
        }
        operation._group->leave();
        operation._block = nil; // the block must be freed while mutex is unlocked
        lock.lock();
      }
      --entry._threadCount;
      
      if (entry._threadCount == 0) {
        NSCAssert(entry._operationQueue.empty() || entry._operationPriorityMap.empty(), @"No working threads but operations are still scheduled"); // this shouldn't happen
        q._entries.erase(queue);
      }
    });
  }
}

void ASAsyncTransactionQueue::GroupImpl::notify(dispatch_queue_t queue, dispatch_block_t block)
{
  std::lock_guard<std::mutex> l(_queue._mutex);

  if (_pendingOperations == 0) {
    dispatch_async(queue, block);
  } else {
    GroupNotify notify;
    notify._block = block;
    notify._queue = queue;
    _notifyList.push_back(notify);
  }
}

void ASAsyncTransactionQueue::GroupImpl::enter()
{
  std::lock_guard<std::mutex> l(_queue._mutex);
  ++_pendingOperations;
}

void ASAsyncTransactionQueue::GroupImpl::leave()
{
  std::lock_guard<std::mutex> l(_queue._mutex);
  --_pendingOperations;
  
  if (_pendingOperations == 0) {
    std::list<GroupNotify> notifyList;
    _notifyList.swap(notifyList);
    
    for (GroupNotify & notify : notifyList) {
      dispatch_async(notify._queue, notify._block);
    }
    
    _condition.notify_one();
    
    // there was attempt to release the group before, but we still
    // had operations scheduled so now is good time
    if (_releaseCalled) {
      delete this;
    }
  }
}

void ASAsyncTransactionQueue::GroupImpl::wait()
{
  std::unique_lock<std::mutex> lock(_queue._mutex);
  while (_pendingOperations > 0) {
    _condition.wait(lock);
  }
}

ASAsyncTransactionQueue & ASAsyncTransactionQueue::instance()
{
  static ASAsyncTransactionQueue *instance = new ASAsyncTransactionQueue();
  return *instance;
}

@implementation Transaction {
  ASAsyncTransactionQueue::Group *_group;
  NSMutableArray<TransactionOperation *> *_operations;
  _Atomic(AsyncTransactionState) _state;
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

    _state = ATOMIC_VAR_INIT(AsyncTransactionStateOpen);
  }
  return self;
}

- (void)dealloc {
  // 未提交的事务破坏了关于释放callbackQueue上完成块的保证。
  NSAssert(self.state != AsyncTransactionStateOpen, @"Uncommitted ASAsyncTransactions are not allowed");
    if (_group) {
        _group->release();
    }
}

#pragma mark - Properties

- (AsyncTransactionState)state
{
    return atomic_load(&_state);
}

- (void)setState:(AsyncTransactionState)state
{
    atomic_store(&_state, state);
}

#pragma mark - Transaction Management

- (void)addOperationWithBlock:(async_transaction_operation_block_t)block
                     priority:(NSInteger)priority
                        queue:(dispatch_queue_t)queue
                   completion:(async_transaction_operation_completion_block_t)completion {
    
    TransactionAssertMainThread();
    NSAssert(self.state == AsyncTransactionStateOpen, @"You can only add operations to open transactions");

    [self _ensureTransactionData];

    TransactionOperation *operation = [[TransactionOperation alloc] initWithOperationCompletionBlock:completion];
    [_operations addObject:operation];
    if (block) {
        _group->schedule(priority, queue, ^{
          @autoreleasepool {
            if (self.state != AsyncTransactionStateCanceled) {
                operation.value = block();
            }
          }
        });
    }
}

- (void)addAsyncOperationWithBlock:(async_transaction_async_operation_block_t)block
                          priority:(NSInteger)priority
                             queue:(dispatch_queue_t)queue
                        completion:(async_transaction_operation_completion_block_t)completion
{
  TransactionAssertMainThread();
  NSAssert(self.state == AsyncTransactionStateOpen, @"You can only add operations to open transactions");

  [self _ensureTransactionData];

  TransactionOperation *operation = [[TransactionOperation alloc] initWithOperationCompletionBlock:completion];
  [_operations addObject:operation];
    if (block) {
        _group->schedule(priority, queue, ^{
          @autoreleasepool {
            if (self.state != AsyncTransactionStateCanceled) {
              self->_group->enter();
              block(^(id<NSObject> value){
                operation.value = value;
                  self->_group->leave();
              });
            }
          }
        });
    }
}

- (void)addCompletionBlock:(async_transaction_completion_block_t)completion
{
    __weak __typeof__(self) weakSelf = self;
    [self addOperationWithBlock:^(){return (id<NSObject>)nil;} priority:0 queue:_callbackQueue completion:^(id<NSObject>  _Nullable value, BOOL canceled) {
        __typeof__(self) strongSelf = weakSelf;
        completion(strongSelf, canceled);
    }];
}

- (void)cancel
{
  TransactionAssertMainThread();
  NSAssert(self.state != AsyncTransactionStateOpen, @"You can only cancel a committed or already-canceled transaction");
  self.state = AsyncTransactionStateCanceled;
}

- (void)commit
{
  TransactionAssertMainThread();
  NSAssert(self.state == AsyncTransactionStateOpen, @"You cannot double-commit a transaction");
  self.state = AsyncTransactionStateCommitted;
  
  if ([_operations count] == 0) {
    // Fast path: if a transaction was opened, but no operations were added, execute completion block synchronously.
    if (_completionBlock) {
      _completionBlock(self, NO);
    }
  } else {
    NSAssert(_group != NULL, @"If there are operations, dispatch group should have been created");
    
    _group->notify(_callbackQueue, ^{
        //_callbackQueue 是当前实践中的主队列（也被断言为in-waitUntilComplete）。
        //在采用明显不同的用例之前，应该先检查这段代码。
        TransactionAssertMainThread();
        [self completeTransaction];
    });
  }
}

- (void)completeTransaction
{
  AsyncTransactionState state = self.state;
  if (state != AsyncTransactionStateComplete) {
    BOOL isCanceled = (state == AsyncTransactionStateCanceled);
    for (TransactionOperation *operation in _operations) {
      [operation callAndReleaseCompletionBlock:isCanceled];
    }
    
    // 始终将状态设置为“完成”，即使我们被取消，以阻止任何无关的
    // 可能已为下一个运行循环计划的对此方法的调用
    //（例如，如果我们需要在这个运行循环中使用-waitUntilComplete强制执行一个，但另一个已经被调度）
    self.state = AsyncTransactionStateComplete;

    if (_completionBlock) {
      _completionBlock(self, isCanceled);
    }
  }
}

- (void)waitUntilComplete
{
 
}

#pragma mark -
#pragma mark Helper Methods

- (void)_ensureTransactionData
{
    if (_group == NULL) {
    _group = ASAsyncTransactionQueue::instance().createGroup();
    }
    if (_operations == nil) {
    _operations = [[NSMutableArray alloc] init];
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<Transaction: %p - _state = %lu, _group = %p, _operations = %@>", self, (unsigned long)self.state, _group, _operations];
}

@end
