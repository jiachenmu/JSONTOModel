//
//  CMObject.h
//  CMGCD
//
//  Created by jiachenmu on 16/7/15.
//  Copyright © 2016年 ManoBoo. All rights reserved.
//  处理json转模型

#import <Foundation/Foundation.h>

#import "CMProperty.h"

@interface CMObject : NSObject

//要解析的对象
@property (strong, nonatomic) id object;

//解析key对应列表 单个对象
@property (strong, nonatomic) NSDictionary *analysisDict;

//解析key对应列表 对象数组
@property (strong, nonatomic) NSDictionary *analysisObjectArrayDict;

//属性列表
@property (strong, nonatomic) NSArray <CMProperty *> *propertyArray;

- (instancetype)initWithGoalObject:(id)object CMPropertyArray:(NSArray <CMProperty *> *)propertyArray;

@property (strong, nonatomic) NSString *jsonString;

BOOL Exist_(id obj,NSArray *existArray);

@end
