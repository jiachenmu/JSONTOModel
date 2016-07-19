//
//  Dog.m
//  CMGCD
//
//  Created by jiachenmu on 16/7/14.
//  Copyright © 2016年 ManoBoo. All rights reserved.
//

#import "Dog.h"
#import "NSObject+CMModel.h"

@implementation Dog

- (NSDictionary *)dict_CMModelWithClass {
    return @{
             @"dog_age" : @"age",
             @"dog_name" : @"name",
             @"dog_pig" : @"dog_pig"
             };
}

@end
