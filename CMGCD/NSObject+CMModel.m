//
//  NSObject+CMModel.m
//  CMGCD
//
//  Created by jiachenmu on 16/7/15.
//  Copyright © 2016年 ManoBoo. All rights reserved.
//

#import "NSObject+CMModel.h"
#import <objc/runtime.h>

#import "CMObject.h"
#import "CMProperty.h"

@implementation NSObject (CMModel)

- ( NSDictionary * _Nullable )dict_CMModelWithClass {
    return nil;
}

- (NSDictionary *)dict_CMModelWIthArrayClass {
    return nil;
}


- (instancetype)cm_initWithJSONString:(NSString *)jsonString {
    if (self) {
        [self analysisWitnJsonString:jsonString];
    }
    return self;
}

//将该类的属性和对应的类型进行封装
- (NSArray <CMProperty *> *)propertyArray {
    NSMutableArray *propertyArray = [NSMutableArray array];
    
    unsigned int count;
    objc_property_t *propertyList = class_copyPropertyList([self class], &count);
    for (unsigned int i = 0; i < count; i++) {
        CMProperty *property = [[CMProperty alloc] init];
        property.propertyName = [NSString stringWithUTF8String:property_getName(propertyList[i])];
        
        NSString *attrs = @(property_getAttributes(propertyList[i]));

        NSUInteger dotLoc = [attrs rangeOfString:@","].location;
        NSString *propertyType = nil;
        NSUInteger loc = 1;
        if (dotLoc == NSNotFound) { // 没有找到
            propertyType = [attrs substringFromIndex:loc];
        }else {
            propertyType = [attrs substringWithRange:NSMakeRange(loc, dotLoc - loc)];
            if ([propertyType isEqualToString:@"Q"]) {
                //基本类型
                property.isBasicType = true;
            }else {
                propertyType = [propertyType substringWithRange:NSMakeRange(2, propertyType.length - 3)];
            }
        }

        property.propertyClass = NSClassFromString(propertyType);
    
        [propertyArray addObject:property];
    }
    
    free(propertyList);
    
    return propertyArray;
}

//进行解析
- (void)analysisWitnJsonString:(NSString *)json {
    
    //存在解析字典
    if ([self dict_CMModelWithClass] != nil || [self dict_CMModelWIthArrayClass] != nil) {
        CMObject *analysisTools = [[CMObject alloc] initWithGoalObject:self CMPropertyArray:[self propertyArray]];
        if ([self dict_CMModelWIthArrayClass]) {
            analysisTools.analysisObjectArrayDict = [self dict_CMModelWIthArrayClass];
        }
        if ([self dict_CMModelWithClass]) {
            analysisTools.analysisDict = [self dict_CMModelWithClass];
        }
        analysisTools.jsonString = json;
    }
}
@end
