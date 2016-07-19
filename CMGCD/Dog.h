//
//  Dog.h
//  CMGCD
//
//  Created by jiachenmu on 16/7/14.
//  Copyright © 2016年 ManoBoo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Pig.h"

@interface Dog : NSObject

@property (strong, nonatomic) NSString *dog_name;
@property (assign, nonatomic) NSUInteger dog_age;

//狗养的猪
@property (strong, nonatomic) Pig *dog_pig;

@end
