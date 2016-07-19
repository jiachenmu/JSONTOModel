//
//  CMGCD.h
//  CMGCD
//
//  Created by jiachenmu on 16/7/13.
//  Copyright © 2016年 ManoBoo. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CMSerialQueue(label)     [CMGCD queueWithLabel:label]
#define CMConCurrentQueue(label) [CMGCD sync_queueWithLabel:label]

typedef BOOL(^IS_Excute_Next_ActionBlock)(void);

@interface CMGCD : NSObject

@property (strong, nonatomic) dispatch_queue_t queue;

+ (instancetype)shareQueue;


#pragma mark - Create a queue
//返回一个queue,上面调用即可 ` CMSerialQueue(label) `
/*
 label : 队列标签
 Example: dispatch_queue_t queue = CMSerialQueue("com.Manoboo.Inc");
 */
+ (dispatch_queue_t)queueWithLabel:(const char *)label;

//返回一个queue,上面调用即可 ` CMConCurrentQueue(label) `
+ (dispatch_queue_t)sync_queueWithLabel:(const char *)label;


#pragma mark - Queue Operation

//同步添加到主线程中
+ (void)cmSync_mainQueueWithAction:(dispatch_block_t)action;

//同步添加到线程中
+ (void)cmSyncWithQueue:(dispatch_queue_t)queue ActiobBlock:(dispatch_block_t)action;


//异步添加到主线程中
+ (void)cmAsync_mainQueueWithAction:(dispatch_block_t)action;

//异步添加到线程中
+ (void)cmAsyncWithQueue:(dispatch_queue_t)queue ActionBlock:(dispatch_block_t)action;


//延迟delayTime秒之后提交任务到queue中
+ (void)queue:(dispatch_queue_t)queue Action:(dispatch_block_t)action Delay:(NSTimeInterval)delayTime;

+ (void)mainQueueWithAction:(dispatch_block_t)action Delay:(NSTimeInterval)delayTime;

#pragma mark - Queue's Action execute according to the order of submission
//线程中添加的操作按提交的顺序依次执行
- (void)start;
// 
- (void)addAction:(dispatch_block_t)action ExecuteSignal:(IS_Excute_Next_ActionBlock)isExcuteBlock;

@end
