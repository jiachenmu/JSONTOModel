//
//  CMProperty.h
//  CMGCD
//
//  Created by jiachenmu on 16/7/15.
//  Copyright © 2016年 ManoBoo. All rights reserved.
//  将属性的详细描述转换成该类，方便调用

#import <Foundation/Foundation.h>

@interface CMProperty : NSObject

//属性名称
@property (strong, nonatomic) NSString *propertyName;

//属性的类
@property (strong, nonatomic) Class propertyClass;

//是否基本类型
@property (assign, nonatomic) BOOL isBasicType;

@end
