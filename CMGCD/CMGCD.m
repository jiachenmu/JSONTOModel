//
//  CMGCD.m
//  CMGCD
//
//  Created by jiachenmu on 16/7/13.
//  Copyright © 2016年 ManoBoo. All rights reserved.
//

#import "CMGCD.h"

#define SafeAction(action) if(action != nil) { action(); }


@interface CMGCD ()

@property (strong, nonatomic) NSMutableArray <dispatch_block_t> *actionArray;
@property (strong, nonatomic) NSMutableArray <IS_Excute_Next_ActionBlock> *isExcuteBlockArray;

@end

@implementation CMGCD 
//
static CMGCD *cm_GCD;
+ (instancetype)shareQueue {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cm_GCD = [[CMGCD alloc] init];
        cm_GCD.queue = CMSerialQueue("com.CMGCD.shareQueue");
        cm_GCD.actionArray = [NSMutableArray array];
        cm_GCD.isExcuteBlockArray = [NSMutableArray array];
    });
    return cm_GCD;
}



//返回一个串行队列

+ (dispatch_queue_t)queueWithLabel:(const char *)label {
    
    dispatch_queue_t queue = dispatch_queue_create(label, DISPATCH_QUEUE_SERIAL);
    return queue;
}

//返回一个并行队列
+ (dispatch_queue_t)sync_queueWithLabel:(const char *)label {
    
    dispatch_queue_t queue = dispatch_queue_create(label, DISPATCH_QUEUE_CONCURRENT);
    return queue;
}


#pragma mark - Add action to queue

//--------------------------------Sync---------------------------------------------//
+ (void)cmSync_mainQueueWithAction:(dispatch_block_t)action {
    dispatch_sync(dispatch_get_main_queue(), ^{
        action();
    });
}

+ (void)cmSyncWithQueue:(dispatch_queue_t)queue ActiobBlock:(dispatch_block_t)action {
    dispatch_sync(queue, ^{
        SafeAction(action);
    });
}

//--------------------------------Async---------------------------------------------//
+ (void)cmAsync_mainQueueWithAction:(dispatch_block_t)action {
    dispatch_async(dispatch_get_main_queue(), ^{
        SafeAction(action);
    });
}

+ (void)cmAsyncWithQueue:(dispatch_queue_t)queue ActionBlock:(dispatch_block_t)action {
    dispatch_async(queue, ^{
        SafeAction(action);
    });
}

//--------------------------------Delay---------------------------------------------//
+ (void)queue:(dispatch_queue_t)queue Action:(dispatch_block_t)action Delay:(NSTimeInterval)delayTime {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), queue, ^{
        SafeAction(action);
    });
}

+ (void)mainQueueWithAction:(dispatch_block_t)action Delay:(NSTimeInterval)delayTime {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        SafeAction(action);
    });
}

//---------------------------Action excute by order--------------------------------//

//add action
- (void)addAction:(dispatch_block_t)action ExecuteSignal:(IS_Excute_Next_ActionBlock)isExcuteBlock {
    [[CMGCD shareQueue].actionArray addObject:action];
    [[CMGCD shareQueue].isExcuteBlockArray addObject:isExcuteBlock];
}

// start
- (void)start {
  
    CMGCD *actionQueue = [CMGCD shareQueue];
    for (int i = 0; i < actionQueue.actionArray.count; i++) {
        
        IS_Excute_Next_ActionBlock isExcuteBlock = [self.isExcuteBlockArray objectAtIndex:i];
        dispatch_block_t action = [self.actionArray objectAtIndex:i];
        
        if (isExcuteBlock() == true) {
            [CMGCD cmSyncWithQueue:self.queue ActiobBlock:^{
                action();
            }];
        }else {
            //end action
            NSLog(@"the %d 'th action not excute",i);
            break;
        }
    }
}

@end
