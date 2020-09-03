//
//  GCTRunLoop.h
//  iLife
//
//  Created by xiaopengwang on 2020/8/19.
//  Copyright © 2020 Gecent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL(^RunLoopWorkDistributionUnit)(void);

@interface GCTRunLoop : NSObject

@property (nonatomic, assign) NSUInteger maximumQueueLength;

+ (instancetype)shareInstance;

- (void)addTask:(RunLoopWorkDistributionUnit)unit;

- (void)removeAllTasks;

@end

NS_ASSUME_NONNULL_END
