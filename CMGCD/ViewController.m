//
//  ViewController.m
//  CMGCD
//
//  Created by jiachenmu on 16/7/13.
//  Copyright © 2016年 ManoBoo. All rights reserved.
//

#import "ViewController.h"

#import "CMGCD.h"
#import "Animals.h"
#import "NSObject+CMModel.h"

#import <objc/objc-runtime.h>

@interface ViewController ()

@property (assign, nonatomic) float x1;
@property (assign, nonatomic) float x2;
@property (assign, nonatomic) float x3;

@property (strong, nonatomic) NSString *content;

@end

@implementation ViewController {
    NSString *output;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
//    [self cm_GCD_Demo];
    
    [self runtimeDemo];
    
    [self jsonToModelDemo];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//这个我封装的一个简单的GCD使用类，可以略过
- (void)cm_GCD_Demo {
    _x1 = _x2 = _x3 = 0.0;
    
    __weak typeof(self) weakSekf = self;
    
    //添加三个任务
    [[CMGCD shareQueue] addAction:^{
        weakSekf.x1 += 1.0;
        NSLog(@"x1 = %.1f",weakSekf.x1);
    } ExecuteSignal:^BOOL{
        return true;
    }];
    
    [[CMGCD shareQueue] addAction:^{
        weakSekf.x2 += 2.0;
        NSLog(@"x2 = %.1f",weakSekf.x2);
    } ExecuteSignal:^BOOL{
        return weakSekf.x1 == 1.0;
    }];
    
    [[CMGCD shareQueue] addAction:^{
        weakSekf.x3 += 1.0;
        NSLog(@"x3 = %.1f",weakSekf.x3);
    } ExecuteSignal:^BOOL{
        return weakSekf.x2 == 1.0;
    }];
    
    //输出结果预测为： x1 = 1.0;  x2 = 2.0;  x3 = 0.0;
    [[CMGCD shareQueue] addAction:^{
        NSLog(@"x1 = %f",weakSekf.x1);
        NSLog(@"x2 = %f",weakSekf.x2);
        NSLog(@"x3 = %f",weakSekf.x3);
    } ExecuteSignal:^BOOL{
        return true;
    }];
    
    [[CMGCD shareQueue] start];
}


//MARK: Runtime Demo
- (void)runtimeDemo {
    
    objc_msgSend(self,@selector(sendAMessage:),@"ManoBoo");
    //这句话等于调用 [self sendAMessage:@"ManoBoo"]
    
    //替换调用方法，类似于window中的hook
    
    class_replaceMethod([self class], @selector(sendAMessage:), (IMP)changeAtoB, NULL);
    
    class_replaceMethod([ViewController class], @selector(sendBMessage:), (IMP)changeBtoC, NULL);
    
    [self sendAMessage:@"发出sendAMessage"];
    
    //获取类的属性名称
    unsigned int count;
    objc_property_t *propertyList = class_copyPropertyList([CMGCD class], &count);
    for (unsigned int i = 0; i < count; i++) {
        const char *propertyName = property_getName(propertyList[i]);
        NSLog(@"property ---> %@",[NSString stringWithUTF8String:propertyName]);
    }
    
    //获取类的方法列表
    count = 0;
    Method *methodList = class_copyMethodList([CMGCD class], &count);
    for (unsigned int i; i < count; i++) {
        Method method = methodList[i];
        NSLog(@"Method ---> %@",NSStringFromSelector(method_getName(method)));
    }
    
    
    //设置对象属性关联
    static char associatedKey;
    objc_setAssociatedObject(self, &associatedKey, @"content_yeah", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSString *get_content = objc_getAssociatedObject(self, &associatedKey);
    NSLog(@"content = %@",get_content);
    
    static char key2;
    objc_setAssociatedObject(self, &key2, @"output_yeah", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSString *get_output = objc_getAssociatedObject(self, &key2);
    NSLog(@"output = %@",get_output);
    
    //断开所有关联
    objc_removeAssociatedObjects(self);
}

//MARK: 方法替换_1
- (void)sendAMessage:(NSString *)message {
    NSLog(@"A_message: %@",message);
}

- (void)sendBMessage:(NSString *)message {
    NSLog(@"B_Message: %@",message);
}

- (void)sendCMessage:(NSString *)message {
    NSLog(@"C_Message: %@",message);
}

ViewController * changeAtoB(ViewController *SELF, SEL _cmd, NSString *message) {
   
    if ([NSStringFromSelector(_cmd) isEqualToString:@"sendAMessage:"]) {
        //将方法进行替换
        [SELF sendBMessage:message];
    }
    return SELF;
}

ViewController * changeBtoC(ViewController *SELF, SEL _cmd, NSString *message) {
    
    if ([NSStringFromSelector(_cmd) isEqualToString:@"sendBMessage:"]) {
        //将方法进行替换
        [SELF sendCMessage:message];
    }
    return SELF;
}

#pragma mark - JSON -> Model

- (void)jsonToModelDemo {
    NSString *testJSON = @"{\"dog\":[{\"name\":\"dog_1\",\"age\":15,\"dog_pig\":{\"name\":\"dogAndPig1\",\"age\":666}},{\"name\":\"dog_2\",\"age\":null,\"dog_pig\":null}],\"pig\":[{\"name\":\"pig_1\",\"age\":10},{\"name\":\"pig_2\",\"age\":12}]}";
    Animals *animals = [[Animals alloc] cm_initWithJSONString:testJSON];
    
    for (Dog *dog in animals.dogs) {
        NSLog(@"dog-----name : %@ age : %lu  'sPig.name : %@ 'sPig.age = %lu",dog.dog_name,(unsigned long)dog.dog_age,dog.dog_pig.pig_name,(unsigned long)dog.dog_pig.pig_age);
    }
    for (Pig *pig in animals.pigs) {
        NSLog(@"pig-----name : %@ age : %lu",pig.pig_name,(unsigned long)pig.pig_age);
    }
}

@end
