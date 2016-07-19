//
//  NSObject+CMModel.h
//  CMGCD
//
//  Created by jiachenmu on 16/7/15.
//  Copyright © 2016年 ManoBoo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (CMModel)

// 单个对象
- (NSDictionary *)dict_CMModelWithClass;

// 对象数组
- (NSDictionary *)dict_CMModelWIthArrayClass;

- (instancetype)cm_initWithJSONString:(NSString *)jsonString;

@end
