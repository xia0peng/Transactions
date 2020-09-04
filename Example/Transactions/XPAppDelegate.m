//
//  XPAppDelegate.m
//  Transactions
//
//  Created by xiaopengmonsters on 09/03/2020.
//  Copyright (c) 2020 xiaopengmonsters. All rights reserved.
//

#import "XPAppDelegate.h"
#import "GCTRunLoop.h"
#import "Transaction.h"
#import "TransactionGroup.h"

@implementation XPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    __weak __typeof(self)weakSelf = self;

    for (int i = 0; i < 1000; i++) {

        [[GCTRunLoop shareInstance] addTask:^BOOL{
            [weakSelf nslogmes:i];
            return YES;
        }];
    }
    
    
//    ASDK 提供了一个私有的管理事务的机制，由三部分组成 _ASAsyncTransactionGroup、_ASAsyncTransactionContainer 以及 _ASAsyncTransaction，这三者各自都有不同的功能：
//    _ASAsyncTransactionGroup 会在初始化时，向 Runloop 中注册一个回调，在每次 Runloop 结束时，执行回调来提交 displayBlock 执行的结果
//    _ASAsyncTransactionContainer 为当前 CALayer 提供了用于保存事务的容器，并提供了获取新的 _ASAsyncTransaction 实例的便利方法
//    _ASAsyncTransaction 将异步操作封装成了轻量级的事务对象，使用 C++ 代码对 GCD 进行了封装
//
//    for (int i = 0; i < 1000; i++) {
//
//        asyncdisplaykit_async_transaction_operation_block_t displayBlock = ^id{
//
//            UIImage *image = [UIImage new];
//            NSLog(@"displayBlock:%d",i);
//            return image;
//        };
//
//        asyncdisplaykit_async_transaction_operation_completion_block_t completionBlock = ^(id<NSObject> value, BOOL canceled){
//            NSLog(@"completionBlock:%d",i);
//        };
//
//        Transaction *transaction = [Transaction new];
//        [transaction addOperationWithBlock:displayBlock queue:[self displayQueue] completion:completionBlock];
//
//        [[TransactionGroup mainTransactionGroup] addTransactionContainer:transaction];
//
//
//    }

    
    return YES;
}

- (void)nslogmes:(int)i {
    NSLog(@"%d",i);
}

#pragma mark -

- (dispatch_queue_t)displayQueue
{
  static dispatch_queue_t displayQueue = NULL;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    displayQueue = dispatch_queue_create("org.AsyncDisplayKit.ASDisplayLayer.displayQueue", DISPATCH_QUEUE_CONCURRENT);
    // we use the highpri queue to prioritize UI rendering over other async operations
    dispatch_set_target_queue(displayQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
  });

  return displayQueue;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
