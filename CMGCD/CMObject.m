//
//  CMObject.m
//  CMGCD
//
//  Created by jiachenmu on 16/7/15.
//  Copyright © 2016年 ManoBoo. All rights reserved.
//

#import "CMObject.h"
#import "NSObject+CMModel.h"

#define NULL_NUM [NSNumber numberWithDouble:0.00]

/// 系统类
#define FoundationClasses @[[NSURL class],[NSDate class],[NSValue class],[NSData class],[NSError class],[NSArray class],[NSString class],[NSMutableString class],[NSAttributedString class]];

@implementation CMObject {
    NSArray *foundationClasses_;
}

- (instancetype)initWithGoalObject:(id)object CMPropertyArray:(NSArray <CMProperty *> *)propertyArray{
    self = [super init];
    if (self) {
        _object = object;
        _propertyArray = propertyArray;
        foundationClasses_ = FoundationClasses;
    }
    return self;
}

- (void)setJsonString:(NSString *)jsonString {
    _jsonString = jsonString;
    
    [self analysisModel];
}

//开始进行model解析
- (void)analysisModel {
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[_jsonString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];


    //从解析字典找出对应属性的解析Key
    [_propertyArray enumerateObjectsUsingBlock:^(CMProperty * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //单独处理数组类型
        if (obj.propertyClass == [NSArray class]) {
            //  对象为数组类型，
            NSString *key = [_analysisObjectArrayDict objectForKey:obj.propertyName];

            Class OBJClass = NSClassFromString(key);
        
            if (![jsonDict objectForKey:key]) {
                //名称与json中的名称并不相符
                if ([_analysisDict objectForKey:obj.propertyName]) {
                    NSMutableArray *objectArray = [NSMutableArray array];
                    
                    NSArray *obj_json_array = [jsonDict objectForKey:[_analysisDict objectForKey:obj.propertyName]];
                    [obj_json_array enumerateObjectsUsingBlock:^(NSDictionary   * _Nonnull obj_dict, NSUInteger idx, BOOL * _Nonnull stop) {
                        id objx = [[OBJClass alloc] cm_initWithJSONString:DataToJSONString(obj_dict)];
                        //解析好对象之后，存到数据中
                        [objectArray addObject:objx];
                        
                    }];
                    [_object setValue:objectArray forKey:obj.propertyName];
                }
            }
        }else if (Exist_(obj.propertyClass, @[[NSDictionary class],[NSMutableDictionary class]])) {
            NSDictionary *obj_dict = [jsonDict valueForKey:[_analysisDict objectForKey:obj.propertyName]];
            if (!obj_dict) {
                [_object setValue:[NSNull null] forKey:obj.propertyName];
            }else {
                [_object setValue:obj_dict forKey:obj.propertyName];
            }
        }else if (obj.isBasicType){
            //基本类型
            id num = [jsonDict valueForKey:[_analysisDict objectForKey:obj.propertyName]];
            if (!num || num == [NSNull null]) {
                //为空判断
                //如果为空，这里我们默认设置为 0.00大小的NSNumber对象
                [_object setValue:NULL_NUM forKey:obj.propertyName];
            }else {
                NSNumber *number = (NSNumber *)num;
                [_object setValue:number forKey:obj.propertyName];
            }
        }else {
            Class OBJClass = obj.propertyClass;
            if(!Exist_(OBJClass, foundationClasses_)) {
                //如果类型为自定义类
                id obj_dict = [jsonDict valueForKey:[_analysisDict objectForKey:obj.propertyName]];
                //非空判断
                if (!obj_dict) {
                    id objx = [[OBJClass alloc] cm_initWithJSONString:DataToJSONString(obj_dict)];
                    [_object setValue:objx forKey:obj.propertyName];
                }else {
                    //这里可以赋值为[NSNull null]，也可以赋值为一个新对象
//                    [_object setValue:[NSNull null] forKey:obj.propertyName];
                    [_object setValue:[[OBJClass alloc] init] forKey:obj.propertyName];
                }
            }else {
                [_object setValue:[jsonDict valueForKey:[_analysisDict objectForKey:obj.propertyName]] forKey:obj.propertyName];
            }
        }
    }];
}


BOOL Exist_(id obj,NSArray *existArray) {
    BOOL isExist = false;
    for (id objx in existArray) {
        if (objx == obj) {
            isExist = true;
            break;
        }
    }
    
    return isExist;
}

NSString * DataToJSONString(id object) {

    NSString *jsonString = nil;
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:object
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    return jsonString;
}



@end
