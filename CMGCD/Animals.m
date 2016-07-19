//
//  Animals.m
//  CMGCD
//
//  Created by jiachenmu on 16/7/14.
//  Copyright © 2016年 ManoBoo. All rights reserved.
//

#import "Animals.h"

@implementation Animals

- (NSDictionary *)dict_CMModelWithClass {
    return @{
             @"dogs" : @"dog",
             @"pigs" : @"pig",
             };
}


- (NSDictionary *)dict_CMModelWIthArrayClass {
    return @{
             @"dogs" : @"Dog",
             @"pigs" : @"Pig",
             };
}
@end
