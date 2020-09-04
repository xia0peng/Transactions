//
//  TransactionGroup.h
//  Pods-Transactions_Example
//
//  Created by xiaopengwang on 2020/9/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TransactionContainer;

/// A group of transaction containers, for which the current transactions are committed together at the end of the next runloop tick.
@interface TransactionGroup : NSObject
/// The main transaction group is scheduled to commit on every tick of the main runloop.
+ (TransactionGroup *)mainTransactionGroup;
+ (void)commit;

/// Add a transaction container to be committed.
- (void)addTransactionContainer:(id<TransactionContainer>)container;

@end

NS_ASSUME_NONNULL_END
